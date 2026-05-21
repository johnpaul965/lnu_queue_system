// lib/features/superadmin/superadmin_requests_screen.dart
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/supabase_service.dart';
import '../../shared/widgets/status_badge.dart';
import '../../core/utils/helpers.dart' show AppHelpers;

class SuperAdminRequestsScreen extends StatefulWidget {
  const SuperAdminRequestsScreen({super.key});

  @override
  State<SuperAdminRequestsScreen> createState() => _SuperAdminRequestsScreenState();
}

class _SuperAdminRequestsScreenState extends State<SuperAdminRequestsScreen> {
  List<Map<String, dynamic>> _requests = [];
  bool _loading = true;
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();

  List<Map<String, dynamic>> get _filtered {
    if (_searchQuery.isEmpty) return _requests;
    final q = _searchQuery.toLowerCase();
    return _requests.where((r) {
      final name = (r['students']?['full_name'] ?? '').toString().toLowerCase();
      final sid = (r['students']?['student_id'] ?? '').toString().toLowerCase();
      final ref = (r['payment_reference'] ?? '').toString().toLowerCase();
      final status = (r['status'] ?? '').toString().toLowerCase();
      return name.contains(q) || sid.contains(q) || ref.contains(q) || status.contains(q);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await SupabaseService.client
          .from('requests')
          .select('*, students(full_name, student_id), document_types(name)')
          .order('created_at', ascending: false);
      if (mounted) {
        setState(() {
          _requests = List<Map<String, dynamic>>.from(data);
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final list = _filtered;
    return Scaffold(
      backgroundColor: LNUColors.background,
      appBar: AppBar(
        title: const Text('All Requests'),
        backgroundColor: LNUColors.primaryDark,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'Search by name, student ID, reference, status...',
                prefixIcon: const Icon(Icons.search, size: 20),
                filled: true,
                fillColor: LNUColors.background,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : list.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off, size: 56, color: LNUColors.textMuted.withOpacity(0.3)),
                            const SizedBox(height: 12),
                            Text(
                              _searchQuery.isEmpty ? 'No requests found' : 'No matching requests',
                              style: const TextStyle(color: LNUColors.textMuted),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 900),
                            child: ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: list.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 8),
                              itemBuilder: (_, i) => _buildCard(list[i]),
                            ),
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> r) {
    final name = r['students']?['full_name'] ?? 'Unknown';
    final sid = r['students']?['student_id'] ?? '';
    final docType = r['document_types']?['name'] ?? 'Document';
    final status = r['status'] ?? '';
    final copies = r['copies'] ?? 1;
    final createdAt = AppHelpers.formatDate(r['created_at']);
    final ref = r['payment_reference'];

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      Text('ID: $sid', style: const TextStyle(fontSize: 12, color: LNUColors.textMuted)),
                    ],
                  ),
                ),
                StatusBadge(status: status),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.description_outlined, size: 14, color: LNUColors.textMuted),
                const SizedBox(width: 4),
                Expanded(child: Text('$docType × $copies', style: const TextStyle(fontSize: 13))),
                Text(createdAt, style: const TextStyle(fontSize: 11, color: LNUColors.textMuted)),
              ],
            ),
            if (ref != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.tag, size: 14, color: LNUColors.textMuted),
                  const SizedBox(width: 4),
                  Text('Ref: $ref', style: const TextStyle(fontSize: 12, color: LNUColors.textMuted)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
