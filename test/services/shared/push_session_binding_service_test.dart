import 'package:flutter_test/flutter_test.dart';
import 'package:mycondo/services/shared/push_session_binding_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PushSessionBindingService service;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    service = PushSessionBindingService();
  });

  test('stores and reads persistent push-session binding', () async {
    await service.bindPersistentSession(profileId: 'profile-123');

    final binding = await service.getBinding();

    expect(binding, isNotNull);
    expect(binding!.profileId, 'profile-123');
    expect(binding.isPersistent, isTrue);
    expect(binding.boundAt, isNotNull);
  });

  test('clearBinding removes stored push-session binding', () async {
    await service.bindPersistentSession(profileId: 'profile-123');

    await service.clearBinding();

    expect(await service.getBinding(), isNull);
  });
}
