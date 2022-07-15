import 'dart:async';
import 'package:flutter/material.dart';

import 'room.dart';

class SwitchesBox extends StatefulWidget {
  final Room room;
  final Function() loadRooms;

  const SwitchesBox({Key? key, required this.room, required this.loadRooms})
      : super(key: key);

  @override
  _SwitchesBoxState createState() {
    return _SwitchesBoxState();
  }
}

class _SwitchesBoxState extends State<SwitchesBox> {
  @override
  void initState() {
    super.initState();
    widget.room.switchesBoxSetState = setState;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: getChildren(),
    );
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
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 80),
              child: Text(
                (device),
                textAlign: TextAlign.center,
              ),
            ),
            Switch(
              value: widget.room.switchState[curr],
              onChanged: (value) async {
                final Future<bool> success;
                if (value) {
                  success = widget.room.sendCommand(currDevice, "ON");
                } else {
                  success = widget.room.sendCommand(currDevice, "OFF");
                }
                setState(() {
                  widget.room.buffMutexes[widget.room.deviceToChannel[device]!].acquire();
                  widget.room.switchState[curr] = value;
                  widget.room.buffMutexes[widget.room.deviceToChannel[device]!].release();

                });
                success.then((success) {
                  if (!success) {
                    widget.loadRooms();
                    if(Navigator.canPop(context)){
                      showDialog<String>(
                        context: context,
                        builder: (BuildContext context) => AlertDialog(
                          title: const Text('Error'),
                          content: const Text(
                              "Can't send command to the module\nPlease sure that you are connected to the WiFi or try to restart the application"),
                          actions: <Widget>[
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                                while (Navigator.canPop(context)) {
                                  Navigator.pop(context);
                                }
                              },
                              child: const Text('OK'),
                            ),
                          ],
                        ),
                      );
                    }
                  }
                }).timeout(const Duration(seconds: 10), onTimeout: () {
                  if(Navigator.canPop(context)){
                    showDialog<String>(
                      context: context,
                      builder: (BuildContext context) => AlertDialog(
                        title: const Text('Error'),
                        content: const Text(
                            "Can't send command to the module\nPlease sure that you are connected to the WiFi or try to restart the application"),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              while (Navigator.canPop(context)) {
                                Navigator.pop(context);
                              }
                            },
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    );
                  }
                });
              },
              activeTrackColor: Colors.lightGreenAccent,
              activeColor: Colors.green,
            )
          ],
        ),
      ));
      rows.add(const SizedBox(
        height: 20,
      ));
      index++;
    }
    return rows;
  }

  @override
  void dispose() {
    super.dispose();
    widget.room.switchesBoxSetState = null;
  }
}
