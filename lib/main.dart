import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'api.rating',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'api.rating app')
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

enum Body {
  main,
  teams
}

class _MyHomePageState extends State<MyHomePage> {
  Body body = Body.main;
  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text(
                'Drawer Header',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              title: const Text('Main'),
              onTap: () {
                setState(() {
                  body = Body.main;
                });
                Navigator.pop(context); // close the drawer
              },
            ),
            ListTile(
              title: const Text('Teams'),
              onTap: () {
                setState(() {
                  body = Body.teams;
                });
                Navigator.pop(context); // close the drawer
              },
            ),
          ],
        ),
      ),
      body: GetBody(body),
    );
  }

  Widget GetBody(Body body) {
    if (body == Body.main) {
      return const Text('Main body');
    }
    if (body == Body.teams) {
      return const TeamsList();
    }
    return const Text('Not reached');
  }
}

class ApiItem {
  final String globalId;
  final String type;
  const ApiItem(this.globalId, this.type);
  factory ApiItem.fromJson(Map<String, dynamic> json) {
    String globalId = json["@id"];
    String type = json["@type"];

    switch (type) {
      case Team.jsonType:
        return Team(globalId, json["id"], json["name"], ApiItem.fromJson(json["town"]) as Town);
      case Town.jsonType:
        return Town(globalId, json["id"], json["name"]);
    }
    return ApiItem(globalId, type);
  }
}

class Team extends ApiItem {
  static const String jsonType = "Team";
  final int id;
  final String name;
  final Town town;
  const Team(String globalId, this.id, this.name, this.town) : super(globalId, jsonType);
}

class Town extends ApiItem {
  static const String jsonType = "Town";
  final int id;
  final String name;
  const Town(String globalId, this.id, this.name) : super(globalId, jsonType);
}

class TeamsHttpService {
  Future<List<Team>> listTeams() async {
    final response = await http.get(Uri.https('api.rating.chgk.net', '/teams',
        {'page': '1', 'itemsPerPage' : '70', 'town': '205'}));

    if (response.statusCode == 200) {
      var result = json.decode(response.body);
      return List.generate(result['hydra:member'].length, (i) {
        return ApiItem.fromJson(result['hydra:member'][i]) as Team;
      });
    } else {
      // If the server did not return a 200 OK response,
      // then throw an exception.
      throw Exception('Failed to load teams');
    }
  }
}

class TeamsList extends StatefulWidget {
  const TeamsList({Key? key}) : super(key: key);

  @override
  State<TeamsList> createState() => _TeamsListState();
}

class _TeamsListState extends State<TeamsList> {
  final _biggerFont = const TextStyle(fontSize: 18);
  Future<List<Team>>? _future;
  final teamHttpService = TeamsHttpService();

  @override
  void initState() {
    super.initState();
    _future = teamHttpService.listTeams();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Team>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return ListView.builder(
                itemCount: snapshot.requireData.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(
                      snapshot.requireData[index].name,
                      style: _biggerFont,
                    ),
                    subtitle: Text(
                      snapshot.requireData[index].town.name,
                    ),
                  );
                }
            );
          }
          if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          }
          return const CircularProgressIndicator();
        }
    );
  }
}