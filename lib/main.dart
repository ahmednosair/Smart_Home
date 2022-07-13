import 'package:flutter/material.dart';
import 'package:graduation_project/config_page.dart';
import 'home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp( MaterialApp(
    home:  MyApp(),
  ));
}

class MyApp extends StatelessWidget {
    MyApp({Key? key}) : super(key: key);
  final List<void Function()> callBacks = [];

  void setLoadRooms(void Function() fn) {
    callBacks.clear();
    callBacks.add(fn);
  }

  void Function()? getLoadRooms(){
    if(callBacks.isNotEmpty){
      return callBacks[0];
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          bottom: const TabBar(
            tabs: [
              Tab(
                icon: Icon(Icons.home),
              ),
              Tab(icon: Icon(Icons.settings)),
            ],
          ),
          title: const Text('Smart Home'),
          actions: [
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: () {
                showDialog<String>(
                  context: context,
                  builder: (BuildContext context) => AlertDialog(
                    title: const Text('How to use'),
                    content: const SingleChildScrollView(child: Text(
                        "- Connect to the module hotspot named \"Smart Home Module\""
                            ".\n\n- Head to the configuration tab to configure the module"
                            ".\n\n- The home tab contains the rooms buttons"
                            ".\n\n- Inside each room, there are devices to control and sensors readings if exist"
                            ".\n\n- The button with mic icon can be used to control devices using voice."),),
                    actions: <Widget>[
                      TextButton(
                        onPressed: () => Navigator.pop(context, 'OK'),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
        body: TabBarView(
          children: [
            HomePage(
              setParentLoadRooms: setLoadRooms,
            ),
            ConfigPage(
              getLoadRooms: getLoadRooms,
            ),
          ],
        ),
      ),
    );
  }
}
