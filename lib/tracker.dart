import 'package:flutter/services.dart';
import 'package:meta/meta.dart';

class TrackerConfig {
  ///指定位置上报接口地址.
  final String postUrl;

  ///指定位置上报携带的请求头.
  final Map<String, String> headers;

  ///指定位置上报携带的额外参数.
  final Map<String, String> extraBody;

  ///最小定位时间间隔(秒).
  final int minTimeInterval;

  ///最小定位距离间隔(米).
  final double minDistance;

  ///安卓常驻通知标题.
  final String notificationTitle;

  ///安卓常驻通知内容.
  final String notificationContent;

  TrackerConfig(this.postUrl,
      {this.headers,
      this.extraBody,
      this.minTimeInterval = 300,
      this.minDistance = 0,
      this.notificationTitle = "位置上报服务已开启",
      this.notificationContent = "位置上报服务正在运行中..."})
      : assert(postUrl != null),
        assert(minTimeInterval >= 5),
        assert(minDistance >= 0),
        assert(notificationTitle != null && notificationTitle.isNotEmpty),
        assert(notificationContent != null && notificationContent.isNotEmpty);

  Map<String, dynamic> asJson() {
    return <String, dynamic>{
      "postUrl": postUrl,
      "minTimeInterval": minTimeInterval,
      "minDistance": minDistance,
      "headers": headers ?? <String, String>{},
      "extraBody": extraBody ?? <String, String>{},
      "notificationTitle": notificationTitle,
      "notificationContent": notificationContent
    };
  }
}

class Tracker {
  static Tracker _singleton;
  final MethodChannel _methodChannel;
  final EventChannel _eventChannel;

  factory Tracker() {
    if (_singleton == null) {
      const MethodChannel methodChannel = MethodChannel('com.chuangdun.flutter/tracker/methods');
      const EventChannel eventChannel = EventChannel('com.chuangdun.flutter/tracker/events');
      _singleton = Tracker.private(methodChannel, eventChannel);
    }
    return _singleton;
  }

  @visibleForTesting
  Tracker.private(this._methodChannel, this._eventChannel);

  Future<void> start(TrackerConfig config) async {
    assert(config != null);
    await _methodChannel.invokeMethod("start", config.asJson());
  }

  Future<void> stop() async {
    await _methodChannel.invokeMethod("stop");
  }
}
