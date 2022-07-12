import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mutex/mutex.dart';
import 'package:network_info_plus/network_info_plus.dart';

import 'home_button.dart';
import 'room.dart';
import 'room_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key, required this.setParentLoadRooms})
      : super(key: key);
  final void Function(void Function() fn) setParentLoadRooms;

  @override
  _HomePageState createState() {
    return _HomePageState();
  }
}

class _HomePageState extends State<HomePage>
    with AutomaticKeepAliveClientMixin {
  final Map<String, int> roomNameToIndex = {};
  final List<Room> rooms = [];
  final Mutex updateRooms = Mutex();
  var lastReload = 0;

  @override
  void initState() {
    super.initState();
    widget.setParentLoadRooms(loadRooms);
    loadRooms();
  }

  void loadRooms() async {
    if (DateTime.now().microsecondsSinceEpoch - lastReload < 5000000) {
      return;
    }
    lastReload = DateTime.now().microsecondsSinceEpoch;
    disposeRooms();
    rooms.clear();
    roomNameToIndex.clear();
    String? ipRng = await (NetworkInfo().getWifiIP());
    if (ipRng == null) {
      setState(() {});
      return;
    }
    final String subnet =
        ipRng.substring(0, ipRng.lastIndexOf('.'));//  "192.168.1";
    const int port = 55555;
    for (int i = 2; i < 255; i++) {
      String ip = '$subnet.$i';
      ping(ip, port);
      await Future.delayed(const Duration(milliseconds: 2));
    }
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {});
    });
  }

  void ping(String ip, int port) async {
    Socket socket;
    try {
      socket =
          await Socket.connect(ip, port, timeout: const Duration(seconds: 4));
    } catch (e) {
      return;
    }
    StringBuffer response = StringBuffer();
    bool done = false;
    Stream broadStream = socket.asBroadcastStream();
    StreamSubscription sub = broadStream.listen((event) {
      String s = const AsciiDecoder().convert(event);
      response.write(s);
      if (s.contains("\n")) {
        done = true;
      }
    }, onError: (error) {
      if (kDebugMode) {
        print("Initialization socket disconnected");
      }
    });
    int timeOut = 0;
    while (!done && timeOut < 50) {
      await Future.delayed(const Duration(milliseconds: 10));
      timeOut++;
    }
    try {
      await sub.cancel();
    } catch (e) {
      if (kDebugMode) {
        print("failed closing bad initialization socket");
      }
    }
    String raw = response.toString();
    if (raw.isEmpty) {
      socket.close();
      return;
    }
    String roomName = raw.split("#")[0];
    int roomIndex;
    updateRooms.acquire();
    setState(() {
      if (roomNameToIndex.containsKey(roomName)) {
        roomIndex = roomNameToIndex[roomName]!;
      } else {
        rooms.add(Room(roomName));
        roomIndex = rooms.length - 1;
        roomNameToIndex[roomName] = roomIndex;
      }
      int oldDevicesSize = rooms[roomIndex].devicesNames.length;
      int oldSensorsSize = rooms[roomIndex].sensorsNames.length;
      List<String> tmp = raw.substring(0, raw.length - 1).split("\$");
      List<String> deviceTokens = tmp[0].split("#");
      List<String> sensorTokens = tmp[1].split("#");
      deviceTokens = deviceTokens.sublist(1, deviceTokens.length - 1);
      sensorTokens = sensorTokens.sublist(0, sensorTokens.length - 1);
      rooms[roomIndex]
          .devicesNames
          .addAll(deviceTokens.sublist(0, deviceTokens.length ~/ 2));
      List<String> rawStates = deviceTokens.sublist(deviceTokens.length ~/ 2);
      rooms[roomIndex]
          .sensorsNames
          .addAll(sensorTokens.sublist(0, sensorTokens.length ~/ 2));
      rooms[roomIndex]
          .sensorsValues
          .addAll(sensorTokens.sublist(sensorTokens.length ~/ 2));
      for (String rawState in rawStates) {
        rooms[roomIndex].switchState.add(rawState == "ON");
      }
      rooms[roomIndex].channels.add(socket);
      rooms[roomIndex].ack[rooms[roomIndex].channels.length - 1] = 0;
      rooms[roomIndex].buffs.add(StringBuffer());
      int k = oldDevicesSize;
      for (int i = oldDevicesSize;
          i < rooms[roomIndex].devicesNames.length;
          i++) {
        rooms[roomIndex].deviceToChannel[rooms[roomIndex].devicesNames[i]] =
            rooms[roomIndex].channels.length - 1;
        rooms[roomIndex].deviceToIndex[rooms[roomIndex].devicesNames[i]] = k;
        k++;
      }
      int m = oldSensorsSize;
      for (String sensor in rooms[roomIndex].sensorsNames) {
        rooms[roomIndex].sensorToIndex[sensor] = m;
        m++;
      }
      final int index = rooms[roomIndex].channels.length - 1;
      StreamSubscription sub = broadStream.listen((event) {
        String raw = const AsciiDecoder().convert(event);
        rooms[roomIndex].buffs[index].write(raw);
        String str = rooms[roomIndex].buffs[index].toString();
        if (str.contains("\n")) {
          List<String> splits = str.split("\n");
          rooms[roomIndex].buffs[index].clear();
          rooms[roomIndex].buffs[index].write(splits[splits.length - 1]);
          for (int i = 0; i < splits.length - 1; i++) {
            if (splits[i] == "OK") {
              rooms[roomIndex].ack[index] = rooms[roomIndex].ack[index]! + 1;
            } else if (splits[i].contains("device")) {
              List<String> tokens = splits[i].split("#");
              rooms[roomIndex].updateSwitchesBox(() {
                rooms[roomIndex].switchState[
                        rooms[roomIndex].deviceToIndex[tokens[1]] as int] =
                    (tokens[2] == "ON");
              });
            } else if (splits[i].contains("sensor")) {
              List<String> tokens = splits[i].split("#");
              rooms[roomIndex].updateSensorsBox(() {
                rooms[roomIndex].sensorsValues[
                        rooms[roomIndex].sensorToIndex[tokens[1]] as int] =
                    tokens[2];
              });
            } else {
              if (kDebugMode) {
                print("Unknown command received from module!!");
              }
            }
          }
        }
      }, onError: (error) {
        loadRooms();
        if (kDebugMode) {
          print("Module socket disconnected");
        }
        showDialog<String>(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            title: const Text('Error'),
            content: const Text("Module disconnected"),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.pop(context, 'OK');
                  while (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  }
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      });
      rooms[roomIndex].subs.add(sub);
    });
    updateRooms.release();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          showDialog(
              barrierDismissible: false,
              context: context,
              builder: (_) {
                return Dialog(
                  // The background color
                  backgroundColor: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        // The loading indicator
                        CircularProgressIndicator(),
                        SizedBox(
                          height: 15,
                        ),
                        // Some text
                        Text('Refreshing rooms...')
                      ],
                    ),
                  ),
                );
              });
          loadRooms();
          await Future.delayed(const Duration(seconds: 3));
          Navigator.pop(context);
        },
        child: const Icon(
          Icons.refresh_outlined,
          size: 35,
        ),
        highlightElevation: 50,
        splashColor: Colors.grey,
      ),
      body: GridView(
        gridDelegate:
            const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2),
        children: getHomeButtons(context),
        physics: const ScrollPhysics(),
      ),
    );
  }

  List<HomeButton> getHomeButtons(BuildContext context) {
    List<HomeButton> buttons = [];
    for (Room room in rooms) {
      buttons.add(HomeButton(
        image: room.image,
        text: room.roomName,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RoomScreen(
                loadRooms: loadRooms,
                room: room,
              ),
            ),
          );
        },
        fontSize: 18,
      ));
    }
    return buttons;
  }

  void disposeRooms() {
    for (Room room in rooms) {
      room.dispose();
    }
  }

  @override
  void dispose() async {
    super.dispose();
    disposeRooms();
    rooms.clear();
    roomNameToIndex.clear();
  }

  @override
  bool get wantKeepAlive => true;
}
