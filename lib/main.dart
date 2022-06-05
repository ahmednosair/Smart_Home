import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
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
  final directory = await getApplicationDocumentsDirectory();
  final File file = File('${directory.path}/rooms.txt');
  if (await file.exists()) {
    String raw = await file.readAsString();
    List<String> tokens = (raw).split("#");
    if (tokens.isNotEmpty) {
      tokens = tokens.sublist(0, tokens.length - 1);
    }
    for (String token in tokens) {
      if (ipReg.hasMatch(token)) {
        rooms[rooms.length - 1].channelsIPs.add(token);
      } else {
        rooms.add(Room(token));
      }
    }
  }
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

