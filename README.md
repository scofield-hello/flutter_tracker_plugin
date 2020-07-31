# tracker

flutter位置上报插件.

## 使用方式
```dart
val config = TrackerConfig("https://httpbin.org/post",
                     minTimeInterval: 60,
                     minDistance: 0.0,
                     headers: {"token": "123456"},
                     extraBody: {"extra1": "1", "extra2": "2"});
//开启
Tracker().start(config);
//关闭
Tracker().stop();
```