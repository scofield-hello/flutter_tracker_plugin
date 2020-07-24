import 'dart:async';

import 'package:flutter/services.dart';

class Tracker {
  static const MethodChannel _channel =
      const MethodChannel('tracker');

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }
}
