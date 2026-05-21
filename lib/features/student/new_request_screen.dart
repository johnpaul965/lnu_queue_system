// lib/features/student/new_request_screen.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/supabase_service.dart';
import '../../shared/widgets/lnu_button.dart';
import '../../shared/widgets/lnu_text_field.dart';
import '../../core/utils/helpers.dart';
import '../../core/utils/validators.dart';
import '../../../main.dart' show preloadedStudent;

class NewRequestScreen extends StatefulWidget {
  const NewRequestScreen({super.key});

  @override
  State<NewRequestScreen> createState() => _NewRequestScreenState();
}

class _NewRequestScreenState extends State<NewRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _purposeCtrl = TextEditingController();
  final _copiesCtrl = TextEditingController(text: '1');
  List<Map<String, dynamic>> _docTypes = [];
  String? _selectedDocTypeId;
  String? _selectedDocTypeName;
  List<String>? _selectedRequirements;

  final List<_UploadedFile> _uploadedFiles = [];
  bool _loading = false;
  bool _loadingTypes = false;
  Map<String, dynamic>? _student;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final preloaded = preloadedStudent;
    if (preloaded != null) _student = preloaded;
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final preloaded = preloadedStudent;
        final student = preloaded ?? await SupabaseService.getStudentByAuthId(user.id);
        final types = await SupabaseService.client
            .from('document_types')
            .select()
            .eq('is_active', true)
            .order('name');
        if (mounted) {
          setState(() {
            _student = student;
            _docTypes = List<Map<String, dynamic>>.from(types);
            _loadingTypes = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _loadingTypes = false);
    }
  }

  Future<void> _pickFile() async {
    try {
      final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      setState(() {
        _uploadedFiles.add(_UploadedFile(
          name: picked.name,
          bytes: bytes,
          isUploading: false,
        ));
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick file: $e'), backgroundColor: LNUColors.yellow),
      );
    }
  }

  void _removeFile(int index) {
    setState(() => _uploadedFiles.removeAt(index));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDocTypeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a document type'), backgroundColor: LNUColors.yellow),
      );
      return;
    }
    if (_uploadedFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload at least one requirement file'),
          backgroundColor: LNUColors.yellow,
        ),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final tempId = DateTime.now().millisecondsSinceEpoch.toString();
      final List<String> uploadedUrls = [];
      for (final file in _uploadedFiles) {
        setState(() => file.isUploading = true);
        final url = await SupabaseService.uploadRequirementFile(
          requestId: tempId,
          fileBytes: file.bytes,
          fileName: file.name,
        );
        uploadedUrls.add(url);
        setState(() => file.isUploading = false);
      }

      await SupabaseService.submitRequest(
        studentId: _student!['id'],
        documentTypeId: _selectedDocTypeId!,
        copies: int.parse(_copiesCtrl.text),
        purpose: _purposeCtrl.text.trim().isEmpty ? null : _purposeCtrl.text.trim(),
        requirementUrls: uploadedUrls,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Request submitted successfully! The registrar will review your requirements.'),
          backgroundColor: LNUColors.darkBlue,
          duration: Duration(seconds: 4),
        ),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: LNUColors.yellow),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _purposeCtrl.dispose();
    _copiesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LNUColors.background,
      appBar: AppBar(
        title: const Text('New Document Request'),
        backgroundColor: LNUColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _loadingTypes
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                      _buildStepLabel('Step 1', 'Select Document Type'),
                      const SizedBox(height: 10),
                      _buildDocumentTypeDropdown(),
                      if (_selectedDocTypeId != null) ...[
                        const SizedBox(height: 12),
                        _buildFeeDisplay(),
                      ],
                      const SizedBox(height: 20),
                      _buildStepLabel('Step 2', 'Enter Details'),
                      const SizedBox(height: 10),
                      LNUTextField(
                        label: 'Number of Copies',
                        controller: _copiesCtrl,
                        keyboardType: TextInputType.number,
                        prefixIcon: const Icon(Icons.content_copy_outlined),
                        validator: (v) {
                          final n = int.tryParse(v ?? '');
                          if (n == null || n < 1) return 'Enter at least 1 copy';
                          if (n > 20) return 'Maximum 20 copies';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      LNUTextField(
                        label: 'Purpose (optional)',
                        controller: _purposeCtrl,
                        maxLines: 3,
                        prefixIcon: const Icon(Icons.notes_outlined),
                        validator: LNUValidators.purpose,
                      ),
                      const SizedBox(height: 20),
                      _buildStepLabel('Step 3', 'Upload Requirements'),
                      const SizedBox(height: 4),
                      Text(
                        'Upload digital copies (images or PDFs) of all required documents.',
                        style: const TextStyle(fontSize: 12, color: LNUColors.textMuted),
                      ),
                      const SizedBox(height: 10),
                      if (_selectedRequirements != null) _buildRequirementsList(),
                      const SizedBox(height: 12),
                      _buildUploadSection(),
                      const SizedBox(height: 28),
                      LNUButton(label: _loading ? 'Submitting...' : 'Submit Request', onPressed: _loading ? null : _submit, isLoading: _loading),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
    );
  }

  Widget _buildStepLabel(String step, String label) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: LNUColors.primary,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(step, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      ],
    );
  }

  Widget _buildDocumentTypeDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedDocTypeId,
      decoration: InputDecoration(
        labelText: 'Document Type',
        prefixIcon: const Icon(Icons.description_outlined),
        filled: true,
        fillColor: LNUColors.background,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: LNUColors.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: LNUColors.border)),
      ),
      hint: const Text('Select document type'),
      items: _docTypes.map((dt) => DropdownMenuItem<String>(
        value: dt['id'].toString(),
        child: Text(dt['name'] ?? ''),
      )).toList(),
      onChanged: (v) {
        final selected = _docTypes.firstWhere((dt) => dt['id'].toString() == v, orElse: () => {});
        setState(() {
          _selectedDocTypeId = v;
          _selectedDocTypeName = selected['name'];
          final reqs = selected['requirements'];
          _selectedRequirements = reqs is List ? List<String>.from(reqs) : null;
          _uploadedFiles.clear();
        });
      },
      validator: (v) => v == null ? 'Please select a document type' : null,
    );
  }

  Widget _buildFeeDisplay() {
    final selected = _docTypes.firstWhere((dt) => dt['id'].toString() == _selectedDocTypeId, orElse: () => {});
    final fee = selected['base_fee'];
    final copies = int.tryParse(_copiesCtrl.text) ?? 1;
    final total = (fee ?? 0) * copies;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: LNUColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: LNUColors.primary.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Base Fee per copy', style: TextStyle(color: LNUColors.textMuted, fontSize: 12)),
              Text(AppHelpers.formatCurrency(fee), style: const TextStyle(fontWeight: FontWeight.bold, color: LNUColors.primary)),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('Estimated Total', style: TextStyle(color: LNUColors.textMuted, fontSize: 12)),
              Text(AppHelpers.formatCurrency(total), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: LNUColors.primary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRequirementsList() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: LNUColors.lightBlue.withOpacity(0.25),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: LNUColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.checklist_rounded, color: LNUColors.darkBlue, size: 18),
              const SizedBox(width: 6),
              Text(
                'Required Documents for ${_selectedDocTypeName ?? ''}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: LNUColors.darkBlue),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ..._selectedRequirements!.asMap().entries.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 20, height: 20,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(color: LNUColors.lightBlue, shape: BoxShape.circle),
                  child: Text('${e.key + 1}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: LNUColors.darkBlue)),
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(e.value, style: const TextStyle(fontSize: 13))),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildUploadSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: LNUColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: LNUColors.border),
        boxShadow: [BoxShadow(color: LNUColors.black.withOpacity(0.04), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Uploaded Files', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              Text('${_uploadedFiles.length} file(s)', style: const TextStyle(color: LNUColors.textMuted, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 10),
          if (_uploadedFiles.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: LNUColors.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: LNUColors.border),
              ),
              child: Column(
                children: [
                  Icon(Icons.cloud_upload_outlined, size: 40, color: LNUColors.lightBlue),
                  const SizedBox(height: 6),
                  const Text('No files uploaded yet', style: TextStyle(color: LNUColors.textMuted, fontSize: 13)),
                ],
              ),
            )
          else
            ..._uploadedFiles.asMap().entries.map((e) => _buildFileChip(e.key, e.value)),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _loading ? null : _pickFile,
              icon: const Icon(Icons.add_photo_alternate_outlined),
              label: const Text('Add Requirement File'),
              style: OutlinedButton.styleFrom(
                foregroundColor: LNUColors.primary,
                side: const BorderSide(color: LNUColors.primary),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileChip(int index, _UploadedFile file) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: LNUColors.primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: LNUColors.primary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(
            file.name.toLowerCase().endsWith('.pdf') ? Icons.picture_as_pdf : Icons.image_outlined,
            color: LNUColors.primary,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              file.name,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (file.isUploading)
            const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
          else
            IconButton(
              icon: const Icon(Icons.close, size: 18, color: LNUColors.textMuted),
              onPressed: () => _removeFile(index),
              constraints: const BoxConstraints(),
              padding: EdgeInsets.zero,
            ),
        ],
      ),
    );
  }
}

class _UploadedFile {
  final String name;
  final Uint8List bytes;
  bool isUploading;
  _UploadedFile({required this.name, required this.bytes, required this.isUploading});
}
