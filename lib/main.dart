import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get_rx/src/rx_typedefs/rx_typedefs.dart';
import 'package:graduation_project/buttons.dart';
import 'package:graduation_project/screens.dart';
import 'package:path_provider/path_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  List<Room> rooms = await loadRooms();

  runApp(MyApp(rooms: rooms));
}

//Load rooms information from saved file
Future<List<Room>> loadRooms() async {
  final IPReg = RegExp(r'^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)(\.|$)){4}$');
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
      if (IPReg.hasMatch(token)) {
        rooms[rooms.length - 1].channelsIPs.add(token);
      } else {
        rooms.add(Room(token));
      }
    }
  }
  return rooms;
}

class Room {
  String image = "";
  String roomName = "";
  List<String> devicesNames = [];
  List<Socket> channels = [];
  Map<String, int> deviceToChannel = {};
  Map<String, int> deviceToIndex = {};
  List<String> channelsIPs = [];
  List<bool> switchState = [];
  List<Stream> channelsStream = [];
  void Function(void Function())? switchesBoxSetState;

  //String temperature = "";
  List<String> sensorsNames = [];
  List<String> sensorsValues = [];
  Map<String, int> sensorToIndex = {};

  Room(String name) {
    this.roomName = name;
    this.image = assignImg(name);
  }

  String assignImg(String name) {
    String img = "icons/living_room.png";
    if (name.isEmpty) {
      return img;
    }
    name = name.toLowerCase().split(" ")[0];
    switch (name) {
      case "bedroom":
        img = "icons/bedroom.png";
        break;
      case "bathroom":
        img = "icons/bathroom.png";
        break;
      case "kitchen":
        img = "icons/kitchen.png";
        break;
    }
    return img;
  }

  void sendCommand(String device, String command) {
    int index = deviceToChannel[device] as int;

    channels[index].write(device + "#" + command + "\n");
  }

  String literalToNum(String literal) {
    switch (literal) {
      case 'one':
        return "1";
        ;
      case 'two':
        return "2";
        ;
      case 'three':
        return "3";
      case 'four':
        return "4";
      case 'five':
        return "5";
      case 'six':
        return "6";
      case 'seven':
        return "7";
      case 'eight':
        return "8";
      case 'nine':
        return "9";
      case 'ten':
        return "10";
      default:
        return literal;
    }
  }

  bool executeVoiceCommand(String command) {
    String raw = command.toLowerCase();
    List<String> tokens = raw.split(" ");
    if (tokens.length < 2) {
      return false;
    }
    String cmnd = tokens[0] + tokens[1];
    switch (cmnd) {
      case 'turnon':
        cmnd = "ON";
        break;
      case 'turnoff':
        cmnd = "OFF";
        break;
      default:
        return false;
    }
    String dev = "";
    for (int i = 2; i < tokens.length; i++) {
      dev += (literalToNum(tokens[i]) + ' ');
    }
    if (dev.isNotEmpty) {
      dev = dev.substring(0, dev.length - 1);
    }
    String rawDev = dev;
    for (String device in devicesNames) {
      if (device.toLowerCase() == dev) {
        dev = device;
        break;
      }
    }
    if (dev == rawDev) {
      return false;
    }
    sendCommand(dev, cmnd);
    switchState[deviceToIndex[dev] as int] = (cmnd == "ON");
    return true;
  }

  void dispose() async {
    try {
      for (Socket socket in channels) {
        await socket.close();
      }
    } catch (e) {
      print(e);
    }
    devicesNames.clear();
    switchState.clear();
    sensorsNames.clear();
    sensorsValues.clear();
    channels.clear();
    deviceToChannel.clear();
    channelsStream.clear();
  }
}

class MyApp extends StatelessWidget {
  List<Room> rooms;

