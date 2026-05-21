// lib/features/admin/admin_requests_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/supabase_service.dart';
import '../../shared/widgets/status_badge.dart';
import '../../core/utils/helpers.dart';

class AdminRequestsScreen extends StatefulWidget {
  const AdminRequestsScreen({super.key});

  @override
  State<AdminRequestsScreen> createState() => _AdminRequestsScreenState();
}

class _AdminRequestsScreenState extends State<AdminRequestsScreen> {
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

  final _filters = const [
    ('All Active', 'ALL'),
    ('Submitted', 'SUBMITTED'),
    ('Under Review', 'UNDER_REVIEW'),
    ('Incomplete', 'INCOMPLETE'),
    ('For Payment', 'FOR_PAYMENT'),
    ('Processing', 'PROCESSING'),
    ('For Claiming', 'FOR_CLAIMING'),
  ];

  @override
  void initState() {
    super.initState();
    _load();
    _channel = SupabaseService.subscribeToAllRequests(() {
      if (mounted) _load();
    });
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      var query = SupabaseService.client
          .from('requests')
          .select('*, students(full_name, student_id), document_types(name)');

      if (_filter == 'ALL') {
        query = query.not('status', 'in', '("COMPLETED","REJECTED")');
      } else {
        query = query.eq('status', _filter);
      }

      final data = await query.order('created_at', ascending: false);
      if (mounted) setState(() { _requests = List<Map<String, dynamic>>.from(data); _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LNUColors.background,
      appBar: AppBar(
        title: const Text('Manage Requests'),
        backgroundColor: LNUColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Row(
              children: [
                Container(width: 7, height: 7, decoration: const BoxDecoration(color: LNUColors.lightBlue, shape: BoxShape.circle)),
                const SizedBox(width: 4),
                const Text('Live', style: TextStyle(fontSize: 11, color: LNUColors.lightBlue)),
              ],
            ),
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
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
                    onRefresh: _load,
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
                                    _searchQuery.isNotEmpty ? 'No results for "$_searchQuery"' : 'No requests found',
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
                                  child: _buildRequestCard(_filtered[i]),
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
      color: LNUColors.white,
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
      color: LNUColors.white,
      height: 46,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: _filters.length,
        itemBuilder: (_, i) {
          final (label, value) = _filters[i];
          final selected = _filter == value;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () { setState(() => _filter = value); _load(); },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
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
            ),
          );
        },
      ),
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> r) {
    final student = r['students'];
    final docType = r['document_types'];
    final status = r['status'] as String? ?? '';
    final isNew = status == 'SUBMITTED';
    final isUrgent = status == 'SUBMITTED' || status == 'FOR_CLAIMING';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isNew ? const BorderSide(color: LNUColors.statusSubmitted, width: 1.5) : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push('/admin/requests/${r['id']}').then((_) => _load()),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    backgroundColor: LNUColors.forStatus(status).withOpacity(0.12),
                    child: Icon(Icons.description_outlined, color: LNUColors.forStatus(status), size: 20),
                  ),
                  if (isUrgent)
                    Positioned(
                      right: 0, top: 0,
                      child: Container(
                        width: 10, height: 10,
                        decoration: const BoxDecoration(color: LNUColors.yellow, shape: BoxShape.circle,
                            border: Border.fromBorderSide(BorderSide(color: LNUColors.white, width: 1.5))),
                      ),
                    ),
                ],
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
                          child: Text(student?['full_name'] ?? 'Unknown',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), overflow: TextOverflow.ellipsis),
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
                        Text(AppHelpers.formatShortDate(r['created_at']), style: const TextStyle(color: LNUColors.textMuted, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: LNUColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
