// ignore_for_file: prefer_const_literals_to_create_immutables, prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations(
    [
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ],
  );
  runApp(MyApp());
}

ThemeData _lightTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
);

ThemeData _darkTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.indigo,
    brightness: Brightness.dark,
  ),
);

var tts_delay = 5;
var tts_word_repeat = 2;
var tts_speech_rate = 0.5;
var cTheme = true;
var listShuffle = false;


class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Brightness currentBrightness = MediaQuery.of(context).platformBrightness;
    if (currentBrightness == Brightness.light) {
      cTheme = false;
    } else {
      cTheme = true;
    }
    return MaterialApp(
      theme: cTheme ? _darkTheme : _lightTheme,
      debugShowCheckedModeBanner: false,
      home: MainSt(),
    );
  }
}

class MainSt extends StatefulWidget {
  const MainSt({Key? key}) : super(key: key);

  @override
  State<MainSt> createState() => _MainStState();
}

final addController = TextEditingController();
List<String> cardsList = [];

class _MainStState extends State<MainSt> {
  FlutterTts flutterTts = FlutterTts();
  bool isPlaying = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadWordsList();
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('About'),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Image(
                image: AssetImage("assets/icon/icon.png"),
                width: 200,
              ),
              Text(
                "Wordly",
                style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
              ),
              Text(
                "Wordly - Your Smart Dictation Study Buddy",
                style: TextStyle(fontSize: 10),
              ),
              SizedBox(height: 10,),
              Text(
                "Version : 1.1",
                style: TextStyle(fontSize: 10),
              ),
              Text(
                "Developer : Mohamed Elsayed",
                style: TextStyle(fontSize: 10),
              ),
                            SizedBox(height: 10,),

