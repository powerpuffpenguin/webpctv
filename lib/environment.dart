class MyEnvironment {
  MyEnvironment._();

  static const String applicationLegalese = "© 2022 The TV for WebPC";
  static const String appName = "WebPC TV";
  static String get packageName => "com.king011.webpctv";
  static String get playStore =>
      'https://play.google.com/store/apps/details?id=$packageName';

  static String version = "v0.0.1";

  static bool get isProduct => const bool.fromEnvironment("dart.vm.product");
  static bool get isDebug => !isProduct;

  static const double viewPadding = 14;
  static const double spacing = 10;
}
