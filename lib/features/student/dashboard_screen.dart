// lib/features/student/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/supabase_service.dart';
import '../../shared/widgets/status_badge.dart';
import '../../shared/widgets/request_status_stepper.dart';
import '../../core/utils/helpers.dart';
import '../../../main.dart' show preloadedStudent;

class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  Map<String, dynamic>? _student;
  List<Map<String, dynamic>> _activeRequests = [];
  int _unreadCount = 0;
  bool _loading = true;
  RealtimeChannel? _channel;

  @override
  void initState() {
    super.initState();
    final preloaded = preloadedStudent;
    if (preloaded != null) {
      _student = preloaded;
      _fetchRequests(preloaded['id']);
    } else {
      _loadData();
    }
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        if (mounted) context.go('/login');
        return;
      }
      final student = await SupabaseService.getStudentByAuthId(user.id);
      await _fetchRequests(student['id']);

      // Subscribe for real-time updates once we have the student ID
      _channel?.unsubscribe();
      _channel = SupabaseService.subscribeToMyRequests(student['id'], (_) {
        if (mounted) _fetchRequests(student['id']);
      });

      if (mounted) setState(() { _student = student; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _fetchRequests(String studentId) async {
    final requests = await SupabaseService.client
        .from('requests')
        .select('*, document_types(name)')
        .eq('student_id', studentId)
        .not('status', 'in', '("COMPLETED","REJECTED")')
        .order('created_at', ascending: false)
        .limit(5);
    final notifications = await SupabaseService.client
        .from('notifications')
        .select('id')
        .eq('student_id', studentId)
        .eq('is_read', false);
    if (mounted) {
      setState(() {
        _activeRequests = List<Map<String, dynamic>>.from(requests);
        _unreadCount = (notifications as List).length;
      });
    }
  }

  Future<void> _logout() async {
    _channel?.unsubscribe();
    await SupabaseService.logout();
    if (mounted) context.go('/login');
  }

  Widget _buildOrphanedAccountScreen() {
    return Scaffold(
      backgroundColor: LNUColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 72, color: LNUColors.yellow),
              const SizedBox(height: 20),
              const Text('Account Setup Incomplete',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              const SizedBox(height: 12),
              Text('Your account was not fully set up. Please log out and register again.',
                  style: const TextStyle(fontSize: 14, color: LNUColors.textMuted), textAlign: TextAlign.center),
              const SizedBox(height: 28),
              ElevatedButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout),
                label: const Text('Log Out & Register Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: LNUColors.primary, foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_loading && _student == null) return _buildOrphanedAccountScreen();

    return Scaffold(
      backgroundColor: LNUColors.background,
      appBar: AppBar(
        title: const Text('LNU Registrar'),
        backgroundColor: LNUColors.primary,
        foregroundColor: Colors.white,
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                tooltip: 'Notifications',
                onPressed: () => context.push('/student/notifications').then((_) => _loadData()),
              ),
              if (_unreadCount > 0)
                Positioned(
                  right: 8, top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(color: LNUColors.yellow, shape: BoxShape.circle),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text('$_unreadCount',
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center),
                  ),
                ),
            ],
          ),
          IconButton(icon: const Icon(Icons.person_outline), onPressed: () => context.push('/student/profile')),
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 960),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildWelcomeCard(),
                          const SizedBox(height: 16),
                          _buildActionRequired(),
                          _buildQuickActions(),
                          const SizedBox(height: 20),
                          _buildActiveRequests(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [LNUColors.primary, LNUColors.primaryLight],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Image.asset('assets/lnu_logo.png', width: 60, height: 60, fit: BoxFit.contain),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.waving_hand, color: Colors.white70, size: 22),
                const SizedBox(height: 4),
                Text('Hello, ${_student?['full_name']?.split(' ').first ?? 'Student'}!',
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text('ID: ${_student?['student_id'] ?? '—'}',
                    style: const TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Shows an alert banner when there's a request needing student attention
  Widget _buildActionRequired() {
    final incomplete = _activeRequests.where((r) => r['status'] == 'INCOMPLETE').toList();
    final forPayment = _activeRequests.where((r) => r['status'] == 'FOR_PAYMENT').toList();
    final forClaiming = _activeRequests.where((r) => r['status'] == 'FOR_CLAIMING').toList();

    if (incomplete.isEmpty && forPayment.isEmpty && forClaiming.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        if (incomplete.isNotEmpty)
          _buildAlertBanner(
            icon: Icons.warning_amber_rounded,
            color: LNUColors.statusIncomplete,
            message: '${incomplete.length} request(s) have incomplete requirements. Tap "My Requests" to resubmit.',
          ),
        if (forPayment.isNotEmpty)
          _buildAlertBanner(
            icon: Icons.payment_outlined,
            color: LNUColors.statusForPayment,
            message: '${forPayment.length} request(s) approved — please proceed to the cashier to pay.',
          ),
        if (forClaiming.isNotEmpty)
          _buildAlertBanner(
            icon: Icons.event_available_outlined,
            color: LNUColors.statusForClaiming,
            message: '${forClaiming.length} document(s) ready for pickup. Check your scheduled date.',
          ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildAlertBanner({required IconData icon, required Color color, required String message}) {
    return GestureDetector(
      onTap: () => context.push('/student/history').then((_) => _loadData()),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(message, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w500))),
            Icon(Icons.chevron_right, color: color, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      _ActionItem('New Request', Icons.add_circle_outline, LNUColors.primary, '/student/new-request'),
      _ActionItem('My Requests', Icons.folder_open_outlined, LNUColors.primaryLight, '/student/history'),
      _ActionItem('Notifications', Icons.notifications_outlined, LNUColors.secondary, '/student/notifications'),
      _ActionItem('My Profile', Icons.person_outline, LNUColors.primaryDark, '/student/profile'),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 600;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Quick Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: isDesktop ? 4 : 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12, mainAxisSpacing: 12,
              childAspectRatio: isDesktop ? 1.8 : 1.6,
              children: actions.map((a) => _buildActionCard(a)).toList(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildActionCard(_ActionItem item) {
    return GestureDetector(
      onTap: () => context.push(item.route).then((_) => _loadData()),
      child: Container(
        decoration: BoxDecoration(
          color: LNUColors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: LNUColors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(item.icon, color: item.color, size: 28),
            Text(item.label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveRequests() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Active Requests', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Row(
              children: [
                Container(
                  width: 8, height: 8,
                  decoration: const BoxDecoration(color: LNUColors.blue, shape: BoxShape.circle),
                ),
                const SizedBox(width: 4),
                const Text('Live', style: TextStyle(fontSize: 11, color: LNUColors.blue, fontWeight: FontWeight.w500)),
                const SizedBox(width: 12),
                TextButton(
                  onPressed: () => context.push('/student/history').then((_) => _loadData()),
                  child: const Text('View All', style: TextStyle(color: LNUColors.primary)),
                ),
              ],
            ),
          ],
        ),
        if (_activeRequests.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                Icon(Icons.inbox_outlined, size: 48, color: LNUColors.lightBlue),
                const SizedBox(height: 8),
                const Text('No active requests', style: TextStyle(color: LNUColors.textMuted)),
                const SizedBox(height: 4),
                const Text('Tap "New Request" to submit a document request.',
                    style: TextStyle(color: LNUColors.textMuted, fontSize: 12), textAlign: TextAlign.center),
              ],
            ),
          )
        else
          ..._activeRequests.map((r) => _buildRequestTile(r)),
      ],
    );
  }

  Widget _buildRequestTile(Map<String, dynamic> r) {
    final docType = r['document_types'];
    final status = r['status'] as String? ?? '';
    final claimDate = r['claim_date'];

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(docType?['name'] ?? 'Document',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14), overflow: TextOverflow.ellipsis),
                ),
                StatusBadge(status: status),
              ],
            ),
            const SizedBox(height: 4),
            Text(AppHelpers.formatShortDate(r['created_at']),
                style: const TextStyle(color: LNUColors.textMuted, fontSize: 12)),
            const SizedBox(height: 10),
            RequestStatusStepper(status: status),
            if (status == 'FOR_CLAIMING' && claimDate != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.event_available, color: LNUColors.statusForClaiming, size: 15),
                  const SizedBox(width: 6),
                  Text('Pickup: ${AppHelpers.formatShortDate(claimDate)}',
                      style: const TextStyle(color: LNUColors.statusForClaiming, fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ActionItem {
  final String label;
  final IconData icon;
  final Color color;
  final String route;
  const _ActionItem(this.label, this.icon, this.color, this.route);
}
