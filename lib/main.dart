import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:graduation_project/config_page.dart';
import 'package:network_info_plus/network_info_plus.dart';

import 'home_page.dart';
import 'room.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _MyAppState();
  }
}

class _MyAppState extends State<MyApp> with TickerProviderStateMixin {
  List<Room> rooms = [];
  Map<String, int> roomNameToIndex = {};
  late TabController _tabController;

  _MyAppState() {
    loadRooms();
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if(_tabController.index==0&&_tabController.indexIsChanging){
        Future.delayed(const Duration(milliseconds: 500),loadRooms);
      }
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
    StreamSubscription sub = socket.listen((event) {
      String s = const AsciiDecoder().convert(event);
      response.write(s);
      if (s.contains("#")) {
        done = true;
      }
    });
    int timeOut = 0;
    while (!done && timeOut < 50) {
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
    setState(() {
      if (roomNameToIndex.containsKey(roomName)) {
        roomIndex = roomNameToIndex[roomName]!;
      } else {
        rooms.add(Room(roomName));
        roomIndex = rooms.length - 1;
        roomNameToIndex[roomName] = roomIndex;
      }
      print(ip);
      rooms[roomIndex].channelsIPs.add(ip);
    });
  }

  void loadRooms() async {
    roomNameToIndex.clear();
    rooms.clear();

    String? ipRng = await (NetworkInfo().getWifiIP());
    final String
        subnet = /*ipRng!.substring(0, ipRng.lastIndexOf('.'));*/ "192.168.1";
    const port = 80;
    for (int i = 2; i < 255; i++) {
      String ip = '$subnet.$i';
      ping(ip, port);
    }
  }

  @override
  Widget build(BuildContext context) {
    const title = 'Smart Home';
    return MaterialApp(
      title: title,
      home: Scaffold(
        appBar: AppBar(
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(
                icon: Icon(Icons.home),
              ),
              Tab(icon: Icon(Icons.settings)),
            ],
          ),
          title: const Text('Smart Home'),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            HomePage(rooms: rooms),
            ConfigPage(refreshRooms: loadRooms),
          ],
        ),
      ),
    );
  }
}
