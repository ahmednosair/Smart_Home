import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'home_button.dart';
import 'room.dart';
import 'room_screen.dart';

class HomePage extends StatefulWidget {
  final List<Room> rooms;

  const HomePage({Key? key, required this.rooms}) : super(key: key);

  @override
  _HomePageState createState() {
    return _HomePageState();
  }
}

class _HomePageState extends State<HomePage> {
  TextEditingController roomName = TextEditingController();
  TextEditingController roomIPs = TextEditingController();
  bool isEdit = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Smart Home"),
        actions: isEdit
            ? [
          IconButton(
            icon: const Icon(
              Icons.done,
            ),
            iconSize: 30,
            onPressed: () {
              setState(() {
                isEdit = false;
              });
            },
          )
        ]
            : null,
      ),
      body: GridView(
        gridDelegate:
        const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2),
        children: isEdit
            ? getEditableHomeButtons(context)
            : getHomeButtons(context),
        physics: const ScrollPhysics(),
      ),
      floatingActionButton: Row(
        children: isEdit ? [] : getFloatingButtons(),
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
              isEdit = true;
            });
          },
          backgroundColor: Colors.blue,
          child: const Icon(Icons.edit),
          heroTag: "deleteBtn",
        ),
        const SizedBox(
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
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              const Text(
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
                                  style: const TextStyle(fontSize: 16),
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
                                child: const Text("Save"),
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

  List<HomeButtonEditable> getEditableHomeButtons(BuildContext context) {
    List<HomeButtonEditable> buttons = [];
    for (Room room in widget.rooms) {
      buttons.add(HomeButtonEditable(
        image: room.image,
        text: room.roomName,
        deleteOnTap: () {
          showAlertDialog(
              context,
              "No",
              "Yes",
              "Would you like to delete this room?",
                  () => {Navigator.pop(context)}, () {
            Navigator.pop(context);
            setState(() {
              widget.rooms.remove(room);
              saveRoomsFile();
            });
          });
        },
        editOnTap: (){
          roomName.text = room.roomName;
          roomIPs.text = room.getIPs();
          showDialog(
              context: context,
              builder: (context) {
                bool buttonEnable = true;
                bool isNameEmpty = false;
                bool isIPEmpty = false;
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
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                const Text(
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
                                    style: const TextStyle(fontSize: 16),
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
                                  child: const Text("Save"),
                                  onPressed: buttonEnable
                                      ? () {
                                    setState(() {
                                      room.updateRoomDetails( roomName.text, roomIPs.text.split("\n"));
                                    });
                                    saveRoomsFile();
                                    Navigator.pop(context);
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
        fontSize: 18,
      ));
    }
    return buttons;
  }

  void updateRoomsFile(Room room) async {
    final directory = await getApplicationDocumentsDirectory();
    final File file = File('${directory.path}/rooms.txt');
    await file.writeAsString(room.roomName + "#", mode: FileMode.append);
    for (String ip in room.channelsIPs) {
      await file.writeAsString(ip + "#", mode: FileMode.append);
    }
  }

  void saveRoomsFile() async {
    final directory = await getApplicationDocumentsDirectory();
    final File file = File('${directory.path}/rooms.txt');
    await file.delete();
    for (Room room in widget.rooms) {
      await file.writeAsString(room.roomName + "#", mode: FileMode.append);
      for (String ip in room.channelsIPs) {
        await file.writeAsString(ip + "#", mode: FileMode.append);
      }
    }
  }

  showAlertDialog(BuildContext context, String button1, String button2,
      String msg, Function()? button1OnPressed, Function()? button2OnPressed) {
    Widget cancelButton = TextButton(
      child: Text(button1),
      onPressed: button1OnPressed,
    );
    Widget continueButton = TextButton(
      child: Text(button2),
      onPressed: button2OnPressed,
    );

    AlertDialog alert = AlertDialog(
      title: const Text("Confirmation"),
      content: Text(msg),
      actions: [
        cancelButton,
        continueButton,
      ],
    );
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }
}