              ElevatedButton(
                onPressed: () {
                  launch('https://sites.google.com/view/mohamed-elsayed-programmer');
                },
                child: Text("User's Guide"),
              )
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _loadSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      tts_speech_rate = prefs.getDouble('tts_speech_rate') ?? 0.5;
      tts_delay = prefs.getInt('tts_delay') ?? 5;
      tts_word_repeat = prefs.getInt('tts_word_repeat') ?? 2;
      listShuffle = prefs.getBool('list_shuffle') ?? false;
    });
  }

  Future<void> _loadWordsList() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      cardsList = prefs.getStringList('cards_list') ?? [];
    });
  }

  Future<void> _saveSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setDouble('tts_speech_rate', tts_speech_rate);
    prefs.setInt('tts_delay', tts_delay);
    prefs.setInt('tts_word_repeat', tts_word_repeat);
    prefs.setBool('list_shuffle', listShuffle);
  }

  Future<void> _saveWordsList() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setStringList('cards_list', cardsList);
  }

  Future<void> textToSpeech(String text) async {
    await flutterTts.setLanguage("en-US");
    await flutterTts.setVolume(0.5);
    await flutterTts.setSpeechRate(tts_speech_rate);
    await flutterTts.setPitch(1);
    await flutterTts.speak(text);
  }

  Future<void> playAllPhrases() async {
    isPlaying = false;
    isPlaying = true;

    List<String> tempCardsList = List.from(cardsList);

    if (listShuffle == true) {
      tempCardsList = tempCardsList..shuffle();
    }

    for (String phrase in tempCardsList) {
      if (!isPlaying) break;
      for (int word = 0; word < tts_word_repeat; word++) {
        if (!isPlaying) break;
        await textToSpeech(phrase);
        await Future.delayed(Duration(seconds: tts_delay));
      }
    }
  }

  Future<void> _dialogBuilder(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add a word or phrase'),
          content: TextField(
            controller: addController,
            decoration: const InputDecoration(
              border: UnderlineInputBorder(),
              labelText: 'Enter word or phrase',
            ),
          ),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                textStyle: Theme.of(context).textTheme.labelLarge,
              ),
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
                addController.clear();
              },
            ),
            TextButton(
              style: TextButton.styleFrom(
                textStyle: Theme.of(context).textTheme.labelLarge,
              ),
              child: const Text('Done'),
              onPressed: () {
                print(addController.text);
                setState(() {
                  if (!(addController.text.trim().isEmpty)) {
                    cardsList.add(addController.text);
                    addController.clear();
                    Navigator.of(context).pop();
                    _saveWordsList(); // Save the words list after adding a word
                  } else {
                    addController.clear();
                  }
                });
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showSettingsDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Settings'),
          content: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                Text('Speech Rate'),
                StatefulBuilder(
                  builder: (context, state) {
                    return Slider(
                      value: tts_speech_rate,
                      min: 0.1,
                      max: 1.0,
                      divisions: 10,
                      label: (tts_speech_rate * 10).round().toString(),
                      onChanged: (double value) {
                        state(() {});
                        setState(() {
                          tts_speech_rate = value;
                          _saveSettings(); // Save the settings when the user closes the dialog
                        });
                      },
                    );
                  },
                ),
                Text('Delay Between Words (seconds)'),
                StatefulBuilder(
                  builder: (context, state) {
                    return Slider(
                      value: tts_delay.toDouble(),
                      min: 1,
                      max: 30,
                      divisions: 30,
                      label: (tts_delay).toString(),
                      onChanged: (double value) {
                        state(() {});
                        setState(() {
                          tts_delay = value.toInt();
                          _saveSettings(); // Save the settings when the user closes the dialog
                        });
                      },
                    );
                  },
                ),
                Text('Word Repeat'),
                StatefulBuilder(
                  builder: (context, state) {
                    return Slider(
                      value: tts_word_repeat.toDouble(),
                      min: 1,
                      max: 10,
                      divisions: 10,
                      label: (tts_word_repeat).toString(),
                      onChanged: (double value) {
                        state(() {});
                        setState(() {
                          tts_word_repeat = value.toInt();
                          _saveSettings(); // Save the settings when the user closes the dialog
                        });
                      },
                    );
                  },
                ),
                Text('Shuffle Words'),
                StatefulBuilder(
                  builder: (context, state) {
                    return Switch(
                      value: listShuffle,
                      onChanged: (bool value) {
                        state(() {});
                        setState(() {
                          listShuffle = value;
                          _saveSettings(); // Save the settings when the user closes the dialog
                        });
                      },
                    );
                  },
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Done'),
              onPressed: () {
                Navigator.of(context).pop();
                _saveSettings(); // Save the settings when the user closes the dialog
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text('Wordly'),
              PopupMenuButton<String>(
                onSelected: (String value) {
                  if (value == 'settings') {
                    _showSettingsDialog();
                  } else if (value == 'about') {
                    _showAboutDialog(context);
                  }
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                    value: 'settings',
                    child: ListTile(
                      leading: Icon(Icons.settings),
                      title: Text('Settings'),
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'about',
                    child: ListTile(
                      leading: Icon(Icons.info),
                      title: Text('About'),
                    ),
                  ),
                ],
                icon: Icon(Icons.more_vert),
              ),
            ],
          ),
        ),
        floatingActionButton: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FloatingActionButton(
              child: Icon(Icons.add),
              onPressed: () {
                _dialogBuilder(context);
              },
            ),
            SizedBox(
              height: 10,
            ),
            FloatingActionButton(
              child: Icon(Icons.volume_up_outlined),
              onPressed: () {
                playAllPhrases();
              },
            ),
            SizedBox(
              height: 10,
            ),
            FloatingActionButton(
              child: Icon(Icons.stop_circle),
              onPressed: () {
                setState(() {
                  isPlaying = false;
                });
              },
            ),
          ],
        ),
        body: HomePage(),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Future<void> _saveWordsList() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setStringList('cards_list', cardsList);
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: cardsList.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 5),
          child: Card(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () {
                      setState(() {
                        cardsList.removeAt(index);
                        _saveWordsList(); // Save the words list after deleting a word
                      });
                    },
                  ),
                  title: Row(
                    children: [
                      Text(cardsList[index]),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
