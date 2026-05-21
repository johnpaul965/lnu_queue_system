// lib/core/services/supabase_service.dart
import 'dart:math';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static SupabaseClient get client => Supabase.instance.client;

  // ── AUTH ──────────────────────────────────────────────────
  static Future<void> createRegistrar({
    required String email,
    required String password,
    required String fullName,
  }) async {
    final res = await client.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName, 'role': 'staff'},
    );
    if (res.user != null) {
      try {
        await client.from('admins').insert({
          'auth_id': res.user!.id,
          'full_name': fullName,
          'email': email,
        });
      } catch (e) {
        rethrow;
      }
    } else {
      throw Exception('Failed to create registrar account. Email may already be in use.');
    }
  }

  static Future<AuthResponse> registerStudent({
    required String email,
    required String password,
    required String fullName,
    required String studentId,
  }) async {
    final res = await client.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName, 'student_id': studentId, 'role': 'student'},
    );
    if (res.user != null) {
      try {
        await client.from('students').insert({
          'auth_id': res.user!.id,
          'full_name': fullName,
          'student_id': studentId,
          'email': email,
        });
      } catch (e) {
        await client.auth.signOut();
        rethrow;
      }
    }
    return res;
  }

  static Future<AuthResponse> login(String email, String password) =>
      client.auth.signInWithPassword(email: email, password: password);

  static Future<void> logout() => client.auth.signOut();

  // ── STUDENT ───────────────────────────────────────────────
  static Future<Map<String, dynamic>> getStudentByAuthId(String authId) async {
    return await client.from('students').select().eq('auth_id', authId).single();
  }

  // ── REQUIREMENT FILE UPLOAD ───────────────────────────────
  static Future<String> uploadRequirementFile({
    required String requestId,
    required Uint8List fileBytes,
    required String fileName,
  }) async {
    final ext = fileName.split('.').last.toLowerCase();
    final contentType = ext == 'pdf' ? 'application/pdf' : 'image/$ext';
    final path = 'requirements/$requestId/${DateTime.now().millisecondsSinceEpoch}_$fileName';
    await client.storage.from('requirements').uploadBinary(
      path,
      fileBytes,
      fileOptions: FileOptions(contentType: contentType, upsert: true),
    );
    return client.storage.from('requirements').getPublicUrl(path);
  }

  // ── REQUESTS ──────────────────────────────────────────────

  /// Step 3 — Student submits request with uploaded requirement files
  static Future<Map<String, dynamic>> submitRequest({
    required String studentId,
    required String documentTypeId,
    required int copies,
    String? purpose,
    List<String> requirementUrls = const [],
  }) async {
    final docType = await client
        .from('document_types')
        .select('base_fee')
        .eq('id', documentTypeId)
        .single();

    final res = await client.from('requests').insert({
      'student_id': studentId,
      'document_type_id': documentTypeId,
      'copies': copies,
      'purpose': purpose,
      'base_fee': docType['base_fee'],
      'status': 'SUBMITTED',
      'requirement_urls': requirementUrls,
    }).select().single();
    return res;
  }

  // ── REGISTRAR ACTIONS ─────────────────────────────────────

  /// Step 4a — Registrar marks request as under review
  static Future<void> markUnderReview(String requestId) async {
    final currentUser = client.auth.currentUser;
    await client.from('requests').update({
      'status': 'UNDER_REVIEW',
      'reviewed_by': currentUser?.id,
      'reviewed_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', requestId);
  }

  /// Step 4b — Registrar marks requirements as incomplete
  static Future<void> markIncomplete({
    required String requestId,
    required String reason,
  }) async {
    final req = await client.from('requests').select('student_id').eq('id', requestId).single();
    await client.from('requests').update({
      'status': 'INCOMPLETE',
      'rejection_reason': reason,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', requestId);
    await _sendNotification(
      studentId: req['student_id'],
      requestId: requestId,
      title: 'Incomplete Requirements',
      body: 'Your request has incomplete requirements: $reason. Please resubmit.',
      type: 'incomplete',
    );
  }

  /// Step 4c — Registrar rejects request
  static Future<void> rejectRequest({
    required String requestId,
    required String reason,
  }) async {
    final req = await client.from('requests').select('student_id').eq('id', requestId).single();
    await client.from('requests').update({
      'status': 'REJECTED',
      'rejection_reason': reason,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', requestId);
    await _sendNotification(
      studentId: req['student_id'],
      requestId: requestId,
      title: 'Request Rejected',
      body: 'Your request was rejected: $reason.',
      type: 'rejected',
    );
  }

  /// Generates a unique cashier reference code like LNU-2025-A3KX9Z
  static String _generateRefCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rand = Random();
    final year = DateTime.now().year;
    final code = List.generate(6, (_) => chars[rand.nextInt(chars.length)]).join();
    return 'LNU-$year-$code';
  }

  /// Step 4d — Registrar approves and assigns payment fee
  static Future<void> approveRequest({
    required String requestId,
    required double assessedFee,
    String? paymentNote,
  }) async {
    final req = await client.from('requests').select('student_id').eq('id', requestId).single();
    final refCode = _generateRefCode();
    await client.from('requests').update({
      'status': 'FOR_PAYMENT',
      'assessed_fee': assessedFee,
      'payment_note': paymentNote,
      'payment_reference': refCode,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', requestId);
    await _sendNotification(
      studentId: req['student_id'],
      requestId: requestId,
      title: 'Requirements Approved — Pay at Cashier',
      body: 'Your reference code is $refCode. Please pay ₱${assessedFee.toStringAsFixed(2)} at the cashier and show this code.',
      type: 'approved',
    );
  }

  /// Step 5 — Registrar verifies payment after student pays at cashier
  static Future<void> verifyPayment(String requestId) async {
    final currentUser = client.auth.currentUser;
    final req = await client.from('requests').select('student_id').eq('id', requestId).single();
    await client.from('requests').update({
      'status': 'PROCESSING',
      'payment_verified_at': DateTime.now().toIso8601String(),
      'payment_verified_by': currentUser?.id,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', requestId);
    await _sendNotification(
      studentId: req['student_id'],
      requestId: requestId,
      title: 'Document Processing',
      body: 'Your payment has been verified. Your document is now being processed.',
      type: 'processing',
    );
  }

  /// Step 6 — Registrar schedules the claim date
  static Future<void> setClaimDate({
    required String requestId,
    required DateTime claimDate,
  }) async {
    final req = await client.from('requests').select('student_id').eq('id', requestId).single();
    await client.from('requests').update({
      'status': 'FOR_CLAIMING',
      'claim_date': claimDate.toIso8601String(),
      'claim_scheduled_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', requestId);
    final dateStr = '${claimDate.month}/${claimDate.day}/${claimDate.year}';
    await _sendNotification(
      studentId: req['student_id'],
      requestId: requestId,
      title: 'Ready for Pickup',
      body: 'Your document is ready for claiming on $dateStr. Please bring your valid school ID.',
      type: 'claim',
    );
  }

  /// Step 7 — Registrar marks document as claimed/completed
  static Future<void> markAsCompleted(String requestId) async {
    final req = await client.from('requests').select('student_id').eq('id', requestId).single();
    await client.from('requests').update({
      'status': 'COMPLETED',
      'completed_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', requestId);
    await _sendNotification(
      studentId: req['student_id'],
      requestId: requestId,
      title: 'Document Claimed',
      body: 'Your document request has been completed. Thank you!',
      type: 'completed',
    );
  }

  // ── NOTIFICATIONS ─────────────────────────────────────────
  static Future<void> _sendNotification({
    required String studentId,
    required String requestId,
    required String title,
    required String body,
    required String type,
  }) async {
    await client.from('notifications').insert({
      'student_id': studentId,
      'request_id': requestId,
      'title': title,
      'body': body,
      'type': type,
    });
  }

  static Future<List<Map<String, dynamic>>> getStudentNotifications(String studentId) async {
    final data = await client
        .from('notifications')
        .select()
        .eq('student_id', studentId)
        .order('created_at', ascending: false)
        .limit(20);
    return List<Map<String, dynamic>>.from(data);
  }

  static Future<void> markNotificationRead(String notificationId) async {
    await client.from('notifications').update({'is_read': true}).eq('id', notificationId);
  }

  // ── RESUBMIT (after INCOMPLETE) ──────────────────────────
  /// Student resubmits corrected requirements after being marked INCOMPLETE
  static Future<void> resubmitRequest({
    required String requestId,
    required List<String> newRequirementUrls,
  }) async {
    await client.from('requests').update({
      'status': 'SUBMITTED',
      'requirement_urls': newRequirementUrls,
      'rejection_reason': null,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', requestId);
  }

  // ── REALTIME ──────────────────────────────────────────────
  static RealtimeChannel subscribeToMyRequests(
    String studentId,
    Function(dynamic) onUpdate,
  ) {
    return client
        .channel('student_requests_$studentId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'requests',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'student_id',
            value: studentId,
          ),
          callback: (payload) => onUpdate(payload),
        )
        .subscribe();
  }

  static RealtimeChannel subscribeToAllRequests(Function() onUpdate) {
    return client
        .channel('admin_all_requests')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'requests',
          callback: (_) => onUpdate(),
        )
        .subscribe();
  }
}
