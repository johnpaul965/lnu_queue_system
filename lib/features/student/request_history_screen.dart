// lib/features/student/request_history_screen.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/supabase_service.dart';
import '../../shared/widgets/status_badge.dart';
import '../../shared/widgets/request_status_stepper.dart';
import '../../core/utils/helpers.dart';
import '../../../main.dart' show preloadedStudent;

class RequestHistoryScreen extends StatefulWidget {
  const RequestHistoryScreen({super.key});

  @override
  State<RequestHistoryScreen> createState() => _RequestHistoryScreenState();
}

class _RequestHistoryScreenState extends State<RequestHistoryScreen> {
  List<Map<String, dynamic>> _requests = [];
  bool _loading = false;
  String _filter = 'ACTIVE';
  String? _studentId;
  RealtimeChannel? _channel;

  @override
  void initState() {
    super.initState();
    final preloaded = preloadedStudent;
    if (preloaded != null) _studentId = preloaded['id'] as String?;
    _init();
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }

  Future<void> _init() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    if (_studentId == null) {
      final student = await SupabaseService.getStudentByAuthId(user.id);
      _studentId = student['id'];
    }

    await _loadRequests();

    _channel?.unsubscribe();
    _channel = SupabaseService.subscribeToMyRequests(_studentId!, (_) {
      if (mounted) _loadRequests();
    });
  }

  Future<void> _loadRequests() async {
    if (_studentId == null) return;
    try {
      var query = SupabaseService.client
          .from('requests')
          .select('*, document_types(name, requirements)')
          .eq('student_id', _studentId!);

      if (_filter == 'ACTIVE') {
        query = query.not('status', 'in', '("COMPLETED","REJECTED")');
      } else if (_filter == 'COMPLETED') {
        query = query.eq('status', 'COMPLETED');
      } else if (_filter == 'REJECTED') {
        query = query.eq('status', 'REJECTED');
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
        title: const Text('My Requests'),
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
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadRequests),
        ],
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadRequests,
                    child: _requests.isEmpty
                        ? ListView(children: [
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.55,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.inbox_outlined, size: 64, color: LNUColors.lightBlue),
                                  const SizedBox(height: 12),
                                  const Text('No requests found', style: TextStyle(color: LNUColors.textMuted, fontSize: 16)),
                                ],
                              ),
                            ),
                          ])
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            itemCount: _requests.length,
                            itemBuilder: (_, i) => Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 900),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: _buildRequestCard(_requests[i]),
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

  Widget _buildFilterBar() {
    return Container(
      color: LNUColors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          _chip('Active', 'ACTIVE'),
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
      onTap: () { setState(() => _filter = value); _loadRequests(); },
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

  Widget _buildRequestCard(Map<String, dynamic> r) {
    final docType = r['document_types'];
    final status = r['status'] as String? ?? '';
    final claimDate = r['claim_date'];
    final rejectionReason = r['rejection_reason'];
    final paymentNote = r['payment_note'];
    final assessedFee = r['assessed_fee'];
    final paymentRef = r['payment_reference'] as String?;
    final isIncomplete = status == 'INCOMPLETE';
    final isForPayment = status == 'FOR_PAYMENT';

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isIncomplete
            ? BorderSide(color: LNUColors.statusIncomplete, width: 1.5)
            : isForPayment
                ? BorderSide(color: LNUColors.statusForPayment, width: 1.5)
                : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(docType?['name'] ?? 'Document',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15), overflow: TextOverflow.ellipsis),
                ),
                StatusBadge(status: status),
              ],
            ),
            const SizedBox(height: 6),
            _infoRow(Icons.numbers, 'Copies: ${r['copies'] ?? 1}'),
            _infoRow(Icons.attach_money, 'Base Fee: ${AppHelpers.formatCurrency(r['base_fee'])}'),
            if (assessedFee != null)
              _infoRow(Icons.receipt_long, 'Assessed Fee: ${AppHelpers.formatCurrency(assessedFee)}', color: LNUColors.primary),
            _infoRow(Icons.calendar_today, 'Submitted: ${AppHelpers.formatDate(r['created_at'])}'),
            if (r['purpose'] != null && r['purpose'].toString().isNotEmpty)
              _infoRow(Icons.notes, 'Purpose: ${r['purpose']}'),

            const SizedBox(height: 12),

            // Status progress tracker
            RequestStatusStepper(status: status),

            // ── CLAIM DATE banner ──────────────────────────────────
            if (status == 'FOR_CLAIMING' && claimDate != null) ...[
              const SizedBox(height: 12),
              _buildBanner(
                color: LNUColors.statusForClaiming,
                icon: Icons.event_available,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Scheduled Pickup Date',
                        style: TextStyle(fontSize: 11, color: LNUColors.statusForClaiming, fontWeight: FontWeight.w600)),
                    Text(AppHelpers.formatShortDate(claimDate),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: LNUColors.statusForClaiming)),
                    const Text('Please bring your valid school ID.',
                        style: TextStyle(fontSize: 11, color: LNUColors.statusForClaiming)),
                  ],
                ),
              ),
            ],

            // ── FOR PAYMENT action banner ──────────────────────────
            if (isForPayment) ...[
              const SizedBox(height: 12),
              _buildBanner(
                color: LNUColors.statusForPayment,
                icon: Icons.payment_outlined,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Action Required: Proceed to Cashier',
                        style: TextStyle(fontSize: 12, color: LNUColors.statusForPayment, fontWeight: FontWeight.bold)),
                    if (assessedFee != null) ...[
                      const SizedBox(height: 4),
                      Text('Amount to pay: ${AppHelpers.formatCurrency(assessedFee)}',
                          style: const TextStyle(fontSize: 13, color: LNUColors.darkBlue, fontWeight: FontWeight.w600)),
                    ],
                    if (paymentRef != null) ...[
                      const SizedBox(height: 8),
                      const Text('Your Reference Code',
                          style: TextStyle(fontSize: 11, color: LNUColors.textMuted, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: LNUColors.statusForPayment, width: 1.5),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.confirmation_number_outlined, size: 16, color: LNUColors.primary),
                            const SizedBox(width: 8),
                            Text(
                              paymentRef,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: LNUColors.primary,
                                letterSpacing: 2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text('Show this code to the cashier when paying.',
                          style: TextStyle(fontSize: 11, color: LNUColors.darkBlue)),
                    ],
                    if (paymentNote != null && paymentNote.toString().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(paymentNote, style: const TextStyle(fontSize: 12, color: LNUColors.darkBlue)),
                    ],
                  ],
                ),
              ),
            ],

            // ── INCOMPLETE / REJECTED reason ──────────────────────
            if ((isIncomplete || status == 'REJECTED') && rejectionReason != null) ...[
              const SizedBox(height: 12),
              _buildBanner(
                color: isIncomplete ? LNUColors.statusIncomplete : LNUColors.statusRejected,
                icon: isIncomplete ? Icons.warning_amber_outlined : Icons.cancel_outlined,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(isIncomplete ? 'Incomplete Requirements' : 'Request Rejected',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isIncomplete ? LNUColors.statusIncomplete : LNUColors.statusRejected,
                        )),
                    const SizedBox(height: 2),
                    Text(rejectionReason, style: const TextStyle(
                      fontSize: 12,
                      color: LNUColors.black,
                    )),
                  ],
                ),
              ),
            ],

            // ── RESUBMIT button (only when INCOMPLETE) ────────────
            if (isIncomplete) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showResubmitSheet(r),
                  icon: const Icon(Icons.upload_file_outlined, size: 18),
                  label: const Text('Resubmit Requirements'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: LNUColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],

            _buildRequirementFiles(r),
          ],
        ),
      ),
    );
  }

  Widget _buildBanner({required Color color, required IconData icon, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _buildRequirementFiles(Map<String, dynamic> r) {
    final urls = r['requirement_urls'] as List?;
    if (urls == null || urls.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Uploaded Files (${urls.length})',
              style: const TextStyle(fontSize: 12, color: LNUColors.textMuted, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6, runSpacing: 4,
            children: urls.asMap().entries.map((e) => Chip(
              label: Text('File ${e.key + 1}', style: const TextStyle(fontSize: 11)),
              avatar: const Icon(Icons.attach_file, size: 14),
              backgroundColor: LNUColors.primary.withOpacity(0.08),
              side: BorderSide(color: LNUColors.primary.withOpacity(0.2)),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color ?? LNUColors.textMuted),
          const SizedBox(width: 6),
          Expanded(child: Text(text, style: TextStyle(color: color ?? LNUColors.textMuted, fontSize: 13), overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }

  // ── RESUBMIT BOTTOM SHEET ────────────────────────────────
  void _showResubmitSheet(Map<String, dynamic> request) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ResubmitSheet(
        request: request,
        studentId: _studentId ?? '',
        onSuccess: () {
          Navigator.pop(context);
          _loadRequests();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Requirements resubmitted successfully! The registrar will review your updated files.'),
              backgroundColor: LNUColors.darkBlue,
              duration: Duration(seconds: 4),
            ),
          );
        },
      ),
    );
  }
}

// ── RESUBMIT SHEET WIDGET ────────────────────────────────────────────────────
class _ResubmitSheet extends StatefulWidget {
  final Map<String, dynamic> request;
  final String studentId;
  final VoidCallback onSuccess;
  const _ResubmitSheet({required this.request, required this.studentId, required this.onSuccess});

  @override
  State<_ResubmitSheet> createState() => _ResubmitSheetState();
}

class _ResubmitSheetState extends State<_ResubmitSheet> {
  final List<_UploadedFile> _files = [];
  bool _submitting = false;
  final _picker = ImagePicker();

  Future<void> _pickFile() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    setState(() => _files.add(_UploadedFile(name: picked.name, bytes: bytes)));
  }

  Future<void> _submit() async {
    if (_files.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one file'), backgroundColor: LNUColors.yellow),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      final requestId = widget.request['id'] as String;
      final tempId = '${requestId}_resubmit_${DateTime.now().millisecondsSinceEpoch}';
      final List<String> urls = [];
      for (final file in _files) {
        final url = await SupabaseService.uploadRequirementFile(
          requestId: tempId, fileBytes: file.bytes, fileName: file.name,
        );
        urls.add(url);
      }
      await SupabaseService.resubmitRequest(requestId: requestId, newRequirementUrls: urls);
      widget.onSuccess();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: LNUColors.yellow),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final docType = widget.request['document_types'];
    final requirements = docType?['requirements'] as List?;
    final reason = widget.request['rejection_reason'] as String? ?? '';

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: LNUColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40, height: 4,
              decoration: BoxDecoration(color: LNUColors.border, borderRadius: BorderRadius.circular(2)),
            ),
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.all(20),
                children: [
                  const Text('Resubmit Requirements', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('for: ${docType?['name'] ?? ''}', style: const TextStyle(color: LNUColors.textMuted, fontSize: 13)),
                  const SizedBox(height: 12),

                  // Show registrar's feedback
                  if (reason.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: LNUColors.statusIncomplete.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: LNUColors.statusIncomplete.withOpacity(0.3)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.warning_amber_outlined, color: LNUColors.statusIncomplete, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Registrar Feedback', style: TextStyle(color: LNUColors.statusIncomplete, fontWeight: FontWeight.bold, fontSize: 12)),
                                const SizedBox(height: 2),
                                Text(reason, style: const TextStyle(color: LNUColors.black, fontSize: 13)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Required documents list
                  if (requirements != null && requirements.isNotEmpty) ...[
                    const Text('Required Documents', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 8),
                    ...requirements.asMap().entries.map((e) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 20, height: 20,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(color: LNUColors.primary.withOpacity(0.1), shape: BoxShape.circle),
                            child: Text('${e.key + 1}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: LNUColors.primary)),
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: Text(e.value.toString(), style: const TextStyle(fontSize: 13))),
                        ],
                      ),
                    )),
                    const SizedBox(height: 14),
                  ],

                  // File upload section
                  const Text('Upload Corrected Files', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 4),
                  const Text('Upload new or corrected copies of the required documents.',
                      style: TextStyle(fontSize: 12, color: LNUColors.textMuted)),
                  const SizedBox(height: 10),

                  if (_files.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: LNUColors.background, borderRadius: BorderRadius.circular(8)),
                      child: Column(children: [
                        const Icon(Icons.cloud_upload_outlined, size: 36, color: LNUColors.lightBlue),
                        const SizedBox(height: 6),
                        const Text('No files added yet', style: TextStyle(color: LNUColors.textMuted, fontSize: 13)),
                      ]),
                    )
                  else
                    ..._files.asMap().entries.map((e) => Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: LNUColors.primary.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: LNUColors.primary.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.image_outlined, color: LNUColors.primary, size: 18),
                          const SizedBox(width: 8),
                          Expanded(child: Text(e.value.name, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis)),
                          IconButton(
                            icon: const Icon(Icons.close, size: 18, color: LNUColors.textMuted),
                            onPressed: () => setState(() => _files.removeAt(e.key)),
                            constraints: const BoxConstraints(), padding: EdgeInsets.zero,
                          ),
                        ],
                      ),
                    )),

                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: _submitting ? null : _pickFile,
                    icon: const Icon(Icons.add_photo_alternate_outlined),
                    label: const Text('Add File'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: LNUColors.primary,
                      side: const BorderSide(color: LNUColors.primary),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _submitting ? null : _submit,
                    icon: _submitting
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.send_outlined),
                    label: Text(_submitting ? 'Submitting...' : 'Resubmit to Registrar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: LNUColors.primary, foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UploadedFile {
  final String name;
  final Uint8List bytes;
  _UploadedFile({required this.name, required this.bytes});
}
