import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:mutex/mutex.dart';

class Room {
  String image = "";
  String roomName = "";
  List<String> devicesNames = [];
  List<Socket> channels = [];
  Map<String, int> deviceToChannel = {};
  Map<String, int> deviceToIndex = {};
  List<bool> switchState = [];
  void Function(void Function())? switchesBoxSetState;
  void Function(void Function())? sensorBoxSetState;
  List<String> sensorsNames = [];
  List<String> sensorsValues = [];
  Map<String, int> sensorToIndex = {};
  final List<StreamSubscription> subs = [];
  final List<StringBuffer> buffs = [];
  final Map<int, int> ack = {};
  final List<Mutex> buffMutexes = [];

  Room(String name) {
    roomName = name;
    image = assignImg(name);
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

  Future<bool> sendCommand(String device, String command) async {
    int index = deviceToChannel[device] as int;
    try {
      channels[index].write(device + "#" + command + "\n");
      await (channels[index].flush());
      int timeOut = 0;
      while (ack[index]! <= 0 && timeOut < 8) {
        await Future.delayed(const Duration(seconds: 1));
        timeOut++;
      }
      if (timeOut == 8) {
        return false;
      }
      ack[index] = (ack[index]! - 1);
    } catch (e) {
      return false;
    }
    return true;
  }

  String literalToNum(String literal) {
    switch (literal) {
      case 'one':
        return "1";

      case 'two':
        return "2";

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

  Future<String> executeVoiceCommand(String command) async {
    String raw = command.toLowerCase();
    List<String> tokens = raw.split(" ");
    if (tokens.length < 2) {
      return "Wrong command.\nAllowed commands are turn on or turn off followed by the device name.";
    }
    String cmd = tokens[0] + tokens[1];
    switch (cmd) {
      case 'turnon':
        cmd = "ON";
        break;
      case 'turnoff':
        cmd = "OFF";
        break;
      default:
        return "Wrong command.\nAllowed commands are turn on or turn off followed by the device name.";
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
      return "Unknown device";
    }
    switchState[deviceToIndex[dev] as int] = (cmd == "ON");
    switchesBoxSetState!(() {});
    bool success = await sendCommand(dev, cmd);
    if (success) {
      return "";
    }
    return "Can't send command to the module\nPlease sure that you are connected to the WiFi or try to restart the application";
  }

  void updateSwitchesBox(void Function() fo) {
    if (switchesBoxSetState == null) {
      fo();
    } else {
      switchesBoxSetState!(fo);
    }
  }

  void updateSensorsBox(void Function() fo) {
    if (sensorBoxSetState == null) {
      fo();
    } else {
      sensorBoxSetState!(fo);
    }
  }

  void dispose() async {
    for (Socket socket in channels) {
      try {
        socket.close();
      } catch (e) {
        if (kDebugMode) {
          print("Closing a bad socket");
        }
      }
    }
    for (StreamSubscription sub in subs) {
      sub.cancel();
    }
    devicesNames.clear();
    switchState.clear();
    sensorsNames.clear();
    sensorsValues.clear();
    sensorToIndex.clear();
    channels.clear();
    deviceToChannel.clear();
    buffs.clear();
    subs.clear();
    ack.clear();
  }
}
