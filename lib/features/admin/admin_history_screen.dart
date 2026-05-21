// lib/features/admin/admin_history_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/supabase_service.dart';
import '../../core/utils/helpers.dart';
import '../../shared/widgets/status_badge.dart';

class AdminHistoryScreen extends StatefulWidget {
  const AdminHistoryScreen({super.key});

  @override
  State<AdminHistoryScreen> createState() => _AdminHistoryScreenState();
}

class _AdminHistoryScreenState extends State<AdminHistoryScreen> {
  List<Map<String, dynamic>> _requests = [];
  bool _loading = false;
  String _filter = 'ALL';
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();
  RealtimeChannel? _channel;

  List<Map<String, dynamic>> get _filtered {
    if (_searchQuery.isEmpty) return _requests;
    final q = _searchQuery.toLowerCase();
    return _requests.where((r) {
      final name = (r['students']?['full_name'] ?? '').toString().toLowerCase();
      final sid  = (r['students']?['student_id'] ?? '').toString().toLowerCase();
      final ref  = (r['payment_reference'] ?? '').toString().toLowerCase();
      return name.contains(q) || sid.contains(q) || ref.contains(q);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _channel = SupabaseService.subscribeToAllRequests(() {
      if (mounted) _loadHistory();
    });
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    try {
      var query = SupabaseService.client
          .from('requests')
          .select('*, students(full_name, student_id), document_types(name)');

      if (_filter == 'COMPLETED') {
        query = query.eq('status', 'COMPLETED');
      } else if (_filter == 'REJECTED') {
        query = query.eq('status', 'REJECTED');
      } else {
        query = query.inFilter('status', ['COMPLETED', 'REJECTED']);
      }

      final data = await query.order('updated_at', ascending: false);
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
    return Scaffold(
      backgroundColor: LNUColors.background,
      appBar: AppBar(
        title: const Text('Request History'),
        backgroundColor: LNUColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadHistory),
        ],
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          _buildSearchBar(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadHistory,
                    child: _filtered.isEmpty
                        ? ListView(children: [
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.55,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.search_off, size: 64, color: LNUColors.lightBlue),
                                  const SizedBox(height: 12),
                                  Text(
                                    _searchQuery.isNotEmpty ? 'No results for "$_searchQuery"' : 'No records found',
                                    style: const TextStyle(color: LNUColors.textMuted, fontSize: 16),
                                  ),
                                ],
                              ),
                            ),
                          ])
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            itemCount: _filtered.length,
                            itemBuilder: (_, i) => Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 900),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: _buildHistoryCard(_filtered[i]),
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

  Widget _buildSearchBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (v) => setState(() => _searchQuery = v.trim()),
        decoration: InputDecoration(
          hintText: 'Search by name, student ID, or reference code…',
          hintStyle: const TextStyle(fontSize: 13, color: LNUColors.textMuted),
          prefixIcon: const Icon(Icons.search, color: LNUColors.textMuted, size: 20),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18, color: LNUColors.textMuted),
                  onPressed: () {
                    _searchCtrl.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          filled: true,
          fillColor: LNUColors.background,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: LNUColors.border)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: LNUColors.border)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: LNUColors.primary)),
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          _chip('All', 'ALL'),
          const SizedBox(width: 8),
          _chip('Completed', 'COMPLETED'),
          const SizedBox(width: 8),
          _chip('Rejected', 'REJECTED'),
        ],
      ),
    );
  }

  Widget _chip(String label, String value) {
    final selected = _filter == value;
    return GestureDetector(
      onTap: () { setState(() => _filter = value); _loadHistory(); },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? LNUColors.primary : LNUColors.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? LNUColors.primary : LNUColors.border),
        ),
        child: Text(label, style: TextStyle(
          color: selected ? LNUColors.white : LNUColors.textMuted,
          fontSize: 12,
          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
        )),
      ),
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> r) {
    final student = r['students'];
    final docType = r['document_types'];
    final status = r['status'] as String? ?? '';
    final isCompleted = status == 'COMPLETED';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push('/admin/requests/${r['id']}'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: isCompleted
                    ? LNUColors.blue.withOpacity(0.12)
                    : LNUColors.black.withOpacity(0.08),
                child: Icon(
                  isCompleted ? Icons.task_alt : Icons.cancel_outlined,
                  color: isCompleted ? LNUColors.blue : LNUColors.black,
                  size: 20,
                ),
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
                          child: Text(student?['full_name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), overflow: TextOverflow.ellipsis),
                        ),
                        StatusBadge(status: status),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(docType?['name'] ?? '—', style: const TextStyle(color: LNUColors.textMuted, fontSize: 13)),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('ID: ${student?['student_id'] ?? '—'}', style: const TextStyle(color: LNUColors.textMuted, fontSize: 12)),
                        Text(AppHelpers.formatShortDate(r['updated_at']), style: const TextStyle(color: LNUColors.textMuted, fontSize: 12)),
                      ],
                    ),
                    if (!isCompleted && r['rejection_reason'] != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text('Reason: ${r['rejection_reason']}', style: const TextStyle(color: LNUColors.black, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                    if (isCompleted && r['assessed_fee'] != null)
                      Text(AppHelpers.formatCurrency(r['assessed_fee']), style: const TextStyle(color: LNUColors.textMuted, fontSize: 12)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: LNUColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
