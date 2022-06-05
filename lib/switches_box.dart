import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';

import 'room.dart';


class SwitchesBox extends StatefulWidget {
  final Room room;

  const SwitchesBox({Key? key, required this.room}) : super(key: key);

  @override
  _SwitchesBoxState createState() {
    return _SwitchesBoxState(room);
  }
}

class _SwitchesBoxState extends State<SwitchesBox> {
  _SwitchesBoxState(Room room) {
    room.switchesBoxSetState = setState;
    for (Stream stream in room.channelsStream) {
      stream.listen((event) {
        String raw = const AsciiDecoder().convert(event);
        //uncompleted command to be handled (\n)
        List<String> tokens = raw.substring(0, raw.length - 1).split("#");
        if (tokens[0] != "device") {
          return;
        }
        setState(() {
          room.switchState[room.deviceToIndex[tokens[1]] as int] =
          (tokens[2] == "ON");
        });
      });
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

  String spacePad(String input){
    int len = 12;
    StringBuffer buff = StringBuffer();
    buff.write(input);
    while(buff.length<len){
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
      rows.add(const SizedBox(height: 10,));
      index++;
    }
    return rows;
  }
}
