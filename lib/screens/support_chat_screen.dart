import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../config/theme.dart';
import '../providers/booking_provider.dart';
import '../services/support_api_service.dart';

class SupportChatScreen extends StatefulWidget {
  const SupportChatScreen({super.key});

  @override
  State<SupportChatScreen> createState() => _SupportChatScreenState();
}

class _SupportChatScreenState extends State<SupportChatScreen> {
  final _api = SupportApiService();
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();

  // Route args: { 'bookingId': String, 'ticketId': String? }
  String? _bookingId;
  SupportTicket? _ticket;
  bool _loading = true;
  bool _sending = false;
  bool _isCreating = false;

  StreamSubscription? _messageSub;
  StreamSubscription? _statusSub;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_bookingId == null) {
      final args =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      _bookingId = args['bookingId'] as String;
      _init();
    }
  }

  Future<void> _init() async {
    try {
      final ticket = await _api.getTicket(_bookingId!);
      if (!mounted) return;
      setState(() {
        _ticket = ticket;
        _loading = false;
      });
      _joinRoom(ticket.id);
      _listenSocket();
      _scrollToBottom();
    } catch (e) {
      // No ticket yet — show create form
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _joinRoom(String ticketId) {
    context.read<BookingProvider>().socketService.joinSupportRoom(ticketId);
  }

  void _listenSocket() {
    final socket = context.read<BookingProvider>().socketService;

    _messageSub = socket.onSupportMessage.listen((data) {
      if (data['ticketId']?.toString() != _ticket?.id) return;
      final raw = data['message'];
      if (raw is! Map) return;
      final msg = SupportMessage.fromJson(Map<String, dynamic>.from(raw));
      if (_ticket!.messages.any((m) => m.id == msg.id)) return;
      setState(() => _ticket!.messages.add(msg));
      _scrollToBottom();
    });

    _statusSub = socket.onSupportStatusChanged.listen((data) {
      if (data['ticketId']?.toString() != _ticket?.id) return;
      setState(() {
        _ticket = SupportTicket(
          id: _ticket!.id,
          bookingId: _ticket!.bookingId,
          issue: _ticket!.issue,
          status: data['status']?.toString() ?? _ticket!.status,
          messages: _ticket!.messages,
        );
      });
    });
  }

  Future<void> _createTicket(String issue) async {
    setState(() => _isCreating = true);
    try {
      final ticket = await _api.createTicket(_bookingId!, issue);
      if (!mounted) return;
      setState(() {
        _ticket = ticket;
        _isCreating = false;
      });
      _joinRoom(ticket.id);
      _listenSocket();
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isCreating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open ticket: $e'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  Future<void> _send() async {
    final text = _inputController.text.trim();
    if (text.isEmpty || _sending || _ticket == null) return;

    setState(() => _sending = true);
    _inputController.clear();

    try {
      final msg = await _api.sendMessage(_ticket!.id, text);
      if (!mounted) return;
      setState(() {
        _ticket!.messages.add(msg);
        _sending = false;
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      _inputController.text = text;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not send: $e'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void dispose() {
    _messageSub?.cancel();
    _statusSub?.cancel();
    if (_ticket != null) {
      context.read<BookingProvider>().socketService.leaveSupportRoom(_ticket!.id);
    }
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              if (_ticket != null) _buildStatusBanner(),
              Expanded(child: _buildBody()),
              if (_ticket != null && !_ticket!.isClosed) _buildComposer(),
              if (_ticket != null && _ticket!.isClosed) _buildClosedBanner(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: AppTheme.textPrimary,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Support',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  'Admin will respond shortly',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppTheme.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.support_agent_rounded,
            color: AppTheme.primary,
            size: 28,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBanner() {
    final ticket = _ticket!;
    Color color;
    String label;
    switch (ticket.status) {
      case 'in_progress':
        color = AppTheme.warning;
        label = 'In Progress';
        break;
      case 'closed':
        color = AppTheme.success;
        label = 'Closed';
        break;
      default:
        color = AppTheme.primary;
        label = 'Open';
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 8),
          Text(
            'Ticket status: $label',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primary),
      );
    }

    if (_ticket == null) {
      return _buildCreateTicketView();
    }

    final messages = _ticket!.messages;
    if (messages.isEmpty) {
      return Center(
        child: Text(
          'No messages yet',
          style: GoogleFonts.inter(color: AppTheme.textMuted),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      itemCount: messages.length,
      itemBuilder: (_, i) => _SupportBubble(
        message: messages[i],
        isMine: messages[i].senderRole != 'admin',
        isAdmin: messages[i].senderRole == 'admin',
      ),
    );
  }

  Widget _buildCreateTicketView() {
    final controller = TextEditingController();
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Describe your issue',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Our admin team will review and respond to your issue as soon as possible.',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppTheme.textMuted,
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: controller,
            maxLines: 5,
            minLines: 3,
            style: GoogleFonts.inter(
              color: AppTheme.textPrimary,
              fontSize: 14,
            ),
            decoration: InputDecoration(
              hintText: 'e.g. Provider did not show up, wrong service...',
              hintStyle: GoogleFonts.inter(color: AppTheme.textMuted),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: AppTheme.primary.withValues(alpha: 0.3),
                ),
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: GestureDetector(
              onTap: _isCreating
                  ? null
                  : () {
                      final issue = controller.text.trim();
                      if (issue.length < 5) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Please describe your issue (min 5 characters).',
                            ),
                            backgroundColor: AppTheme.error,
                          ),
                        );
                        return;
                      }
                      _createTicket(issue);
                    },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: _isCreating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Submit Issue',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComposer() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        16 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
        border: Border(
          top: BorderSide(color: AppTheme.primary.withValues(alpha: 0.05)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _inputController,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _send(),
              style: GoogleFonts.inter(
                color: AppTheme.textPrimary,
                fontSize: 14,
              ),
              decoration: InputDecoration(
                hintText: 'Type a message...',
                hintStyle: GoogleFonts.inter(
                  color: AppTheme.textMuted,
                  fontWeight: FontWeight.w500,
                ),
                filled: true,
                fillColor: AppTheme.primary.withValues(alpha: 0.03),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppTheme.primary.withValues(alpha: 0.05),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppTheme.primary.withValues(alpha: 0.05),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppTheme.primary.withValues(alpha: 0.15),
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _sending ? null : _send,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: _sending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.send_rounded,
                        size: 20,
                        color: Colors.white,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClosedBanner() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        20,
        14,
        20,
        14 + MediaQuery.of(context).padding.bottom,
      ),
      color: AppTheme.success.withValues(alpha: 0.08),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.check_circle_rounded,
            color: AppTheme.success,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            'This ticket has been resolved and closed.',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.success,
            ),
          ),
        ],
      ),
    );
  }
}

class _SupportBubble extends StatelessWidget {
  final SupportMessage message;
  final bool isMine;
  final bool isAdmin;

  const _SupportBubble({
    required this.message,
    required this.isMine,
    required this.isAdmin,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment:
            isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (isAdmin)
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 2),
              child: Text(
                'Support Admin',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primary,
                ),
              ),
            ),
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.74,
            ),
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              gradient: isMine ? AppTheme.primaryGradient : null,
              color: isAdmin
                  ? AppTheme.primary.withValues(alpha: 0.06)
                  : isMine
                  ? null
                  : Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(12).copyWith(
                bottomRight: Radius.circular(isMine ? 4 : 12),
                bottomLeft: Radius.circular(isMine ? 12 : 4),
              ),
              border: isMine
                  ? null
                  : Border.all(
                      color: isAdmin
                          ? AppTheme.primary.withValues(alpha: 0.15)
                          : AppTheme.textMuted.withValues(alpha: 0.12),
                    ),
            ),
            child: Text(
              message.text,
              style: GoogleFonts.inter(
                fontSize: 14,
                height: 1.35,
                color: isMine ? Colors.white : AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
