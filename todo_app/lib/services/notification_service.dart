import 'package:flutter/material.dart';

import 'platform_notifier.dart';
import 'platform_notifier_stub.dart'
    if (dart.library.html) 'platform_notifier_web.dart';

class NotificationService {
  NotificationService(this.scaffoldMessengerKey)
      : _platform = PlatformNotifierImpl();

  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey;
  final PlatformNotifier _platform;

  Future<bool> requestPermission() => _platform.requestPermission();

  void notify(String title, String body) {
    _platform.show(title, body);
    final messenger = scaffoldMessengerKey.currentState;
    messenger?.hideCurrentSnackBar();
    messenger?.showSnackBar(
      SnackBar(
        content: Text('$title — $body'),
        duration: const Duration(seconds: 6),
      ),
    );
  }
}
