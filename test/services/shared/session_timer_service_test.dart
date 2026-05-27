import 'package:flutter_test/flutter_test.dart';
import 'package:mycondo/services/shared/session_timer_service.dart';
import 'package:mycondo/services/shared/session_preference_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SessionTimerService timerService;
  late SessionPreferenceService preferenceService;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    timerService = SessionTimerService();
    timerService.stopTimer();
    preferenceService = SessionPreferenceService();
    preferenceService.clearEphemeralSessionMarker();
  });

  tearDown(() {
    timerService.stopTimer();
  });

  test(
    'does not run inactivity timer when keep signed in is enabled',
    () async {
      await preferenceService.applyLoginChoice(keepSignedIn: true);

      timerService.startTimer('manager');
      await Future<void>.delayed(Duration.zero);

      expect(timerService.isTimerActive, isFalse);
    },
  );

  test('runs inactivity timer when keep signed in is disabled', () async {
    await preferenceService.applyLoginChoice(keepSignedIn: false);

    timerService.startTimer('resident');
    await Future<void>.delayed(Duration.zero);

    expect(timerService.isTimerActive, isTrue);
  });

  test('keeps role timeout durations unchanged', () {
    expect(
      timerService.timeoutDurationForRole('manager'),
      const Duration(minutes: 10),
    );
    expect(
      timerService.timeoutDurationForRole('resident'),
      const Duration(minutes: 15),
    );
  });
}
