import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'room.dart';
import 'sensors_box.dart';
import 'switches_box.dart';
import 'voice_interface.dart';

class RoomScreen extends StatefulWidget {
  Room room;

  @override
  _RoomScreenState createState() {
    return _RoomScreenState();
  }

  RoomScreen({Key? key, required this.room}) : super(key: key);
}
class _RoomScreenState extends State<RoomScreen> {
  Future<bool> initializeRoom() async {
    widget.room.devicesNames.clear();
    widget.room.switchState.clear();
    widget.room.channels.clear();
    widget.room.deviceToChannel.clear();
    widget.room.channelsStream.clear();
    widget.room.sensorsNames.clear();
    widget.room.sensorsValues.clear();
    //load devices for each module
    for (String ip in widget.room.channelsIPs) {
      int oldDevicesSize = widget.room.devicesNames.length;
      try {
        Socket sock = await Socket.connect(ip, 80);
        StringBuffer response = StringBuffer();
        bool done = false;
        Stream broadStream = sock.asBroadcastStream();
        StreamSubscription sub = broadStream.listen((event) {
          String s = const AsciiDecoder().convert(event);
          response.write(s);
          if (s.codeUnitAt(s.length - 1) == '\n'.codeUnitAt(0)) {
            done = true;
          }
        });
        int timeOut = 0;
        while (!done && timeOut < 25) {
          await Future.delayed(const Duration(milliseconds: 1));
          timeOut++;
        }
        await sub.cancel();
        String raw = response.toString();
        if (raw.isEmpty) {
          sock.close();
          continue;
        }
        List<String> tmp = raw.substring(0, raw.length - 1).split("\$");
        List<String> deviceTokens = tmp[0].split("#");
        List<String> sensorTokens = tmp[1].split("#");
        deviceTokens = deviceTokens.sublist(0, deviceTokens.length - 1);
        sensorTokens = sensorTokens.sublist(0, sensorTokens.length - 1);
        widget.room.devicesNames
            .addAll(deviceTokens.sublist(0, deviceTokens.length ~/ 2));
        List<String> rawStates = deviceTokens.sublist(deviceTokens.length ~/ 2);
        widget.room.sensorsNames
            .addAll(sensorTokens.sublist(0, sensorTokens.length ~/ 2));
        widget.room.sensorsValues
            .addAll(sensorTokens.sublist(sensorTokens.length ~/ 2));

        for (String rawState in rawStates) {
          widget.room.switchState.add(rawState == "ON");
        }
        widget.room.channels.add(sock);
        widget.room.channelsStream.add(broadStream);
        int k = oldDevicesSize;
        for (int i = oldDevicesSize; i < widget.room.devicesNames.length; i++) {
          widget.room.deviceToChannel[widget.room.devicesNames[i]] =
              widget.room.channels.length - 1;
          widget.room.deviceToIndex[widget.room.devicesNames[i]] = k;
          k++;
        }
        int m = 0;
        for (String sensor in widget.room.sensorsNames) {
          widget.room.sensorToIndex[sensor] = m;
          m++;
        }
      } catch (e) {
        if (kDebugMode) {
          print(e);
        }
      }
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.room.roomName),
      ),
      body: Center(
        child: FutureBuilder(
          future: initializeRoom(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return SingleChildScrollView(
                child: Column(
                  children: [
                    SwitchesBox(room: widget.room),
                    const SizedBox(
                      height: 30,
                    ),
                    SensorsBox(room: widget.room),
                  ],
                  mainAxisAlignment: MainAxisAlignment.center,
                ),
              );
            } else {
              return Column();
            }
          },
        ),
      ),
      bottomNavigationBar: VoiceInterface(room: widget.room),
    );
  }

  @override
  void dispose() {
    //widget.channel.close();
    widget.room.dispose();
    super.dispose();
  }
}
