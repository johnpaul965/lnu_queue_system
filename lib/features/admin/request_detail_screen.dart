// lib/features/admin/request_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/supabase_service.dart';
import '../../shared/widgets/status_badge.dart';
import '../../core/utils/helpers.dart';

class RequestDetailScreen extends StatefulWidget {
  final String requestId;
  const RequestDetailScreen({super.key, required this.requestId});

  @override
  State<RequestDetailScreen> createState() => _RequestDetailScreenState();
}

class _RequestDetailScreenState extends State<RequestDetailScreen> {
  Map<String, dynamic>? _request;
  bool _loading = true;
  bool _acting = false;

  @override
  void initState() {
    super.initState();
    _loadRequest();
  }

  Future<void> _loadRequest() async {
    try {
      final data = await SupabaseService.client
          .from('requests')
          .select('*, students(full_name, student_id, email), document_types(name, base_fee, requirements)')
          .eq('id', widget.requestId)
          .single();
      if (mounted) setState(() { _request = Map<String, dynamic>.from(data); _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _act(Future<void> Function() action) async {
    if (_acting) return;
    setState(() => _acting = true);
    try {
      await action();
      await _loadRequest();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Done'), backgroundColor: LNUColors.darkBlue),
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: LNUColors.yellow),
      );
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  void _showMarkUnderReview() {
    _act(() => SupabaseService.markUnderReview(widget.requestId));
  }

  void _showApproveDialog() {
    final feeCtrl = TextEditingController(
      text: (_request?['assessed_fee'] ?? _request?['base_fee'])?.toString() ?? '',
    );
    final noteCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Approve Request'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: feeCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Assessed Fee (₱)', prefixText: '₱'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Payment Note (optional)',
                hintText: 'e.g. Pay at Cashier Window 2',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              final fee = double.tryParse(feeCtrl.text) ?? 0.0;
              _act(() => SupabaseService.approveRequest(
                requestId: widget.requestId,
                assessedFee: fee,
                paymentNote: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
              ));
            },
            style: ElevatedButton.styleFrom(backgroundColor: LNUColors.statusForPayment),
            child: const Text('Approve', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showIncompleteDialog() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Mark as Incomplete'),
        content: TextField(
          controller: ctrl,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'What is missing?',
            hintText: 'e.g. VPSD Clearance is missing or unclear',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (ctrl.text.trim().isEmpty) return;
              Navigator.pop(context);
              _act(() => SupabaseService.markIncomplete(requestId: widget.requestId, reason: ctrl.text.trim()));
            },
            style: ElevatedButton.styleFrom(backgroundColor: LNUColors.statusIncomplete),
            child: const Text('Send', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reject Request'),
        content: TextField(
          controller: ctrl,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Reason for rejection',
            hintText: 'e.g. Student is not enrolled this semester',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (ctrl.text.trim().isEmpty) return;
              Navigator.pop(context);
              _act(() => SupabaseService.rejectRequest(requestId: widget.requestId, reason: ctrl.text.trim()));
            },
            style: ElevatedButton.styleFrom(backgroundColor: LNUColors.statusRejected),
            child: const Text('Reject', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showVerifyPaymentDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Verify Payment'),
        content: const Text('Confirm that the student has paid the assessed fee at the cashier?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _act(() => SupabaseService.verifyPayment(widget.requestId));
            },
            style: ElevatedButton.styleFrom(backgroundColor: LNUColors.statusVerified),
            child: const Text('Confirm', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showScheduleClaimDialog() {
    DateTime? selectedDate;
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setInner) => AlertDialog(
          title: const Text('Schedule Claim Date'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Select the date when the student can pick up their document.'),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: DateTime.now().add(const Duration(days: 3)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) setInner(() => selectedDate = picked);
                },
                icon: const Icon(Icons.calendar_today),
                label: Text(selectedDate == null
                    ? 'Pick a Date'
                    : '${selectedDate!.month}/${selectedDate!.day}/${selectedDate!.year}'),
                style: ElevatedButton.styleFrom(backgroundColor: LNUColors.primary, foregroundColor: Colors.white),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: selectedDate == null ? null : () {
                Navigator.pop(context);
                _act(() => SupabaseService.setClaimDate(requestId: widget.requestId, claimDate: selectedDate!));
              },
              style: ElevatedButton.styleFrom(backgroundColor: LNUColors.statusForClaiming),
              child: const Text('Schedule', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showMarkCompletedDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Mark as Completed'),
        content: const Text('Confirm that the student has picked up their document?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _act(() => SupabaseService.markAsCompleted(widget.requestId));
            },
            style: ElevatedButton.styleFrom(backgroundColor: LNUColors.statusCompleted),
            child: const Text('Confirm', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LNUColors.background,
      appBar: AppBar(
        title: const Text('Request Detail'),
        backgroundColor: LNUColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _request == null
              ? const Center(child: Text('Request not found'))
              : SingleChildScrollView(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 860),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildStatusCard(),
                            const SizedBox(height: 12),
                            _buildStudentCard(),
                            const SizedBox(height: 12),
                            _buildRequestCard(),
                            const SizedBox(height: 12),
                            _buildRequirementFiles(),
                            const SizedBox(height: 20),
                            _buildActionButtons(),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
    );
  }

  Widget _buildStatusCard() {
    final status = _request!['status'] as String? ?? '';
    final claimDate = _request!['claim_date'];
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Current Status', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                StatusBadge(status: status),
              ],
            ),
            if (claimDate != null) ...[
              const SizedBox(height: 8),
              _row('Claim Date', AppHelpers.formatShortDate(claimDate)),
            ],
            if (_request!['rejection_reason'] != null) ...[
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, size: 14, color: LNUColors.black),
                  const SizedBox(width: 6),
                  Expanded(child: Text(_request!['rejection_reason'], style: const TextStyle(color: LNUColors.black, fontSize: 13))),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStudentCard() {
    final s = _request!['students'];
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Student Information', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            _row('Full Name', s?['full_name'] ?? '—'),
            _row('Student ID', s?['student_id'] ?? '—'),
            _row('Email', s?['email'] ?? '—'),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestCard() {
    final dt = _request!['document_types'];
    final assessedFee = _request!['assessed_fee'];
    final paymentNote = _request!['payment_note'];
    final paymentRef = _request!['payment_reference'] as String?;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Request Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            _row('Document Type', dt?['name'] ?? '—'),
            _row('Copies', '${_request!['copies'] ?? 1}'),
            _row('Base Fee', AppHelpers.formatCurrency(_request!['base_fee'])),
            if (assessedFee != null)
              _row('Assessed Fee', AppHelpers.formatCurrency(assessedFee), highlight: true),
            if (paymentRef != null)
              _row('Reference Code', paymentRef, highlight: true),
            if (paymentNote != null && paymentNote.toString().isNotEmpty)
              _row('Payment Note', paymentNote),
            if (_request!['purpose'] != null)
              _row('Purpose', _request!['purpose']),
            _row('Submitted', AppHelpers.formatDate(_request!['created_at'])),
            if (_request!['reviewed_at'] != null)
              _row('Reviewed At', AppHelpers.formatDate(_request!['reviewed_at'])),
            if (_request!['payment_verified_at'] != null)
              _row('Payment Verified', AppHelpers.formatDate(_request!['payment_verified_at'])),
          ],
        ),
      ),
    );
  }

  Widget _buildRequirementFiles() {
    final urls = _request!['requirement_urls'] as List?;
    if (urls == null || urls.isEmpty) {
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.attach_file, color: LNUColors.textMuted),
              SizedBox(width: 8),
              Text('No requirement files uploaded', style: TextStyle(color: LNUColors.textMuted)),
            ],
          ),
        ),
      );
    }
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Uploaded Requirements (${urls.length})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            ...urls.asMap().entries.map((e) => _buildFileRow(e.key + 1, e.value.toString())),
          ],
        ),
      ),
    );
  }

  Widget _buildFileRow(int index, String url) {
    final isImage = url.contains('.jpg') || url.contains('.jpeg') || url.contains('.png') || url.contains('.webp');
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: LNUColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: LNUColors.primary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(isImage ? Icons.image_outlined : Icons.picture_as_pdf_outlined, color: LNUColors.primary, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text('Requirement $index', style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13))),
          if (isImage)
            TextButton.icon(
              onPressed: () => _viewImage(url),
              icon: const Icon(Icons.visibility_outlined, size: 16),
              label: const Text('View', style: TextStyle(fontSize: 12)),
              style: TextButton.styleFrom(foregroundColor: LNUColors.primary, padding: EdgeInsets.zero),
            )
          else
            TextButton.icon(
              onPressed: () => launchUrl(Uri.parse(url)),
              icon: const Icon(Icons.open_in_new, size: 16),
              label: const Text('Open', style: TextStyle(fontSize: 12)),
              style: TextButton.styleFrom(foregroundColor: LNUColors.primary, padding: EdgeInsets.zero),
            ),
        ],
      ),
    );
  }

  void _viewImage(String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(8),
        child: Stack(
          children: [
            InteractiveViewer(child: Image.network(url, fit: BoxFit.contain)),
            Positioned(
              top: 8, right: 8,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    final status = _request!['status'] as String? ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (status == 'SUBMITTED') ...[
          _actionBtn('Mark as Under Review', Icons.find_in_page_outlined, LNUColors.statusUnderReview, _showMarkUnderReview),
          const SizedBox(height: 8),
        ],
        if (status == 'SUBMITTED' || status == 'UNDER_REVIEW') ...[
          _actionBtn('Approve & Assign Fee', Icons.check_circle_outline, LNUColors.statusForPayment, _showApproveDialog),
          const SizedBox(height: 8),
          _actionBtn('Mark Requirements Incomplete', Icons.warning_amber_outlined, LNUColors.statusIncomplete, _showIncompleteDialog),
          const SizedBox(height: 8),
          _actionBtn('Reject Request', Icons.cancel_outlined, LNUColors.statusRejected, _showRejectDialog),
        ],
        if (status == 'FOR_PAYMENT') ...[
          _actionBtn('Verify Payment Received', Icons.verified_outlined, LNUColors.statusVerified, _showVerifyPaymentDialog),
          const SizedBox(height: 8),
        ],
        if (status == 'PROCESSING' || status == 'PAYMENT_VERIFIED') ...[
          _actionBtn('Schedule Claim Date', Icons.event_available_outlined, LNUColors.statusForClaiming, _showScheduleClaimDialog),
          const SizedBox(height: 8),
        ],
        if (status == 'FOR_CLAIMING') ...[
          _actionBtn('Mark as Completed (Document Claimed)', Icons.task_alt, LNUColors.statusCompleted, _showMarkCompletedDialog),
        ],
      ],
    );
  }

  Widget _actionBtn(String label, IconData icon, Color color, VoidCallback onTap) {
    return ElevatedButton.icon(
      onPressed: _acting ? null : onTap,
      icon: _acting ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _row(String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 130, child: Text(label, style: const TextStyle(color: LNUColors.textMuted, fontSize: 13))),
          Expanded(child: Text(value, style: TextStyle(
            fontWeight: highlight ? FontWeight.bold : FontWeight.w500,
            fontSize: 13,
            color: highlight ? LNUColors.primary : null,
          ))),
        ],
      ),
    );
  }
}
