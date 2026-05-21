// lib/features/superadmin/superadmin_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/supabase_service.dart';

class SuperAdminDashboardScreen extends StatefulWidget {
  const SuperAdminDashboardScreen({super.key});

  @override
  State<SuperAdminDashboardScreen> createState() => _SuperAdminDashboardScreenState();
}

class _SuperAdminDashboardScreenState extends State<SuperAdminDashboardScreen> {
  Map<String, int> _stats = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _loading = true);
    try {
      final students = await SupabaseService.client.from('students').select('id');
      final registrars = await SupabaseService.client.from('admins').select('id');
      final allRequests = await SupabaseService.client.from('requests').select('id');
      final activeRequests = await SupabaseService.client
          .from('requests')
          .select('id')
          .not('status', 'in', '("COMPLETED","REJECTED")');
      final completed = await SupabaseService.client
          .from('requests')
          .select('id')
          .eq('status', 'COMPLETED');

      if (mounted) {
        setState(() {
          _stats = {
            'students': (students as List).length,
            'registrars': (registrars as List).length,
            'total_requests': (allRequests as List).length,
            'active_requests': (activeRequests as List).length,
            'completed': (completed as List).length,
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
        title: const Text('Admin Dashboard'),
        backgroundColor: LNUColors.primaryDark,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadStats),
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => context.push('/superadmin/profile'),
          ),
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
                          const SizedBox(height: 24),
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
          colors: [LNUColors.primaryDark, LNUColors.primary],
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
                const Icon(Icons.shield_outlined, color: Colors.white70, size: 24),
                const SizedBox(height: 4),
                const Text(
                  'System Administration',
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Text(
                  'LNU Registrar Queue & Request System',
                  style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('System Overview', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        LayoutBuilder(builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 600;
          return GridView.count(
            crossAxisCount: isDesktop ? 5 : 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: isDesktop ? 1.1 : 1.2,
            children: [
              _statCard('Students', _stats['students'] ?? 0, Icons.school_outlined, LNUColors.primaryLight),
              _statCard('Registrars', _stats['registrars'] ?? 0, Icons.badge_outlined, LNUColors.secondary),
              _statCard('Total Requests', _stats['total_requests'] ?? 0, Icons.description_outlined, LNUColors.primary),
              _statCard('Active', _stats['active_requests'] ?? 0, Icons.pending_actions_outlined, LNUColors.statusIncomplete),
              _statCard('Completed', _stats['completed'] ?? 0, Icons.check_circle_outline, Colors.green.shade700),
            ],
          );
        }),
      ],
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
      _MenuItem('Manage Registrars', Icons.badge_outlined, LNUColors.secondary,
          '/superadmin/registrars', 'Create and manage registrar accounts'),
      _MenuItem('View All Requests', Icons.description_outlined, LNUColors.primary,
          '/superadmin/requests', 'View all document requests system-wide'),
    ];
    return LayoutBuilder(builder: (context, constraints) {
      final isDesktop = constraints.maxWidth >= 600;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Management', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          if (isDesktop)
            Row(
              children: items
                  .map((m) => Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: _buildMenuTile(m),
                        ),
                      ))
                  .toList(),
            )
          else
            ...items.map((m) => _buildMenuTile(m)),
        ],
      );
    });
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
