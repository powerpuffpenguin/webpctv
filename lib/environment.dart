class MyEnvironment {
  MyEnvironment._();

  static const String applicationLegalese = "© 2022 The TV for WebPC";
  static const String appName = "WebPC TV";
  static String get packageName => "com.king011.webpctv";
  static String get playStore =>
      'https://play.google.com/store/apps/details?id=$packageName';

  static String version = "v0.1.0";

  static bool get isProduct => const bool.fromEnvironment("dart.vm.product");
  static bool get isDebug => !isProduct;

  static const double viewPadding = 14;
  static const double spacing = 10;
  static String durationToString(Duration duration) => duration.inDays > 0
      ? "${duration.inDays} days ${duration.inHours.remainder(24).toString().padLeft(2, '0')}:${duration.inMinutes.remainder(60).toString().padLeft(2, '0')}:${duration.inSeconds.remainder(60).toString().padLeft(2, '0')}"
      : "${duration.inHours.toString().padLeft(2, '0')}:${duration.inMinutes.remainder(60).toString().padLeft(2, '0')}:${duration.inSeconds.remainder(60).toString().padLeft(2, '0')}";
}
