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
    Tracker().start(TrackerConfig("http://192.168.0.23:8080/mob/location/upload",
        minTimeInterval: 30,
        minDistance: 0.0,
        headers: {"Authorization": "Bearer eyJhbGciOiJIUzUxMiJ9.eyJsb2dpbl91c2VyX2tleSI6IjVhYjJiZWVlLTA1N2MtNGM0OS1hYmUyLWI1Y2QwM2NlYmRlNiJ9.IusCiRjAdggWEEjtFdHNa7XdYWqoHB-d9y9wEpRalQ-Cy9QSY9VQOl9G2xF2T2ogPXLuspfY8iti5k0vIxDDYw"},
        ));
  }

  Future<void> restart() async {
    if (!mounted) return;
    Tracker().start(TrackerConfig("http://192.168.0.23:8080/mob/location/upload",
        minTimeInterval: 60,
        minDistance: 10.0,
        headers: {"Authorization": "Bearer eyJhbGciOiJIUzUxMiJ9.eyJsb2dpbl91c2VyX2tleSI6IjVhYjJiZWVlLTA1N2MtNGM0OS1hYmUyLWI1Y2QwM2NlYmRlNiJ9.IusCiRjAdggWEEjtFdHNa7XdYWqoHB-d9y9wEpRalQ-Cy9QSY9VQOl9G2xF2T2ogPXLuspfY8iti5k0vIxDDYw"},
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
