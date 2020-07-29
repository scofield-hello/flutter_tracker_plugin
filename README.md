# tracker

flutter位置上报插件.

## Getting Started

This project is a starting point for a Flutter
[plug-in package](https://flutter.dev/developing-packages/),
a specialized package that includes platform-specific implementation code for
Android and/or iOS.

For help getting started with Flutter, view our 
[online documentation](https://flutter.dev/docs), which offers tutorials, 
samples, guidance on mobile development, and a full API reference.

## 使用方式
```dart
val config = TrackerConfig("https://httpbin.org/post",
                     minTimeInterval: 60,
                     minDistance: 0.0,
                     headers: {"token": "123456"},
                     extraBody: {"extra1": "1", "extra2": "2"});
Tracker().start(config);
```