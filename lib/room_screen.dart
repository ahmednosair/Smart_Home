import 'package:flutter/material.dart';

import 'room.dart';
import 'sensors_box.dart';
import 'switches_box.dart';
import 'voice_interface.dart';

class RoomScreen extends StatelessWidget {
  final Room room;
  final Function() loadRooms;

  const RoomScreen({Key? key, required this.room, required this.loadRooms}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(room.roomName),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            children: [
              SwitchesBox(room: room,loadRooms: loadRooms,),
              const SizedBox(
                height: 30,
              ),
              SensorsBox(room: room),
            ],
            mainAxisAlignment: MainAxisAlignment.center,
          ),
        ),
      ),
      bottomNavigationBar: VoiceInterface(room: room),
    );
  }

}
