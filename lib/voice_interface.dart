import 'package:avatar_glow/avatar_glow.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_to_text.dart';

import 'package:flutter/material.dart';

import 'room.dart';

class VoiceInterface extends StatefulWidget {
  final Room room;
  final SpeechToText speech = SpeechToText();

  VoiceInterface({
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

  @override
  void initState() {
    super.initState();
    widget.speech.initialize();
  }

  void listen() async {
    if (!isListen) {
      if (widget.speech.isAvailable) {
        setState(() {
          isListen = true;
        });
        widget.speech.listen(onResult: (value) {
          if (value.finalResult) {
            widget.speech.stop();
            setState(() {
              isListen = false;
            });
            widget.room
                .executeVoiceCommand(value.recognizedWords)
                .then((result) {
              if (result.isNotEmpty) {
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
            }).timeout(const Duration(seconds: 10), onTimeout: () {
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
      await widget.speech.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return RawKeyboardListener(
        autofocus: true,
        focusNode: FocusNode(),
        onKey: (event) {
          if (event.isKeyPressed(LogicalKeyboardKey.headsetHook)) {
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
