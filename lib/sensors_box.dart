import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';

import 'room.dart';

class SensorsBox extends StatelessWidget {
  final Room room;
  final List<TextEditingController> controllers = [];

  SensorsBox({Key? key, required this.room}) : super(key: key) {
    for (String sensor in room.sensorsNames) {
      controllers.add(TextEditingController());
      controllers[room.sensorToIndex[sensor] as int].text =
      room.sensorsValues[room.sensorToIndex[sensor] as int];
    }
    //temperature.text = room.temperature;
    for (Stream stream in room.channelsStream) {
      stream.listen((event) {
        String raw = const AsciiDecoder().convert(event);
        //uncompleted command to be handled (\n)
        List<String> tokens = raw.substring(0, raw.length - 1).split("#");
        if (tokens[0] != "sensor") {
          return;
        }
        controllers[room.sensorToIndex[tokens[1]] as int].text = tokens[2];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      //    mainAxisAlignment: MainAxisAlignment.center,
//      mainAxisSize: MainAxisSize.min,
      children: getSensors(),
    );
  }

  List<Widget> getSensors() {
    List<Widget> rows = [];
    for (String sensor in room.sensorsNames) {
      rows.add(Row(
        children: [
          Flexible(
            child: Text(
              sensor,
              style: const TextStyle(fontSize: 22),
            ),
            flex: 3,
          ),
          Flexible(
            child: TextField(
              textAlign: TextAlign.center,
              controller: controllers[room.sensorToIndex[sensor] as int],
              readOnly: true,
              style: const TextStyle(fontSize: 22),
            ),
            flex: 1,
          ),
        ],
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
      ));
    }
    return rows;
  }
}
