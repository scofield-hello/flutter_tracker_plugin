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
    Tracker().start(TrackerConfig("https://httpbin.org/post",
        minTimeInterval: 30,
        minDistance: 0.0,
        headers: {"token": "123456", "timestamp": "123454545454"},
        extraBody: {"extra1": "1", "extra2": "2"}));
  }

  Future<void> restart() async {
    if (!mounted) return;
    Tracker().start(TrackerConfig("https://httpbin.org/post",
        minTimeInterval: 60,
        minDistance: 0.0,
        headers: {"token": "123456", "timestamp": "123454545454"},
        extraBody: {"extra1": "1", "extra2": "2"}));
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
