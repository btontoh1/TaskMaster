abstract class PlatformNotifier {
  Future<bool> requestPermission();
  void show(String title, String body);
}
