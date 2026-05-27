import 'package:flutter_test/flutter_test.dart';
import 'package:mycondo/services/shared/session_preference_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SessionPreferenceService service;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    service = SessionPreferenceService();
    service.clearEphemeralSessionMarker();
  });

  test('unchecked keep signed in allows current launch only', () async {
    await service.applyLoginChoice(keepSignedIn: false);

    expect(await service.isKeepSignedInEnabled(), isFalse);
    expect(await service.shouldRetainSessionOnAppLaunch(), isTrue);

    service.clearEphemeralSessionMarker();
    expect(await service.shouldRetainSessionOnAppLaunch(), isFalse);
  });

  test('checked keep signed in persists across launch checks', () async {
    await service.applyLoginChoice(keepSignedIn: true);

    expect(await service.isKeepSignedInEnabled(), isTrue);
    expect(await service.shouldRetainSessionOnAppLaunch(), isTrue);

    service.clearEphemeralSessionMarker();
    expect(await service.shouldRetainSessionOnAppLaunch(), isTrue);
  });

  test('clear remembered session resets preference and marker', () async {
    await service.applyLoginChoice(keepSignedIn: true);
    await service.retainSessionForOnboarding();

    await service.clearRememberedSession();

    expect(await service.isKeepSignedInEnabled(), isFalse);
    expect(await service.shouldRetainForOnboarding(), isFalse);
    expect(await service.shouldRetainSessionOnAppLaunch(), isFalse);
  });

  test('onboarding retention keeps session across launches', () async {
    await service.retainSessionForOnboarding();

    service.clearEphemeralSessionMarker();
    expect(await service.shouldRetainSessionOnAppLaunch(), isTrue);

    await service.clearOnboardingRetention();
    expect(await service.shouldRetainSessionOnAppLaunch(), isFalse);
  });
}
