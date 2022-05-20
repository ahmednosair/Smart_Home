import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:avatar_glow/avatar_glow.dart';
import 'package:speech_to_text/speech_to_text.dart';

import 'package:flutter/material.dart';

import 'main.dart';

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
    for (String IP in widget.room.channelsIPs) {
      int oldDevicesSize = widget.room.devicesNames.length;
      try {
        Socket sock = await Socket.connect(IP, 80);
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
        print(raw);
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
        print(widget.room.sensorsNames);
        print(widget.room.sensorsValues);
      } catch (e) {
        print(e);
        print("HiCatch");
        continue;
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

class SwitchesBox extends StatefulWidget {
  Room room;

  SwitchesBox({required this.room}) {}

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
    print("Swtich box build");
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

class SensorsBox extends StatelessWidget {
  Room room;
  List<TextEditingController> controllers = [];

  SensorsBox({required this.room}) {
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
              style: TextStyle(fontSize: 22),
            ),
            flex: 3,
          ),
          Flexible(
            child: TextField(
              textAlign: TextAlign.center,
              controller: controllers[room.sensorToIndex[sensor] as int],
              readOnly: true,
              style: TextStyle(fontSize: 22),
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

class VoiceInterface extends StatefulWidget {
  Room room;

  VoiceInterface({required this.room}) {}

  @override
  _VoiceInterfaceState createState() {
    return _VoiceInterfaceState();
  }
}

class _VoiceInterfaceState extends State<VoiceInterface> {
  bool isListen = false;
  SpeechToText speech = SpeechToText();

  void listen() async {
    await speech.initialize(onStatus: (status) {
      if (status == "done") {
        setState(() {
          isListen = false;
        });
        speech.stop();
      }
    });

    if (!isListen) {
      if (speech.isAvailable) {
        setState(() {
          isListen = true;
        });
        speech.listen(onResult: (value) {
          if (value.finalResult) {
            if (widget.room.executeVoiceCommand(value.recognizedWords)) {
              widget.room.switchesBoxSetState!(() {});
            }
          }
        });
      }
    } else {
      setState(() {
        isListen = false;
      });
      speech.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: AvatarGlow(
        animate: isListen,
        glowColor: Colors.red,
        endRadius: 65.0,
        duration: Duration(milliseconds: 2000),
        repeatPauseDuration: Duration(milliseconds: 100),
        repeat: true,
        child: FloatingActionButton(
          child: Icon(isListen ? Icons.mic : Icons.mic_none),
          onPressed: () {
            listen();
          },
        ),
      ),
      height: 70,
    );
  }
}
