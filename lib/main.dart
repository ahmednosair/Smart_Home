import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:path_provider/path_provider.dart';

import 'home_page.dart';
import 'room.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  List<Room> rooms = await loadRooms();

  runApp(MyApp(rooms: rooms));
}

//Load rooms information from saved file
Future<List<Room>> loadRooms() async {
  final ipReg = RegExp(r'^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)(\.|$)){4}$');
  List<Room> rooms = [];
  Map<String, int> roomNameToIndex = {};
  await (NetworkInfo().getWifiIP()).then(
    (ip) async {
      final String subnet = ip!.substring(0, ip.lastIndexOf('.'));
      const port = 80;
      for (var i = 100; i < 103; i++) {
        String ip = '$subnet.$i';
        await Socket.connect(ip, port, timeout: Duration(milliseconds: 100))
            .then((socket) async {
          StringBuffer response = StringBuffer();
          bool done = false;
          StreamSubscription sub = socket.listen((event) {
            String s = const AsciiDecoder().convert(event);
            response.write(s);
            if (s.contains("#")) {
              done = true;
            }
          });
          int timeOut = 0;
          while (!done && timeOut < 10) {
            await Future.delayed(const Duration(milliseconds: 10));
            timeOut++;
          }
          print(done);
          print(timeOut);
          await sub.cancel();
          String raw = response.toString();
          if (raw.isEmpty) {
            socket.close();
            return;
          }
          socket.close();
          String roomName = raw.split("#")[0];
          print(roomName);
          int roomIndex;
          if (roomNameToIndex.containsKey(roomName)) {
            roomIndex = roomNameToIndex[roomName]!;
          } else {
            rooms.add(Room(roomName));
            roomIndex = rooms.length - 1;
            roomNameToIndex[roomName] = roomIndex;
          }
          rooms[roomIndex].channelsIPs.add(ip);
        }).catchError((error) => null);
      }
    },
  );
  print('Done');
  return rooms;
}

class MyApp extends StatelessWidget {
  final List<Room> rooms;

  const MyApp({Key? key, required this.rooms}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const title = 'Smart Home';
    return MaterialApp(
      title: title,
      home: HomePage(
        rooms: rooms,
      ),
    );
  }
}
