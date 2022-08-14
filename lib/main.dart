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
  players,
  towns,
  countries,
  venues,
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
              title: const Text('Players'),
              onTap: () {
                setState(() {
                  body = Body.players;
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
            ListTile(
              title: const Text('Venues'),
              onTap: () {
                setState(() {
                  body = Body.venues;
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
      return const ApiItemList<Team>();
    }
    if (body == Body.players) {
      return const PlayerListWithSearch();
    }
    if (body == Body.towns) {
      return const ApiItemList<Town>();
    }
    if (body == Body.countries) {
      return const ApiItemList<Country>();
    }
    if (body == Body.venues) {
      return const ApiItemList<Venue>();
    }
    return const Text('Not reached');
  }
}

class PlayerListWithSearch extends StatefulWidget {
  const PlayerListWithSearch({Key? key}) : super(key: key);

  @override
  State<PlayerListWithSearch> createState() => _PlayerListWithSearchState();
}

class _PlayerListWithSearchState extends State<PlayerListWithSearch> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        TextField(
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.search),
            hintText: "Surname",
          ),
          onTap: () {
            developer.log('PREVED on tap');
          },
          onSubmitted: (String value) {
            developer.log('PREVED on submitted $value');
          },
        ),
        Expanded(
          child: ApiItemList<Player>(),
        )
      ],
    );
  }
}

class ApiItem {
  final String globalId;
  final String type;
  final int id;
  final String name;

  String get title => name;
  String get subtitle => 'id: $id';

  ApiItem(Map<String, dynamic> json) :
        globalId = json['@id'],
        type = json['@type'],
        id = json['id'],
        name = json['name'];

  static ApiItem? maybeBuildFromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    String? type = json["@type"];
    if (type == null) {
      return null;
    }
    switch (type) {
      case Team.jsonType:
        return Team(json);
      case Player.jsonType:
        return Player(json);
      case Town.jsonType:
        return Town(json);
      case Country.jsonType:
        return Country(json);
      case Venue.jsonType:
        return Venue(json);
    }
    throw Exception("Can't build an item from ${json.toString()}");
  }
}

class Team extends ApiItem {
  static const String jsonType = "Team";
  final Town? town;
  Team(Map<String, dynamic> json) :
        town = ApiItem.maybeBuildFromJson(json['town']) as Town,
        super(json);

  @override
  String get subtitle => 'id: $id, ${town?.name}, ${town?.country?.name}';
}

class Player extends ApiItem {
  static const String jsonType = "Player";
  final String surname;
  final String? patronymic;
  Player(Map<String, dynamic> json) :
      surname = json['surname'],
      patronymic = json['patronymic'],
      super(json);

  @override
  String get title => '$name $surname';
}

class Town extends ApiItem {
  static const String jsonType = "Town";
  final Country? country;
  Town(Map<String, dynamic> json) :
        country = ApiItem.maybeBuildFromJson(json['country']) as Country,
        super(json);

  @override
  String get subtitle => 'id: $id, ${country?.name}';
}

class Country extends ApiItem {
  static const String jsonType = "Country";
  Country(Map<String, dynamic> json) : super(json);
}

class Venue extends ApiItem {
  static const String jsonType = "Venue";
  final Town town;
  Venue(Map<String, dynamic> json) :
        town = ApiItem.maybeBuildFromJson(json['town'])! as Town,
        super(json);
  @override
  get subtitle => 'id: $id, ${town.name}, ${town.country?.name}';
}

String apiMethod<T>() {
  if (T == Team) {
    return "teams";
  }
  if (T == Player) {
    return "players";
  }
  if (T == Town) {
    return "towns";
  }
  if (T == Country) {
    return "countries";
  }
  if (T == Venue) {
    return "venues";
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
        return ApiItem.maybeBuildFromJson(result['hydra:member'][i])! as Team;
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
        return ApiItem.maybeBuildFromJson(result['hydra:member'][i])! as T;
    });
  }

  Stream<ApiItem> ratingStream(String path) async* {
    final response = await http.get(Uri.parse(apiUrl+path));
    if (response.statusCode != 200) {
      throw Exception('Failed to load $path');
    }
    final result = json.decode(response.body);
    for (var jsonItem in result['hydra:member']) {
      yield ApiItem.maybeBuildFromJson(jsonItem)!;
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
              item.title,
              //style: _biggerFont,
            ),
            subtitle: Text(
              item.subtitle,
            ),
          );
        }
    );
  }
}
