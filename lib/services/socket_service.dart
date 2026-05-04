import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

/// Manages Socket.IO connection for real-time instant booking events.
/// Worker listens for: new-booking-request, booking-taken
class SocketService {
  static const String _serverUrl = 'http://10.0.2.2:3000';

  io.Socket? _socket;
  bool _isConnected = false;

  bool get isConnected => _isConnected;

  // Stream controllers for events
  final _newBookingRequestController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _bookingTakenController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get onNewBookingRequest =>
      _newBookingRequestController.stream;
  Stream<Map<String, dynamic>> get onBookingTaken =>
      _bookingTakenController.stream;

  /// Connect to the socket server and register the user
  void connect(String userId) {
    if (_socket != null) {
      _socket!.dispose();
    }

    _socket = io.io(
      _serverUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .build(),
    );

    _socket!.onConnect((_) {
      debugPrint('[Socket] Connected: ${_socket!.id}');
      _isConnected = true;

      // CRITICAL: Register user so backend maps socket to userId
      _socket!.emit('register', {'userId': userId});
      debugPrint('[Socket] Registered userId: $userId');
    });

    _socket!.on('new-booking-request', (data) {
      debugPrint('[Socket] 🚨 new-booking-request: $data');
      if (data is Map<String, dynamic>) {
        _newBookingRequestController.add(data);
      } else if (data is Map) {
        _newBookingRequestController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket!.on('booking-taken', (data) {
      debugPrint('[Socket] booking-taken: $data');
      if (data is Map<String, dynamic>) {
        _bookingTakenController.add(data);
      } else if (data is Map) {
        _bookingTakenController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket!.onDisconnect((_) {
      debugPrint('[Socket] Disconnected');
      _isConnected = false;
    });

    _socket!.onConnectError((err) {
      debugPrint('[Socket] Connect error: $err');
      _isConnected = false;
    });

    _socket!.connect();
  }

  /// Disconnect from socket server
  void disconnect() {
    _socket?.dispose();
    _socket = null;
    _isConnected = false;
  }

  /// Clean up resources
  void dispose() {
    disconnect();
    _newBookingRequestController.close();
    _bookingTakenController.close();
  }
}
