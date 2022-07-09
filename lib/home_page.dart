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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
