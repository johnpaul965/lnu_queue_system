// lib/features/student/notifications_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/supabase_service.dart';
import '../../core/utils/helpers.dart';
import '../../../main.dart' show preloadedStudent;

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<Map<String, dynamic>> _notifications = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;
      final preloaded = preloadedStudent;
      final student = preloaded ?? await SupabaseService.getStudentByAuthId(user.id);
      final data = await SupabaseService.getStudentNotifications(student['id']);
      if (mounted) setState(() { _notifications = data; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _markRead(String id) async {
    await SupabaseService.markNotificationRead(id);
    _load();
  }

  Future<void> _markAllRead() async {
    for (final n in _notifications.where((n) => n['is_read'] == false)) {
      await SupabaseService.markNotificationRead(n['id']);
    }
    _load();
  }

  IconData _iconForType(String? type) => switch (type) {
    'incomplete'  => Icons.warning_amber_outlined,
    'approved'    => Icons.check_circle_outline,
    'rejected'    => Icons.cancel_outlined,
    'processing'  => Icons.sync_outlined,
    'claim'       => Icons.event_available_outlined,
    'completed'   => Icons.task_alt_outlined,
    _             => Icons.notifications_outlined,
  };

  Color _colorForType(String? type) => switch (type) {
    'incomplete'  => LNUColors.statusIncomplete,
    'approved'    => LNUColors.statusForPayment,
    'rejected'    => LNUColors.statusRejected,
    'processing'  => LNUColors.statusProcessing,
    'claim'       => LNUColors.statusForClaiming,
    'completed'   => LNUColors.statusCompleted,
    _             => LNUColors.primary,
  };

  @override
  Widget build(BuildContext context) {
    final unread = _notifications.where((n) => n['is_read'] == false).length;
    return Scaffold(
      backgroundColor: LNUColors.background,
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: LNUColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (unread > 0)
            TextButton(
              onPressed: _markAllRead,
              child: const Text('Mark all read', style: TextStyle(color: Colors.white70, fontSize: 12)),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _notifications.isEmpty
                  ? ListView(children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.6,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.notifications_off_outlined, size: 64, color: LNUColors.lightBlue),
                            const SizedBox(height: 12),
                            const Text('No notifications yet', style: TextStyle(color: LNUColors.textMuted, fontSize: 16)),
                          ],
                        ),
                      ),
                    ])
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      itemCount: _notifications.length,
                      itemBuilder: (_, i) => Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 900),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: _buildNotificationCard(_notifications[i]),
                          ),
                        ),
                      ),
                    ),
            ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> n) {
    final isUnread = n['is_read'] == false;
    final type = n['type'] as String?;
    final color = _colorForType(type);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isUnread ? color.withOpacity(0.05) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: isUnread ? color.withOpacity(0.3) : Colors.transparent),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: isUnread ? () => _markRead(n['id']) : null,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
                child: Icon(_iconForType(type), color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            n['title'] ?? '',
                            style: TextStyle(fontWeight: isUnread ? FontWeight.bold : FontWeight.w600, fontSize: 14),
                          ),
                        ),
                        if (isUnread)
                          Container(
                            width: 8, height: 8,
                            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                          ),
                      ],
                    ),
                    if (n['body'] != null) ...[
                      const SizedBox(height: 4),
                      Text(n['body'], style: const TextStyle(color: LNUColors.textMuted, fontSize: 13)),
                    ],
                    const SizedBox(height: 4),
                    Text(AppHelpers.formatDate(n['created_at']), style: const TextStyle(color: LNUColors.textMuted, fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
