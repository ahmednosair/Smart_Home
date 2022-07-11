import 'package:avatar_glow/avatar_glow.dart';
import 'package:flutter/services.dart';
import 'package:graduation_project/room_screen.dart';
import 'package:speech_to_text/speech_to_text.dart';

import 'package:flutter/material.dart';

import 'room.dart';

class VoiceInterface extends StatefulWidget {
  final Room room;

  const VoiceInterface({
    Key? key,
    required this.room,
  }) : super(key: key);

  @override
  _VoiceInterfaceState createState() {
    return _VoiceInterfaceState();
  }
}

class _VoiceInterfaceState extends State<VoiceInterface> {
  bool isListen = false;
  SpeechToText speech = SpeechToText();

  void listen() async {
    await speech.initialize(onStatus: (status) {
      if (status == "done") {
        setState(() {
          isListen = false;
        });
        speech.stop();
      }
    });

    if (!isListen) {
      if (speech.isAvailable) {
        setState(() {
          isListen = true;
        });
        speech.listen(onResult: (value) {
          if (value.finalResult) {
            widget.room
                .executeVoiceCommand(value.recognizedWords)
                .then((result) {
              if (result.isEmpty) {
                widget.room.switchesBoxSetState!(() {});
              } else {
                showDialog<String>(
                  context: context,
                  builder: (BuildContext context) => AlertDialog(
                    title: const Text('Error'),
                    content: Text(result),
                    actions: <Widget>[
                      TextButton(
                        onPressed: () => Navigator.pop(context, 'OK'),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
              }
            }).timeout(const Duration(seconds: 2), onTimeout: () {
              showDialog<String>(
                context: context,
                builder: (BuildContext context) => AlertDialog(
                  title: const Text('Error'),
                  content: const Text(
                      "Can't send command to the module\nPlease sure that you are connected to the WiFi or try to restart the application"),
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
        });
      }
    } else {
      setState(() {
        isListen = false;
      });
      speech.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return RawKeyboardListener(autofocus: true,
        focusNode: FocusNode(),
        onKey: (event) {
        if(event.isKeyPressed(LogicalKeyboardKey.headsetHook)){
          listen();
        }

        },
        child: SizedBox(
          child: AvatarGlow(
            animate: isListen,
            glowColor: Colors.red,
            endRadius: 65.0,
            duration: const Duration(milliseconds: 2000),
            repeatPauseDuration: const Duration(milliseconds: 100),
            repeat: true,
            child: FloatingActionButton(
              child: Icon(isListen ? Icons.mic : Icons.mic_none),
              onPressed: () {
                listen();
              },
            ),
          ),
          height: 70,
        ));
  }
}
