import 'package:flutter/material.dart';

/// Shown while [AuthController.build] resolves the current session. The
/// router's `redirect` callback moves off this page as soon as that future
/// completes — this widget never navigates itself.
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
