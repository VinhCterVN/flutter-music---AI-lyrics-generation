import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class AppExitService {
  static const _channel = MethodChannel('com.flutter_ai_music/app_exit');

  const AppExitService._();

  static Future<void> closeTask() async {
    if (kIsWeb) return;

    if (defaultTargetPlatform == TargetPlatform.android) {
      try {
        await _channel.invokeMethod<void>('finishAndRemoveTask');
      } on PlatformException {
        await SystemNavigator.pop(animated: true);
      } on MissingPluginException {
        await SystemNavigator.pop(animated: true);
      }
      return;
    }

    await SystemNavigator.pop(animated: true);
  }
}
