import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:mycondo/features/shared/widgets/app_about_sheet.dart';
import 'package:mycondo/theme/app_theme.dart';

void main() {
  setUp(() {
    PackageInfo.setMockInitialValues(
      appName: 'myCondo',
      packageName: 'com.example.mycondo',
      version: '1.2.3',
      buildNumber: '45',
      buildSignature: '',
    );
  });

  testWidgets('app about sheet shows release metadata and support notes', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(body: AppAboutSheet()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('myCondo'), findsWidgets);
    expect(find.text('Version'), findsOneWidget);
    expect(find.text('1.2.3'), findsOneWidget);
    expect(find.text('Build Number'), findsOneWidget);
    expect(find.text('45'), findsOneWidget);
    expect(find.text('com.example.mycondo'), findsOneWidget);
    expect(find.text('InnovaTxch'), findsOneWidget);
    expect(find.text('Support Notes'), findsOneWidget);
  });
}
