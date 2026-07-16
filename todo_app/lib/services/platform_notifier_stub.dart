import 'platform_notifier.dart';

class PlatformNotifierImpl implements PlatformNotifier {
  @override
  Future<bool> requestPermission() async => false;

  @override
  void show(String title, String body) {
    // No OS-level notification support on this platform; the in-app
    // banner shown by NotificationService is the fallback.
  }
}
