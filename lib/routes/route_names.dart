class RouteNames {
  static const splash = '/splash';
  static const auth = '/auth';
  static const home = '/home';
  static const profile = '/profile';
  static const chatBase = '/chat';
  static const chat = '$chatBase/:chatId';

  static String chatPath(String chatId) => '$chatBase/$chatId';
}
