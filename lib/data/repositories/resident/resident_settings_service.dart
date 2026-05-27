import 'package:mycondo/data/repositories/auth/profile_identity_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ResidentSettingsService {
  ResidentSettingsService({SupabaseClient? supabase})
    : _supabase = supabase ?? Supabase.instance.client;

  final SupabaseClient _supabase;
  final ProfileIdentityService _identity = ProfileIdentityService();

  Future<ResidentSettingsBundle> fetchSettings() async {
    final residentId = await _requireResidentId();

    final rows = await _supabase
        .from('resident_preferences')
        .select()
        .eq('resident_id', residentId)
        .maybeSingle();

    final methodRows = await _supabase
        .from('resident_payment_methods')
        .select()
        .eq('resident_id', residentId)
        .order('is_default', ascending: false);

    return ResidentSettingsBundle(
      notifications: ResidentNotificationPreferences.fromMap(residentId, rows),
      messaging: ResidentMessagingPreferences.fromMap(residentId, rows),
      paymentMethods: (methodRows as List<dynamic>)
          .map((e) => ResidentPaymentMethod.fromMap(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<void> saveNotifications(
    ResidentNotificationPreferences settings,
  ) async {
    await _upsertPreferences({
      'payment_reminders': settings.paymentReminders,
      'announcement_alerts': settings.announcementAlerts,
      'maintenance_updates': settings.maintenanceUpdates,
      'message_alerts': settings.messageAlerts,
    });
  }

  Future<void> saveMessaging(ResidentMessagingPreferences settings) async {
    await _upsertPreferences({
      'allow_manager_messages': settings.allowManagerMessages,
      'quiet_hours_enabled': settings.quietHoursEnabled,
      'quiet_hours_start': settings.quietHoursStart,
      'quiet_hours_end': settings.quietHoursEnd,
      'preferred_contact': settings.preferredContact,
    });
  }

  Future<void> savePaymentMethods(List<ResidentPaymentMethod> methods) async {
    final residentId = await _requireResidentId();

    // Delete then re-insert for simplicity (small list, low frequency)
    await _supabase
        .from('resident_payment_methods')
        .delete()
        .eq('resident_id', residentId);

    if (methods.isEmpty) return;

    await _supabase.from('resident_payment_methods').insert(
          methods
              .map(
                (m) => {
                  'resident_id': residentId,
                  'label': m.label,
                  'account_name': m.accountName,
                  'account_number': m.accountNumber,
                  'instructions': m.instructions,
                  'is_default': m.isDefault,
                },
              )
              .toList(),
        );
  }

  Future<void> _upsertPreferences(Map<String, dynamic> values) async {
    final residentId = await _requireResidentId();
    await _supabase.from('resident_preferences').upsert({
      'resident_id': residentId,
      ...values,
    });
  }

  Future<String> _requireResidentId() async {
    final profile = await _identity.requireCurrentProfile(
      missingMessage: 'No resident profile is linked to this signed-in user.',
    );

    final resident = await _supabase
        .from('residents')
        .select('id')
        .eq('id', profile.id)
        .single();

    return resident['id'].toString();
  }

}

class ResidentSettingsBundle {
  const ResidentSettingsBundle({
    required this.notifications,
    required this.messaging,
    required this.paymentMethods,
  });

  final ResidentNotificationPreferences notifications;
  final ResidentMessagingPreferences messaging;
  final List<ResidentPaymentMethod> paymentMethods;
}

class ResidentNotificationPreferences {
  const ResidentNotificationPreferences({
    required this.residentId,
    required this.paymentReminders,
    required this.announcementAlerts,
    required this.maintenanceUpdates,
    required this.messageAlerts,
  });

  final String residentId;
  final bool paymentReminders;
  final bool announcementAlerts;
  final bool maintenanceUpdates;
  final bool messageAlerts;

  factory ResidentNotificationPreferences.fromMap(
    String residentId,
    Map<String, dynamic>? map,
  ) {
    return ResidentNotificationPreferences(
      residentId: residentId,
      paymentReminders: map?['payment_reminders'] as bool? ?? true,
      announcementAlerts: map?['announcement_alerts'] as bool? ?? true,
      maintenanceUpdates: map?['maintenance_updates'] as bool? ?? true,
      messageAlerts: map?['message_alerts'] as bool? ?? true,
    );
  }

  ResidentNotificationPreferences copyWith({
    bool? paymentReminders,
    bool? announcementAlerts,
    bool? maintenanceUpdates,
    bool? messageAlerts,
  }) {
    return ResidentNotificationPreferences(
      residentId: residentId,
      paymentReminders: paymentReminders ?? this.paymentReminders,
      announcementAlerts: announcementAlerts ?? this.announcementAlerts,
      maintenanceUpdates: maintenanceUpdates ?? this.maintenanceUpdates,
      messageAlerts: messageAlerts ?? this.messageAlerts,
    );
  }
}

class ResidentMessagingPreferences {
  const ResidentMessagingPreferences({
    required this.residentId,
    required this.allowManagerMessages,
    required this.quietHoursEnabled,
    required this.quietHoursStart,
    required this.quietHoursEnd,
    required this.preferredContact,
  });

  final String residentId;
  final bool allowManagerMessages;
  final bool quietHoursEnabled;
  final String quietHoursStart;
  final String quietHoursEnd;
  final String preferredContact;

  factory ResidentMessagingPreferences.fromMap(
    String residentId,
    Map<String, dynamic>? map,
  ) {
    return ResidentMessagingPreferences(
      residentId: residentId,
      allowManagerMessages: map?['allow_manager_messages'] as bool? ?? true,
      quietHoursEnabled: map?['quiet_hours_enabled'] as bool? ?? false,
      quietHoursStart: map?['quiet_hours_start']?.toString() ?? '22:00',
      quietHoursEnd: map?['quiet_hours_end']?.toString() ?? '07:00',
      preferredContact: map?['preferred_contact']?.toString() ?? 'in_app',
    );
  }

  ResidentMessagingPreferences copyWith({
    bool? allowManagerMessages,
    bool? quietHoursEnabled,
    String? quietHoursStart,
    String? quietHoursEnd,
    String? preferredContact,
  }) {
    return ResidentMessagingPreferences(
      residentId: residentId,
      allowManagerMessages: allowManagerMessages ?? this.allowManagerMessages,
      quietHoursEnabled: quietHoursEnabled ?? this.quietHoursEnabled,
      quietHoursStart: quietHoursStart ?? this.quietHoursStart,
      quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
      preferredContact: preferredContact ?? this.preferredContact,
    );
  }
}

class ResidentPaymentMethod {
  const ResidentPaymentMethod({
    this.id,
    required this.label,
    required this.accountName,
    required this.accountNumber,
    required this.instructions,
    required this.isDefault,
  });

  final int? id;
  final String label;
  final String accountName;
  final String accountNumber;
  final String instructions;
  final bool isDefault;

  factory ResidentPaymentMethod.fromMap(Map<String, dynamic> map) {
    return ResidentPaymentMethod(
      id: (map['id'] as num?)?.toInt(),
      label: map['label']?.toString() ?? '',
      accountName: map['account_name']?.toString() ?? '',
      accountNumber: map['account_number']?.toString() ?? '',
      instructions: map['instructions']?.toString() ?? '',
      isDefault: map['is_default'] as bool? ?? false,
    );
  }

  ResidentPaymentMethod copyWith({
    int? id,
    String? label,
    String? accountName,
    String? accountNumber,
    String? instructions,
    bool? isDefault,
  }) {
    return ResidentPaymentMethod(
      id: id ?? this.id,
      label: label ?? this.label,
      accountName: accountName ?? this.accountName,
      accountNumber: accountNumber ?? this.accountNumber,
      instructions: instructions ?? this.instructions,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}
