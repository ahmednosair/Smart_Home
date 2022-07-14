import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

class ConfigPage extends StatefulWidget {

   const ConfigPage({Key? key, required this.getLoadRooms}) : super(key: key);
  final Function()? Function() getLoadRooms;
  @override
  State<StatefulWidget> createState() {
    return _ConfigPageState();
  }
}

class _ConfigPageState extends State<ConfigPage> with AutomaticKeepAliveClientMixin{
  final formKey = GlobalKey<FormState>();
  StreamSubscription? sub ;
  String wifiName = "";
  String wifiPassword = "";
  String roomName = "";
  String dev1 = "";
  String dev2 = "";
  String dev3 = "";
  String dev4 = "";
  bool isObscure = true;


  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      body: Form(
        autovalidateMode: AutovalidateMode.onUserInteraction,
        key: formKey,
        child: ListView(
          children: [
            TextFormField(
              decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.wifi),
                  labelText: "WiFi name",
                  border: OutlineInputBorder()),
              validator: (value) {
                if (value != null && value.length > 50) {
                  return "Enter max. 50 characters";
                } else if (value != null && value.isEmpty) {
                  return "WiFi name required";
                } else {
                  return null;
                }
              },
              onChanged: (value) {
                wifiName = value;
              },
            ),
            const SizedBox(
              height: 10,
            ),
            TextFormField(
              obscureText: isObscure,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.lock),
                labelText: "WiFi password",
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    isObscure ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      isObscure = !isObscure;
                    });
                  },
                ),
              ),
              validator: (value) {
                if (value != null && value.length > 50) {
                  return "Enter max. 50 characters";
                } else if (value != null && value.isEmpty) {
                  return "WiFi password required";
                } else {
                  return null;
                }
              },
              onChanged: (value) {
                wifiPassword = value;
              },
            ),
            const SizedBox(
              height: 10,
            ),
            TextFormField(
              decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.meeting_room),
                  labelText: "Room name",
                  border: OutlineInputBorder()),
              validator: (value) {
                if (value != null && value.length > 40) {
                  return "Enter max. 40 characters";
                } else if (value != null && value.isEmpty) {
                  return "Room name required";
                } else {
                  return null;
                }
              },
              onChanged: (value) {
                roomName = value;
              },
            ),
            const SizedBox(
              height: 10,
            ),
            TextFormField(
              decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.electrical_services),
                  labelText: "Device 1 name",
                  border: OutlineInputBorder()),
              validator: (value) {
                if (value != null && value.length > 30) {
                  return "Enter max. 30 characters";
                } else if (value != null &&
                    value.isNotEmpty &&
                    (value == dev2 || value == dev3 || value == dev4)) {
                  return "Enter unique device names";
                } else {
                  return null;
                }
              },
              onChanged: (value) {
                dev1 = value;
              },
            ),
            const SizedBox(
              height: 10,
            ),
            TextFormField(
              decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.electrical_services),
                  labelText: "Device 2 name",
                  border: OutlineInputBorder()),
              validator: (value) {
                if (value != null && value.length > 30) {
                  return "Enter max. 30 characters";
                } else if (value != null &&
                    value.isNotEmpty &&
                    (value == dev1 || value == dev3 || value == dev4)) {
                  return "Enter unique device names";
                } else {
                  return null;
                }
              },
              onChanged: (value) {
                dev2 = value;
              },
            ),
            const SizedBox(
              height: 10,
            ),
            TextFormField(
              decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.electrical_services),
                  labelText: "Device 3 name",
                  border: OutlineInputBorder()),
              validator: (value) {
                if (value != null && value.length > 30) {
                  return "Enter max. 30 characters";
                } else if (value != null &&
                    value.isNotEmpty &&
                    (value == dev1 || value == dev2 || value == dev4)) {
                  return "Enter unique device names";
                } else {
                  return null;
                }
              },
              onChanged: (value) {
                dev3 = value;
              },
            ),
            const SizedBox(
              height: 10,
            ),
            TextFormField(
              decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.electrical_services),
                  labelText: "Device 4 name",
                  border: OutlineInputBorder()),
              validator: (value) {
                if (value != null && value.length > 30) {
                  return "Enter max. 30 characters";
                } else if (value != null &&
                    value.isNotEmpty &&
                    (value == dev1 || value == dev2 || value == dev3)) {
                  return "Enter unique device names";
                } else {
                  return null;
                }
              },
              onChanged: (value) {
                dev4 = value;
              },
            ),
            const SizedBox(
              height: 15,
            ),
            ElevatedButton(
                onPressed: () {
                  final bool isValidForm = formKey.currentState!.validate();
                  if (isValidForm) {
                    configure();
                  }
                },
                child: const Text(
                  "Configure",
                  style: TextStyle(fontSize: 18),
                )),
          ],
          padding: const EdgeInsets.all(20),
        ),
      ),
    );
  }

  void configure() {
    FocusScope.of(context).unfocus();
    showDialog(
        barrierDismissible: false,
        context: context,
        builder: (_) {
          return Dialog(
            // The background color
            backgroundColor: Colors.white,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  // The loading indicator
                  CircularProgressIndicator(),
                  SizedBox(
                    height: 15,
                  ),
                  // Some text
                  Text('Configuring...')
                ],
              ),
            ),
          );
        });
    Socket.connect("192.168.4.1", 55555,timeout: const Duration(seconds: 3)).then((sock) async{
      sock.write(roomName +
          "#" +
          wifiName +
          "#" +
          wifiPassword +
          "#" +
          dev1 +
          "#" +
          dev2 +
          "#" +
          dev3 +
          "#" +
          dev4 +
          "#");
      await sock.flush();
      Future.delayed(const Duration(seconds: 7),(){
        sock.close();
        widget.getLoadRooms()!();
        Navigator.of(context).pop();
        showDialog<String>(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            title: const Text('Configuration'),
            content: const Text('Configuration sent to the module, if success the module AP should disappear'),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(context, 'OK'),
                child: const Text('OK'),
              ),
            ],
          ),
        );

      });

      //Received
    }).onError((error, stackTrace){
      //Make Sure
      Navigator.of(context).pop();
      showDialog<String>(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: const Text('Configuration'),
          content: const Text("Can't send configuration to the module, please make sure to connect to the module AP"),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context, 'OK'),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    });

  }

  @override
  bool get wantKeepAlive => true;
}
