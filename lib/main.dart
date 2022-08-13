import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:endless/endless.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:developer' as developer;

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
  teams,
  towns,
  countries,
}

class _MyHomePageState extends State<MyHomePage> {
  Body body = Body.teams;
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
            ListTile(
              title: const Text('Towns'),
              onTap: () {
                setState(() {
                  body = Body.towns;
                });
                Navigator.pop(context); // close the drawer
              },
            ),
            ListTile(
              title: const Text('Countries'),
              onTap: () {
                setState(() {
                  body = Body.countries;
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
    if (body == Body.towns) {
      return const ApiItemList<Town>();
    }
    if (body == Body.countries) {
      return const ApiItemList<Country>();
    }
    return const Text('Not reached');
  }
}

class ApiItem {
  final String globalId;
  final String type;
  final int id;
  final String name;
  ApiItem(Map<String, dynamic> json) :
        globalId = json['@id'],
        type = json['@type'],
        id = json['id'],
        name = json['name'];
  factory ApiItem.fromJson(Map<String, dynamic> json) {
    String type = json["@type"];
    switch (type) {
      case Team.jsonType:
        return Team(json);
      case Town.jsonType:
        return Town(json);
      case Country.jsonType:
        return Country(json);
    }
    return ApiItem(json);
  }
}

class Team extends ApiItem {
  static const String jsonType = "Team";
  final Town town;
  final Country country;
  Team(Map<String, dynamic> json) :
        town = Town(json['town']),
        country = Country(json['country']),
        super(json);
}

class Town extends ApiItem {
  static const String jsonType = "Town";
  Town(Map<String, dynamic> json) : super(json);
}

class Country extends ApiItem {
  static const String jsonType = "Country";
  Country(Map<String, dynamic> json) : super(json);
}

String apiMethod<T>() {
  if (T == Team) {
    return "teams";
  }
  if (T == Town) {
    return "towns";
  }
  if (T == Country) {
    return "countries";
  }
  throw Exception("Not reached");
}

class TeamsHttpService {
  static const apiAddress = 'api.rating.chgk.net';
  static const apiUrl = 'https://$apiAddress';
  static const hydraViewKey = 'hydra:view';
  static const hydraNextKey = 'hydra:next';
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

  Future<List<T>> getPage<T extends ApiItem>(String method, int page, int itemsPerPage) async {
    final response = await http.get(Uri.https(apiAddress, '/$method',
        {'page': page.toString(), 'itemsPerPage' : itemsPerPage.toString()}));
    if (response.statusCode != 200) {
      throw Exception('Failed to load $method');
    }
    final result = json.decode(response.body);
    return List.generate(result['hydra:member'].length, (i) {
        return ApiItem.fromJson(result['hydra:member'][i]) as T;
    });
  }

  Stream<ApiItem> ratingStream(String path) async* {
    final response = await http.get(Uri.parse(apiUrl+path));
    if (response.statusCode != 200) {
      throw Exception('Failed to load $path');
    }
    final result = json.decode(response.body);
    for (var jsonItem in result['hydra:member']) {
      yield ApiItem.fromJson(jsonItem);
    }

    final Map<String, dynamic> hydraView = result[hydraViewKey];
    if (!hydraView.containsKey(hydraNextKey)) {
      return;
    }
    yield* ratingStream(hydraView[hydraNextKey]);
  }

  Stream<Team> teamsStream() async* {
    await for (final team in ratingStream('/teams?itemsPerPage=30&page=1')) {
      yield team as Team;
    }
  }

  Stream<Town> townsStream() async* {
    await for (final item in ratingStream('/towns?itemsPerPage=30&page=1')) {
      yield item as Town;
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
    developer.log('PREVED');
    stderr.writeln('PREVED');
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

class ApiItemList<T extends ApiItem> extends StatefulWidget {
  const ApiItemList({Key? key}) : super(key: key);

  @override
  State<ApiItemList<T>> createState() => _ApiItemListState<T>();
}

class _ApiItemListState<T extends ApiItem> extends State<ApiItemList<T>> {
  final teamHttpService = TeamsHttpService();
  static const pageSize = 30;
  static const _biggerFont = const TextStyle(fontSize: 18);

  @override
  Widget build(BuildContext context) {
    return EndlessPaginationListView<T>(
        loadMore: (pageIndex) {
          return teamHttpService.getPage<T>(apiMethod<T>(), pageIndex + 1, pageSize);
        },
        paginationDelegate: EndlessPaginationDelegate(
          pageSize: pageSize,
        ),
        itemBuilder: (context,
            {
              required item,
              required index,
              required totalItems,
            }
            ) {
          return ListTile(
            title: Text(
              item.name,
              //style: _biggerFont,
            ),
            subtitle: Text(
              'id: ${item.id.toString()}',
            ),
          );
        }
    );
  }
}
