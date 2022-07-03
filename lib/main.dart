import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:graduation_project/config_page.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:path_provider/path_provider.dart';

import 'home_page.dart';
import 'room.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _MyAppState();
  }
}

class _MyAppState extends State<MyApp> {
  Future<List<Room>> loadRooms() async {
    final ipReg =
        RegExp(r'^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)(\.|$)){4}$');
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
    /*Room room = Room("Bedroom 1");
  room.channelsIPs.add("192.168.1.101");
  return [room];*/
  }

  @override
  Widget build(BuildContext context) {
    const title = 'Smart Home';
    return MaterialApp(
      title: title,
      home: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            bottom: const TabBar(
              tabs: [
                Tab(
                  icon: Icon(Icons.home),
                ),
                Tab(icon: Icon(Icons.settings)),
              ],
            ),
            title: const Text('Smart Home'),
          ),
          body: TabBarView(
            children: [
              FutureBuilder(
                future: loadRooms(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return HomePage(
                      rooms: snapshot.data as List<Room>,
                    );
                  }
                  return HomePage(rooms: []);
                },
              ),
              ConfigPage(myAppSetState: setState),
            ],
          ),
        ),
      ),
    );
  }
}
