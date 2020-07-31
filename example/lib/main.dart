import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tracker/tracker.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
  }

  Future<void> start() async {
    if (!mounted) return;
    Tracker().start(TrackerConfig("http://192.168.0.23:8080/location/info/create",
        minTimeInterval: 30,
        minDistance: 0.0,
        headers: {"Authorization": "Bearer eyJhbGciOiJIUzUxMiJ9.eyJsb2dpbl91c2VyX2tleSI6IjhhZDU2ZWU0LWY2ZTUtNDc2My04NTYwLTgwYTk5Zjc2MTIyOCJ9.8Mh8lFu4Rd9uhV6w_dRvCGfZE3ErpvJz6UiOZnhuKOrjM_WMFp8aMd6rXs9Uro3CaQodhfLAon-gvh5Vyrtxag"},
        ));
  }

  Future<void> restart() async {
    if (!mounted) return;
    Tracker().start(TrackerConfig("http://192.168.0.23:8080/location/info/create",
        minTimeInterval: 60,
        minDistance: 10.0,
        headers: {"Authorization": "Bearer eyJhbGciOiJIUzUxMiJ9.eyJsb2dpbl91c2VyX2tleSI6IjhhZDU2ZWU0LWY2ZTUtNDc2My04NTYwLTgwYTk5Zjc2MTIyOCJ9.8Mh8lFu4Rd9uhV6w_dRvCGfZE3ErpvJz6UiOZnhuKOrjM_WMFp8aMd6rXs9Uro3CaQodhfLAon-gvh5Vyrtxag"},
        extraBody: {"extra": "1"}));
  }

  Future<void> stop() async {
    if (!mounted) return;
    Tracker().stop();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: Column(
            children: <Widget>[
              RaisedButton(
                onPressed: () {
                  start();
                },
                child: Text("打开"),
              ),
              RaisedButton(
                onPressed: () {
                  restart();
                },
                child: Text("更新"),
              ),
              RaisedButton(
                onPressed: () {
                  stop();
                },
                child: Text("关闭"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
