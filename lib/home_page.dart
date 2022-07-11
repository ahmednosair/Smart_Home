import 'package:flutter/material.dart';

import 'home_button.dart';
import 'room.dart';
import 'room_screen.dart';

class HomePage extends StatefulWidget {
  final List<Room> rooms;
  final Function() loadRooms;
  const HomePage({Key? key, required this.rooms, required this.loadRooms}) : super(key: key);

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
                  room: room,loadRooms:widget.loadRooms,
                )),
          );
        },
        fontSize: 18,
      ));
    }
    return buttons;
  }

}
