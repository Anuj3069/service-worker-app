import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

/// Manages Socket.IO connection for real-time booking events.
///
/// Worker listens for all Redis Pub/Sub events routed through the backend:
///   - new-booking-request    → Instant booking broadcast to candidate workers
///   - booking-taken          → Another worker accepted the instant booking
///   - new-scheduled-booking  → A new scheduled booking assigned to this worker
class SocketService {
  static const String _serverUrl = 'https://service-app-rduc.onrender.com';

  io.Socket? _socket;
  bool _isConnected = false;
  String? _userId;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 10;

  bool get isConnected => _isConnected;
  String? get userId => _userId;

  // ── Stream Controllers (broadcast so multiple listeners work) ──
  final _newBookingRequestController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _bookingTakenController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _newScheduledBookingController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _chatMessageController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _connectionStateController = StreamController<bool>.broadcast();

  // ── Public Streams ──
  Stream<Map<String, dynamic>> get onNewBookingRequest =>
      _newBookingRequestController.stream;
  Stream<Map<String, dynamic>> get onBookingTaken =>
      _bookingTakenController.stream;
  Stream<Map<String, dynamic>> get onNewScheduledBooking =>
      _newScheduledBookingController.stream;
  Stream<Map<String, dynamic>> get onChatMessage =>
      _chatMessageController.stream;
  Stream<bool> get onConnectionStateChanged =>
      _connectionStateController.stream;

  /// Connect to the socket server and register the user.
  /// The backend maps this socket to userId in Redis HASH (online_users).
  void connect(String userId) {
    _userId = userId;
    _reconnectAttempts = 0;

    if (_socket != null) {
      _socket!.dispose();
    }

    _socket = io.io(
      _serverUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .enableReconnection()
          .setReconnectionAttempts(_maxReconnectAttempts)
          .setReconnectionDelay(1000)
          .setReconnectionDelayMax(5000)
          .build(),
    );

    // ── Connection lifecycle ──
    _socket!.onConnect((_) {
      debugPrint('[Socket] ✅ Connected: ${_socket!.id}');
      _isConnected = true;
      _reconnectAttempts = 0;
      _connectionStateController.add(true);

      // CRITICAL: Register user → backend stores in Redis HASH
      _socket!.emit('register', {'userId': userId});
      debugPrint('[Socket] 📡 Registered userId: $userId (Redis-backed)');
    });

    _socket!.onDisconnect((_) {
      debugPrint('[Socket] 🔌 Disconnected');
      _isConnected = false;
      _connectionStateController.add(false);
    });

    _socket!.onReconnect((_) {
      debugPrint('[Socket] 🔄 Reconnected');
      _reconnectAttempts = 0;
      // Re-register on reconnect so Redis mapping is refreshed
      _socket!.emit('register', {'userId': userId});
    });

    _socket!.onReconnectAttempt((attempt) {
      _reconnectAttempts = attempt is int ? attempt : 0;
      debugPrint('[Socket] 🔄 Reconnect attempt: $_reconnectAttempts');
    });

    _socket!.onReconnectFailed((_) {
      debugPrint('[Socket] ❌ Reconnection failed after $_maxReconnectAttempts attempts');
    });

    _socket!.onConnectError((err) {
      debugPrint('[Socket] ❌ Connect error: $err');
      _isConnected = false;
      _connectionStateController.add(false);
    });

    _socket!.onError((err) {
      debugPrint('[Socket] ❌ Socket error: $err');
    });

    // ── Booking events (routed from Redis Pub/Sub → Socket.IO) ──

    // Instant booking request broadcast to candidate workers
    _socket!.on('new-booking-request', (data) {
      debugPrint('[Socket] 🚨 new-booking-request: $data');
      _addToController(_newBookingRequestController, data);
    });

    // Another worker accepted the instant booking
    _socket!.on('booking-taken', (data) {
      debugPrint('[Socket] 🔒 booking-taken: $data');
      _addToController(_bookingTakenController, data);
    });

    // A new scheduled booking assigned to this worker
    _socket!.on('new-scheduled-booking', (data) {
      debugPrint('[Socket] 📋 new-scheduled-booking: $data');
      _addToController(_newScheduledBookingController, data);
    });

    _socket!.on('chat-message', (data) {
      debugPrint('[Socket] chat-message: $data');
      _addToController(_chatMessageController, data);
    });

    _socket!.connect();
  }

  // ── Emit methods for live tracking ──

  /// Signal that the worker is en route to the customer
  void emitTrackingStart(String bookingId) {
    if (_socket == null || !_isConnected) {
      debugPrint('[Socket] ⚠️ Cannot emit tracking-start: not connected');
      return;
    }
    _socket!.emit('tracking-start', {'bookingId': bookingId});
    debugPrint('[Socket] 📍 Emitted tracking-start for booking: $bookingId');
  }

  /// Send live GPS location update
  void emitLocationUpdate(String bookingId, List<double> coordinates) {
    if (_socket == null || !_isConnected) {
      debugPrint('[Socket] ⚠️ Cannot emit location-update: not connected');
      return;
    }
    _socket!.emit('location-update', {
      'bookingId': bookingId,
      'coordinates': coordinates,
    });
    debugPrint('[Socket] 🗺️ Emitted location-update: $coordinates');
  }

  /// Helper to safely add data to a stream controller
  void _addToController(
    StreamController<Map<String, dynamic>> controller,
    dynamic data,
  ) {
    if (controller.isClosed) return;
    if (data is Map<String, dynamic>) {
      controller.add(data);
    } else if (data is Map) {
      controller.add(Map<String, dynamic>.from(data));
    }
  }

  /// Disconnect from socket server
  void disconnect() {
    _socket?.dispose();
    _socket = null;
    _isConnected = false;
    _userId = null;
    _connectionStateController.add(false);
  }

  /// Clean up resources
  void dispose() {
    disconnect();
    _newBookingRequestController.close();
    _bookingTakenController.close();
    _newScheduledBookingController.close();
    _chatMessageController.close();
    _connectionStateController.close();
  }
}
