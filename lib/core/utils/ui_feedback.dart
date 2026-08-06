import 'package:flutter/material.dart';

/// Placeholder affordance for entry points that are laid out but not built
/// yet. Keeping them tappable-but-honest is better than dead buttons: the
/// navigation shape of the app stays visible while the screens land.
void showComingSoonSnackBar(BuildContext context, String feature) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text('$feature đang được phát triển')));
}