  MyApp({Key? key, required this.rooms}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    print("myapp build");
    const title = 'Smart Home';
    return MaterialApp(
      title: title,
      home: HomePage(
        rooms: rooms,
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  List<Room> rooms;
  bool isDelete = false;

  HomePage({Key? key, required this.rooms}) : super(key: key) {}

  @override
  _HomePageState createState() {
    return _HomePageState();
  }
}

class _HomePageState extends State<HomePage> {
  TextEditingController roomName = TextEditingController();
  TextEditingController roomIPs = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Smart Home"),
        actions: widget.isDelete
            ? [
                IconButton(
                  icon: Icon(
                    Icons.done,
                  ),
                  iconSize: 30,
                  onPressed: () {
                    setState(() {
                      widget.isDelete = false;
                    });
                  },
                )
              ]
            : null,
      ),
      body: GridView(
        gridDelegate:
            const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2),
        children: widget.isDelete
            ? getDeletableHomeButtons(context)
            : getHomeButtons(context),
        physics: const ScrollPhysics(),
      ),
      floatingActionButton: Row(
        children: widget.isDelete ? [] : getFloatingButtons(),
        mainAxisSize: MainAxisSize.min,
      ),
    );
  }

  List<Widget> getFloatingButtons() {
    List<Widget> buttons = [];
    if (widget.rooms.isNotEmpty) {
      buttons.addAll([
        FloatingActionButton(
          onPressed: () {
            setState(() {
              widget.isDelete = true;
            });
          },
          backgroundColor: Colors.red,
          child: const Icon(Icons.delete),
          heroTag: "deletBtn",
        ),
        SizedBox(
          width: 20,
        ),
      ]);
    }

    buttons.add(FloatingActionButton(
      onPressed: () {
        roomName.clear();
        roomIPs.clear();
        showDialog(
            context: context,
            builder: (context) {
              bool buttonEnable = false;
              bool isNameEmpty = true;
              bool isIPEmpty = true;
              return StatefulBuilder(
                builder: (BuildContext context,
                    void Function(void Function()) setDialogState) {
                  return Dialog(
                    child: Container(
                      height: 200,
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Text(
                                "Room Name: ",
                                style: TextStyle(fontSize: 16),
                              ),
                              Flexible(
                                child: TextField(
                                  onChanged: (val) {
                                    isNameEmpty = val.isEmpty;
                                    setDialogState(() {
                                      buttonEnable = !isNameEmpty && !isIPEmpty;
                                    });
                                  },
                                  controller: roomName,
                                  style: TextStyle(fontSize: 16),
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Text(
                                "Modules IPs: ",
                                style: TextStyle(fontSize: 16),
                              ),
                              Flexible(
                                child: TextField(
                                  onChanged: (val) {
                                    isIPEmpty = val.isEmpty;
                                    setDialogState(() {
                                      buttonEnable = !isNameEmpty && !isIPEmpty;
                                    });
                                  },
                                  controller: roomIPs,
                                  maxLines: 3,
                                  minLines: 1,
                                  style: TextStyle(fontSize: 16),
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              ElevatedButton(
                                child: const Text("Cancel"),
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                              ),
                              ElevatedButton(
                                child: Text("Save"),
                                onPressed: buttonEnable
                                    ? () {
                                        Room newRoom = Room(roomName.text);
                                        newRoom.channelsIPs =
                                            roomIPs.text.split("\n");
                                        updateRoomsFile(newRoom);
                                        Navigator.pop(context);
                                        setState(() {
                                          widget.rooms.add(newRoom);
                                        });
                                      }
                                    : null,
                              ),
                            ],
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          ),
                        ],
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      ),
                      margin: const EdgeInsets.all(20),
                    ),
                  );
                },
              );
            });
      },
      backgroundColor: Colors.blue,
      child: const Icon(Icons.add),
      heroTag: "addBtn",
    ));

    return buttons;
  }

  List<HomeButton> getHomeButtons(BuildContext context) {
    List<HomeButton> buttons = [];
    for (Room room in widget.rooms) {
      buttons.add(HomeButton(
        image: room.image,
        text: room.roomName,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => RoomScreen(
                      room: room,
                    )),
          );
        },
        fontSize: 18,
      ));
    }
    return buttons;
  }

  List<HomeButtonDeletable> getDeletableHomeButtons(BuildContext context) {
    List<HomeButtonDeletable> buttons = [];
    for (Room room in widget.rooms) {
      buttons.add(HomeButtonDeletable(
        image: room.image,
        text: room.roomName,
        onTap: () {
          setState(() {
            widget.rooms.remove(room);
            saveRoomsFile();
          });
        },
        fontSize: 18,
      ));
    }
    return buttons;
  }

  void updateRoomsFile(Room room) async {
    final directory = await getApplicationDocumentsDirectory();
    final File file = File('${directory.path}/rooms.txt');
    await file.writeAsString(room.roomName + "#", mode: FileMode.append);
    for (String IP in room.channelsIPs) {
      await file.writeAsString(IP + "#", mode: FileMode.append);
    }
  }

  void saveRoomsFile() async {
    final directory = await getApplicationDocumentsDirectory();
    final File file = File('${directory.path}/rooms.txt');
    await file.delete();
    for (Room room in widget.rooms) {
      await file.writeAsString(room.roomName + "#", mode: FileMode.append);
      for (String IP in room.channelsIPs) {
        await file.writeAsString(IP + "#", mode: FileMode.append);
      }
    }
  }
}
