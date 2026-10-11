import 'package:flutter/services.dart';

class AppExitService {
  static const _channel = MethodChannel('com.flutter_ai_music/app_exit');

  const AppExitService._();

  static Future<void> closeTask() async {
    try {
      await _channel.invokeMethod<void>('finishAndRemoveTask');
    } on PlatformException {
      await SystemNavigator.pop(animated: true);
    } on MissingPluginException {
      await SystemNavigator.pop(animated: true);
    }
  }
}
