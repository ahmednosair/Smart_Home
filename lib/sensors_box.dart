import 'dart:async';
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
    widget.room.sensorBoxSetState = setState;
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
           Text(
            sensor,
            style: const TextStyle(fontSize: 24),
          ),
        const SizedBox(width: 20,),
         SizedBox(width: 100,child: TextField(
            readOnly: true,
            controller: TextEditingController(text: widget
                .room.sensorsValues[widget.room.sensorToIndex[sensor] as int]),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 24),
          ),),
        ],
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        mainAxisSize: MainAxisSize.min,
      ));
    }
    return rows;
  }

  @override
  void dispose() {
    super.dispose();
    widget.room.sensorBoxSetState = null;
  }
}
