import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';

import 'room.dart';

class SwitchesBox extends StatefulWidget {
  final Room room;

  const SwitchesBox({Key? key, required this.room}) : super(key: key);

  @override
  _SwitchesBoxState createState() {
    return _SwitchesBoxState();
  }
}

class _SwitchesBoxState extends State<SwitchesBox> {
  final List<StreamSubscription> subs = [];
  final List<StringBuffer> buffs = [];

  @override
  void initState() {
    super.initState();
    widget.room.switchesBoxSetState = setState;
    for (Stream stream in widget.room.channelsStream) {
      buffs.add(StringBuffer());
      final int index = buffs.length - 1;
      StreamSubscription sub = stream.listen((event) {
        String raw = const AsciiDecoder().convert(event);
        if(!raw.contains("device")){
          return;
        }
        buffs[index].write(raw);
        String str = buffs[index].toString();
        if (str.contains("\n")) {
          List<String> splits = str.split("\n");
          buffs[index].clear();
          buffs[index].write(splits[splits.length - 1]);
          for (int i = 0; i < splits.length - 1; i++) {
            List<String> tokens =
            splits[i].split("#");
            setState(() {
              widget.room.switchState[widget.room.deviceToIndex[tokens[1]] as int] =
              (tokens[2] == "ON");
            });
          }
        }
      });
      subs.add(sub);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: getChildren(),
    );
  }

  String spacePad(String input) {
    int len = 12;
    StringBuffer buff = StringBuffer();
    buff.write(input);
    while (buff.length < len) {
      buff.write(' ');
    }
    return buff.toString();
  }

  List<Widget> getChildren() {
    List<Widget> rows = [];
    int index = 0;
    for (String device in widget.room.devicesNames) {
      int curr = index;
      String currDevice = device;
      rows.add(Transform.scale(
        scale: 2,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(spacePad(device)),
            Switch(
              value: widget.room.switchState[curr],
              onChanged: (value) {
                if (value) {
                  widget.room.sendCommand(currDevice, "ON");
                } else {
                  widget.room.sendCommand(currDevice, "OFF");
                }
                setState(() {
                  widget.room.switchState[curr] = value;
                });
              },
              activeTrackColor: Colors.lightGreenAccent,
              activeColor: Colors.green,
            )
          ],
        ),
      ));
      rows.add(const SizedBox(
        height: 10,
      ));
      index++;
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
