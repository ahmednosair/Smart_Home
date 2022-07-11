import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:graduation_project/config_page.dart';
import 'package:network_info_plus/network_info_plus.dart';

import 'home_page.dart';
import 'room.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const MaterialApp(home: MyApp(),));
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
    },onError: (error){
      if (kDebugMode) {
        print("Initialization socket disconnected");
      }
    });
    int timeOut = 0;
    while (!done && timeOut < 50) {
      await Future.delayed(const Duration(milliseconds: 10));
      timeOut++;
    }
    try{
      await sub.cancel();
    }catch(e){
      if (kDebugMode) {
        print("failed closing bad initialization socket");
      }
    }
    String raw = response.toString();
    if (raw.isEmpty) {
      socket.close();
      return;
    }
    socket.close();
    String roomName = raw.split("#")[0];
    int roomIndex;
    setState(() {
      if (roomNameToIndex.containsKey(roomName)) {
        roomIndex = roomNameToIndex[roomName]!;
      } else {
        rooms.add(Room(roomName));
        roomIndex = rooms.length - 1;
        roomNameToIndex[roomName] = roomIndex;
      }
      rooms[roomIndex].channelsIPs.add(ip);
    });
  }

  void loadRooms() async {
    roomNameToIndex.clear();
    rooms.clear();

    String? ipRng = await (NetworkInfo().getWifiIP());
    final String
        subnet = ipRng!.substring(0, ipRng.lastIndexOf('.')); /*"192.168.1";*/
    const port = 80;
    for (int i = 2; i < 255; i++) {
      String ip = '$subnet.$i';
      ping(ip, port);
    }
  }

  @override
  Widget build(BuildContext context) {
    const title = 'Smart Home';
    return Scaffold(
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
          actions: [
            IconButton(
              icon: Icon(Icons.info_outline),
              onPressed: () {
                showDialog<String>(
                  context: context,
                  builder: (BuildContext context) => AlertDialog(
                    title: const Text('How to use'),
                    content: const Text("- Connect to the module hotspot named \"Smart Home Module\""
                        ".\n\n- Head to the configuration tab to configure the module"
                        ".\n\n- The home tab contains the rooms buttons"
                        ".\n\n- Inside each room, there are devices to control and sensors readings if exist"
                        ".\n\n- The button with mic icon can be used to control devices using voice."),
                    actions: <Widget>[
                      TextButton(
                        onPressed: () => Navigator.pop(context, 'OK'),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            HomePage(rooms: rooms,loadRooms:loadRooms),
            ConfigPage(refreshRooms: loadRooms),
          ],
        ),
      );
  }
}
