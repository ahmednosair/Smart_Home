import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'room.dart';

class SensorsBox extends StatefulWidget {
  final Room room;

  const SensorsBox({Key? key, required this.room}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _SensorBoxState();
  }
}

class _SensorBoxState extends State<SensorsBox> {
  final List<TextEditingController> controllers = [];
  final List<StreamSubscription> subs = [];
  final List<StringBuffer> buffs = [];

  @override
  void initState() {
    super.initState();
    for (String sensor in widget.room.sensorsNames) {
      controllers.add(TextEditingController());
      controllers[widget.room.sensorToIndex[sensor] as int].text =
          widget.room.sensorsValues[widget.room.sensorToIndex[sensor] as int];
    }
    for (Stream stream in widget.room.channelsStream) {
      buffs.add(StringBuffer());
      final int index = buffs.length - 1;
      subs.add(stream.listen((event) {
        String raw = const AsciiDecoder().convert(event);
        if (!raw.contains("sensor")) {
          return;
        }
        buffs[index].write(raw);
        String str = buffs[index].toString();
        if (str.contains("\n")) {
          List<String> splits = str.split("\n");
          buffs[index].clear();
          buffs[index].write(splits[splits.length - 1]);
          for (int i = 0; i < splits.length - 1; i++) {
            List<String> tokens = splits[i].split("#");
            controllers[widget.room.sensorToIndex[tokens[1]] as int].text =
                tokens[2];
          }
        }
      }, onError: (error) {
        if (kDebugMode) {
          print("Module sensors socket disconnected");
        }
      }));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: getSensors(),
    );
  }

  List<Widget> getSensors() {
    List<Widget> rows = [];
    for (String sensor in widget.room.sensorsNames) {
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
              controller: controllers[widget.room.sensorToIndex[sensor] as int],
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

  @override
  void dispose() async {
    super.dispose();

    for (StreamSubscription sub in subs) {
      await sub.cancel();
    }
  }
}
