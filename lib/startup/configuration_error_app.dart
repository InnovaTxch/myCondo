import 'package:flutter/material.dart';

class ConfigurationErrorApp extends StatelessWidget {
  const ConfigurationErrorApp({super.key, required this.missingValues});

  final List<String> missingValues;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'myCondo Configuration Error',
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'myCondo is missing required configuration:\n\n'
                  '${missingValues.join('\n')}\n\n'
                  'Start the app with --dart-define-from-file=.env.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
