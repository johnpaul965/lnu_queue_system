// lib/features/admin/admin_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/supabase_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  Map<String, int> _stats = {};
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final submitted = await SupabaseService.client.from('requests').select('id').eq('status', 'SUBMITTED');
      final underReview = await SupabaseService.client.from('requests').select('id').eq('status', 'UNDER_REVIEW');
      final incomplete = await SupabaseService.client.from('requests').select('id').eq('status', 'INCOMPLETE');
      final forPayment = await SupabaseService.client.from('requests').select('id').eq('status', 'FOR_PAYMENT');
      final processing = await SupabaseService.client.from('requests').select('id')
          .inFilter('status', ['PAYMENT_VERIFIED', 'PROCESSING']);
      final forClaiming = await SupabaseService.client.from('requests').select('id').eq('status', 'FOR_CLAIMING');
      final completed = await SupabaseService.client.from('requests').select('id').eq('status', 'COMPLETED');

      if (mounted) {
        setState(() {
          _stats = {
            'submitted':    (submitted as List).length,
            'under_review': (underReview as List).length,
            'incomplete':   (incomplete as List).length,
            'for_payment':  (forPayment as List).length,
            'processing':   (processing as List).length,
            'for_claiming': (forClaiming as List).length,
            'completed':    (completed as List).length,
          };
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _logout() async {
    await SupabaseService.logout();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LNUColors.background,
      appBar: AppBar(
        title: const Text('Registrar Dashboard'),
        backgroundColor: LNUColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadStats),
          IconButton(icon: const Icon(Icons.person_outline), onPressed: () => context.push('/admin/profile')),
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadStats,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 960),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(),
                          const SizedBox(height: 20),
                          _buildPendingAlert(),
                          const SizedBox(height: 16),
                          _buildStatsSection(),
                          const SizedBox(height: 24),
                          _buildMenuSection(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [LNUColors.primary, LNUColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
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
                const Icon(Icons.admin_panel_settings, color: Colors.white70, size: 24),
                const SizedBox(height: 4),
                const Text('Registrar Panel', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                Text(
                  'LNU Document Request & Scheduling',
                  style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingAlert() {
    final pending = (_stats['submitted'] ?? 0) + (_stats['under_review'] ?? 0);
    if (pending == 0) return const SizedBox.shrink();
    return GestureDetector(
      onTap: () => context.push('/admin/requests'),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: LNUColors.statusSubmitted.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: LNUColors.statusSubmitted.withOpacity(0.4)),
        ),
        child: Row(
          children: [
            const Icon(Icons.inbox, color: LNUColors.statusSubmitted, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '$pending request(s) awaiting review',
                style: const TextStyle(color: LNUColors.statusSubmitted, fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ),
            const Icon(Icons.chevron_right, color: LNUColors.statusSubmitted),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 600;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Overview', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: isDesktop ? 6 : 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: isDesktop ? 1.1 : 0.95,
              children: [
                _statCard('Submitted', _stats['submitted'] ?? 0, Icons.inbox_outlined, LNUColors.statusSubmitted),
                _statCard('Under Review', _stats['under_review'] ?? 0, Icons.find_in_page_outlined, LNUColors.statusUnderReview),
                _statCard('Incomplete', _stats['incomplete'] ?? 0, Icons.warning_amber_outlined, LNUColors.statusIncomplete),
                _statCard('For Payment', _stats['for_payment'] ?? 0, Icons.payment_outlined, LNUColors.statusForPayment),
                _statCard('Processing', _stats['processing'] ?? 0, Icons.sync_outlined, LNUColors.statusProcessing),
                _statCard('For Claiming', _stats['for_claiming'] ?? 0, Icons.event_available_outlined, LNUColors.statusForClaiming),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _statCard(String label, int value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: LNUColors.black.withOpacity(0.06), blurRadius: 8)],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 6),
          Text('$value', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 10, color: LNUColors.textMuted), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildMenuSection() {
    final items = [
      _MenuItem('Manage Requests', Icons.folder_open_outlined, LNUColors.primary, '/admin/requests',
          'Review, approve, and process document requests'),
      _MenuItem('Request History', Icons.history_outlined, LNUColors.primaryDark, '/admin/history',
          'View completed and rejected requests'),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 600;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Management', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (isDesktop)
              Row(
                children: items
                    .map((m) => Expanded(child: Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: _buildMenuTile(m),
                        )))
                    .toList(),
              )
            else
              ...items.map((m) => _buildMenuTile(m)),
          ],
        );
      },
    );
  }

  Widget _buildMenuTile(_MenuItem m) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: m.color.withOpacity(0.12),
          child: Icon(m.icon, color: m.color),
        ),
        title: Text(m.label, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(m.subtitle, style: const TextStyle(fontSize: 12, color: LNUColors.textMuted)),
        trailing: const Icon(Icons.chevron_right, color: LNUColors.textMuted),
        onTap: () => context.push(m.route).then((_) => _loadStats()),
      ),
    );
  }
}

class _MenuItem {
  final String label;
  final IconData icon;
  final Color color;
  final String route;
  final String subtitle;
  const _MenuItem(this.label, this.icon, this.color, this.route, this.subtitle);
}
