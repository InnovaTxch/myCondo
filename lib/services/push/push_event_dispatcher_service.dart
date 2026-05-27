import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PushEventDispatcherService {
  PushEventDispatcherService({SupabaseClient? supabase})
    : _supabase = supabase ?? Supabase.instance.client;

  final SupabaseClient _supabase;

  Future<void> dispatchPaymentSubmitted({
    required int paymentId,
    required String residentId,
  }) {
    return _dispatch(
      eventType: 'payment_submitted',
      payload: {'payment_id': paymentId, 'resident_id': residentId},
    );
  }

  Future<void> dispatchPaymentDecision({
    required int paymentId,
    required String residentId,
    required String decision,
  }) {
    return _dispatch(
      eventType: 'payment_decision',
      payload: {
        'payment_id': paymentId,
        'resident_id': residentId,
        'decision': decision,
      },
    );
  }

  Future<void> dispatchMaintenanceSubmitted({
    required int requestId,
    required int condoId,
    required String residentId,
  }) {
    return _dispatch(
      eventType: 'maintenance_submitted',
      payload: {
        'request_id': requestId,
        'condo_id': condoId,
        'resident_id': residentId,
      },
    );
  }

  Future<void> dispatchMaintenanceUpdated({
    required int requestId,
    required String residentId,
    required String status,
  }) {
    return _dispatch(
      eventType: 'maintenance_updated',
      payload: {
        'request_id': requestId,
        'resident_id': residentId,
        'status': status,
      },
    );
  }

  Future<void> dispatchAnnouncementPublished({
    required int announcementId,
    required int condoId,
  }) {
    return _dispatch(
      eventType: 'announcement_published',
      payload: {'announcement_id': announcementId, 'condo_id': condoId},
    );
  }

  Future<void> dispatchMessageSent({
    required int conversationId,
    required String senderId,
  }) {
    return _dispatch(
      eventType: 'message_sent',
      payload: {'conversation_id': conversationId, 'sender_id': senderId},
    );
  }

  Future<void> _dispatch({
    required String eventType,
    required Map<String, dynamic> payload,
  }) async {
    try {
      await _supabase.functions.invoke(
        'send-push-event',
        body: {'event_type': eventType, 'payload': payload},
      );
    } catch (error) {
      debugPrint('Push dispatch failed for $eventType: $error');
    }
  }
}
