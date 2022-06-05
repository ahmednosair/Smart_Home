import 'package:avatar_glow/avatar_glow.dart';
import 'package:speech_to_text/speech_to_text.dart';

import 'package:flutter/material.dart';

import 'room.dart';


class VoiceInterface extends StatefulWidget {
  final Room room;

  const VoiceInterface({Key? key, required this.room}) : super(key: key);

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
            if (widget.room.executeVoiceCommand(value.recognizedWords)) {
              widget.room.switchesBoxSetState!(() {});
            }
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
    return SizedBox(
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
    );
  }
}
