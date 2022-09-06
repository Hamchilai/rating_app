import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:endless/endless.dart';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:async';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

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
        home: const MyHomePage(title: 'api.rating app'));
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
      return const ApiItemListWithSearch<Team>();
    }
    if (body == Body.players) {
      return const ApiItemListWithSearch<Player>();
    }
    if (body == Body.towns) {
      return const ApiItemList<Town>();
    }
    if (body == Body.countries) {
      return const ApiItemList<Country>();
    }
    if (body == Body.venues) {
      return const ApiItemListWithSearch<Venue>();
    }
    return const Text('Not reached');
  }
}

class ApiItem {
  late final String globalId;
  final String type;
  final int id;
  final String name;

  String get title => name;
  String get subtitle => 'id: $id';

  static String generateGlobalId(String type, int id) {
    return "/${apiMethodFromString(type)}/$id";
  }

  ApiItem(this.type, this.id, this.name) {
    globalId = generateGlobalId(type, id);
  }
  ApiItem.fromJson(Map<String, dynamic> json)
      : globalId = json['@id'],
        type = json['@type'],
        id = json['id'],
        name = json['name'] {
    assert(globalId == generateGlobalId(type, id));
  }

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

  static ApiItem? buildFromDB<T extends ApiItem>(Map<String, Object?> map) {
    if (T == Venue) {
      return Venue.fromDB(map);
    }
    return null;
  }

  Map<String, dynamic> toMap() {
    final prefix = '${type.toLowerCase()}_';
    return {
      '${prefix}id': id,
      '${prefix}name': name,
    };
  }
}

class Team extends ApiItem {
  static const String jsonType = "Team";
  late final Town? town;
  Team(Map<String, dynamic> json) : super.fromJson(json) {
    final maybeTown = ApiItem.maybeBuildFromJson(json['town']);
    if (maybeTown != null) {
      town = maybeTown as Town;
    } else {
      town = null;
    }
  }

  @override
  String get subtitle => 'id: $id, ${town?.name}, ${town?.country?.name}';
}

class Player extends ApiItem {
  static const String jsonType = "Player";
  final String surname;
  final String? patronymic;
  Player(Map<String, dynamic> json)
      : surname = json['surname'],
        patronymic = json['patronymic'],
        super.fromJson(json);

  @override
  String get title => '$name $surname';
}

class Town extends ApiItem {
  static const String jsonType = "Town";
  late final Country? country;
  Town(Map<String, dynamic> json) : super.fromJson(json) {
    final maybeCountry = ApiItem.maybeBuildFromJson(json['country']);
    if (maybeCountry != null) {
      country = maybeCountry as Country;
    } else {
      country = null;
    }
  }

  Town.fromDB(Map<String, Object?> map)
      : super(jsonType, map['town_id'] as int, map['town_name'] as String) {
    if (map.containsKey('country_id')) {
      country = Country.fromDB(map);
    } else {
      country = null;
    }
  }

  @override
  String get subtitle => 'id: $id, ${country?.name}';

  @override
  Map<String, dynamic> toMap() {
    var res = super.toMap();
    if (country != null) {
      res['country_id'] = country!.id;
    }
    return res;
  }
}

class Country extends ApiItem {
  static const String jsonType = "Country";

  Country(Map<String, dynamic> json) : super.fromJson(json);

  Country.fromDB(Map<String, Object?> map)
      : super(
            jsonType, map['country_id'] as int, map['country_name'] as String);
}

class Venue extends ApiItem {
  static const String jsonType = "Venue";
  final Town town;
  Venue(Map<String, dynamic> json)
      : town = ApiItem.maybeBuildFromJson(json['town'])! as Town,
        super.fromJson(json);

  Venue.fromDB(Map<String, Object?> map)
      : town = Town.fromDB(map),
        super(jsonType, map['venue_id'] as int, map['venue_name'] as String);

  @override
  get subtitle => 'id: $id, ${town.name}, ${town.country?.name}';

  @override
  Map<String, dynamic> toMap() {
    var res = super.toMap();
    res['town_id'] = town.id;
    return res;
  }
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

String apiMethodFromString(String type) {
  switch (type) {
    case Team.jsonType:
      return apiMethod<Team>();
    case Player.jsonType:
      return apiMethod<Player>();
    case Town.jsonType:
      return apiMethod<Town>();
    case Country.jsonType:
      return apiMethod<Country>();
    case Venue.jsonType:
      return apiMethod<Venue>();
  }
  throw Exception("Not reached with type $type");
}

class APILoader {
  static const apiAddress = 'api.rating.chgk.net';
  static const apiUrl = 'https://$apiAddress';
  static const hydraViewKey = 'hydra:view';
  static const hydraNextKey = 'hydra:next';
  static const int kItemsPerPage = 50;
  /*
  Future<List<Team>> listTeams() async {
    final response = await http.get(Uri.https('api.rating.chgk.net', '/teams',
        {'page': '1', 'itemsPerPage': '70', 'town': '205'}));

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
   */

  static Future<Map<String, String>> getSearchParams<T>(String pattern) async {
    Map<String, String> params = {};
    switch (T) {
      case Player:
        final tokens = pattern.split(' ');
        if (tokens.length >= 2) {
          params["name"] = tokens[0];
          params["surname"] = tokens[1];
        } else if (tokens.isNotEmpty) {
          params["surname"] = tokens[0];
        }
        break;
      case Team:
        final tokens = pattern.split(';').map((e) => e.trim()).toList();
        if (tokens.isNotEmpty && tokens[0].isNotEmpty) {
          params["name"] = tokens[0];
        }
        if (tokens.length >= 2 && tokens[1].isNotEmpty) {
          final int? townId = await DBService.instance.findTownId(tokens[1]);
          if (townId != null) {
            params["town"] = townId.toString();
          } else {
            final int? countryId =
                await DBService.instance.findCountryId(tokens[1]);
            if (countryId != null) {
              params["town.country"] = countryId.toString();
            }
          }
        }
        break;
      default:
        throw Exception("Not reached in getSearchParams ${apiMethod<T>()}");
    }
    developer.log('PREVED getSearch ${params.toString()}');
    return params;
  }

  static Future<List<T>> getPage<T extends ApiItem>(int page,
      {String? searchPattern}) async {
    final loader = await getLazyApiLoader<T>(page, searchPattern: searchPattern);
    return loader.data;
  }

  static Future<LazyApiLoader<T>> getLazyApiLoader<T extends ApiItem>(int page,
      {String? searchPattern}) async {
    final String method = apiMethod<T>();
    var options = {
      'page': page.toString(),
      'itemsPerPage': kItemsPerPage.toString()
    };
    if (searchPattern != null && searchPattern.isNotEmpty) {
      final searchParams = await getSearchParams<T>(searchPattern);
      options.addAll(searchParams);
    }
    final response = await http.get(Uri.https(apiAddress, '/$method', options));

    if (response.statusCode != 200) {
      throw Exception('Failed to load $method: ${response.reasonPhrase}');
    }
    final result = json.decode(response.body);
    List<T> data = List.generate(result['hydra:member'].length, (i) {
      return ApiItem.maybeBuildFromJson(result['hydra:member'][i])! as T;
    });
    return LazyApiLoader<T>(data, result['hydra:totalItems']);
  }

  /*
  Stream<ApiItem> ratingStream(String path) async* {
    final response = await http.get(Uri.parse(apiUrl + path));
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
   */
}

class ApiItemList<T extends ApiItem> extends StatefulWidget {
  const ApiItemList({Key? key}) : super(key: key);

  @override
  State<ApiItemList<T>> createState() => _ApiItemListState<T>();
}

class _ApiItemListState<T extends ApiItem> extends State<ApiItemList<T>> {
  static const _biggerFont = const TextStyle(fontSize: 18);

  @override
  Widget build(BuildContext context) {
    return EndlessPaginationListView<T>(
        loadMore: (pageIndex) {
          return APILoader.getPage<T>(pageIndex + 1);
        },
        paginationDelegate: EndlessPaginationDelegate(
          pageSize: APILoader.kItemsPerPage,
        ),
        itemBuilder: (
          context, {
          required item,
          required index,
          required totalItems,
        }) {
          return ListTile(
            title: Text(
              item.title,
              //style: _biggerFont,
            ),
            subtitle: Text(
              item.subtitle,
            ),
          );
        });
  }
}

class DBService {
  static DBService instance = DBService();
  late Database db;
  static const String kFavoritesTable = "favorites";
  Map<String, bool> favorites = {};

  DBService() {
    openDB();
  }

  Future<void> openDB() async {
    final venuesTableName = apiMethod<Venue>();
    final townsTableName = apiMethod<Town>();
    final countryTableName = apiMethod<Country>();
    db = await openDatabase(
      join(await getDatabasesPath(), "local_cache.db"),
      onCreate: (db, version) async {
        developer.log('PREVED onCreate $version');
        await db.execute(
            'CREATE TABLE $venuesTableName(id INTEGER PRIMARY KEY, name TEXT, town_id INTEGER)');
        await db.execute(
            'CREATE TABLE $townsTableName(id INTEGER PRIMARY KEY, name TEXT, country_id INTEGER)');
        await db.execute(
            'CREATE TABLE $countryTableName(id INTEGER PRIMARY KEY, name TEXT)');
      },
      onOpen: (db) async {
        //await db.execute('DROP TABLE $venuesTableName');
        //await db.execute('DROP TABLE $townsTableName');
        //await db.execute('DROP TABLE $countryTableName');

        await db.execute(
            'CREATE TABLE IF NOT EXISTS $venuesTableName(venue_id INTEGER PRIMARY KEY, venue_name TEXT, town_id INTEGER)');
        await db.execute(
            'CREATE TABLE IF NOT EXISTS $townsTableName(town_id INTEGER PRIMARY KEY, town_name TEXT, country_id INTEGER)');
        await db.execute(
            'CREATE TABLE IF NOT EXISTS $countryTableName(country_id INTEGER PRIMARY KEY, country_name TEXT)');
        await db.execute(
            'CREATE TABLE IF NOT EXISTS $kFavoritesTable(global_id STRING PRIMARY KEY, is_favorite BOOLEAN)');

        {
          // load favorites
          final favs = await db.query(kFavoritesTable);
          for (final fav in favs) {
            developer.log('load favorites ${fav.toString()}');
            favorites[fav["global_id"] as String] =
                (fav["is_favorite"] as int) == 1;
          }
        }
      },
      version: 1,
    );
  }

  bool isFavorite(String globalId) {
    //final result = await (await db).query(kFavoritesTable, where: "global_id = ?", whereArgs: [globalId]);
    //if (result.isEmpty) {
    //return false;
    //}
    //return result[0]["is_favorite"]! as bool;
    return favorites[globalId] ?? false;
  }

  Future<void> flipIsFavorite(String globalId) async {
    favorites[globalId] = !isFavorite(globalId);
    db
        .insert(
            kFavoritesTable,
            {
              "global_id": globalId,
              "is_favorite": isFavorite(globalId) ? 1 : 0
            },
            conflictAlgorithm: ConflictAlgorithm.replace)
        .then((value) => developer.log('Inserted as $value'));
  }

  Future<List<T>> fetchFavorites<T extends ApiItem>() async {
    return [];
  }

  Future<int?> findTownId(String name) async {
    final tableName = apiMethod<Town>();
    final results = await db.query(tableName,
        columns: ["town_id"],
        where: "UPPER(town_name) = UPPER(?)",
        whereArgs: [name]);
    if (results.length != 1) {
      return null;
    }
    return results[0]["town_id"] as int;
  }

  Future<int?> findCountryId(String name) async {
    final tableName = apiMethod<Country>();
    final results = await db.query(tableName,
        columns: ["country_id"],
        where: "UPPER(country_name) = UPPER(?)",
        whereArgs: [name]);
    if (results.length != 1) {
      return null;
    }
    return results[0]["country_id"] as int;
  }

  Future<void> updateCache() async {
    fetchData<Venue>(db);
    fetchData<Town>(db);
    fetchData<Country>(db);
  }

  Future<void> fetchData<T extends ApiItem>(Database db) async {
    final tableName = apiMethod<T>();
    int count = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM $tableName'))!;
    developer.log('PREVED $count in $tableName');
    for (int page = count ~/ APILoader.kItemsPerPage;; page++) {
      var data = await APILoader.getPage<T>(page + 1);
      Batch batch = db.batch();
      for (T t in data) {
        batch.insert(tableName, t.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await batch.commit(noResult: true);
      if (data.length < APILoader.kItemsPerPage) {
        break;
      }
    }
  }

  /*
  Future<Database> get db async {
    if (database == null) {
      await openDB();
    }
    return database!;
  }
   */

  Future<List<T>> getPage<T extends ApiItem>(
      int page, int itemsPerPage, String town) async {
    final dbList = await db.rawQuery(
        'SELECT * FROM venues'
        ' INNER JOIN towns USING(town_id) LEFT JOIN countries'
        ' USING(country_id)'
        ' WHERE INSTR(UPPER(venue_name), UPPER(?)) > 0'
        ' OR INSTR(UPPER(town_name), UPPER(?)) > 0'
        ' OR INSTR(UPPER(country_name), UPPER(?)) > 0'
        ' LIMIT ?,?',
        [town, town, town, page * itemsPerPage, itemsPerPage]);
    return dbList.map((e) => ApiItem.buildFromDB<T>(e) as T).toList();
  }
}

class ApiItemListWithSearch<T extends ApiItem> extends StatefulWidget {
  const ApiItemListWithSearch({Key? key}) : super(key: key);

  @override
  State<ApiItemListWithSearch<T>> createState() =>
      _ApiItemListWithSearchState<T>();
}

String getHintText<T>() {
  switch (T) {
    case Venue:
      return "Town";
    case Player:
      return "[Name ]Surname";
    case Team:
      return "Name[;Town or Country]";
    default:
      return "Name";
  }
}

class _ApiItemListWithSearchState<T extends ApiItem>
    extends State<ApiItemListWithSearch<T>> {

  final ValueNotifier<String> searchPatternNotifier = ValueNotifier<String>("");

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        TextField(
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.search),
            hintText: getHintText<T>(),
          ),
          onTap: () {
            developer.log('PREVED on tap');
          },
          onSubmitted: (String value) {
            developer.log('PREVED on submitted $value');
            searchPatternNotifier.value = value.trim();
          },
          onChanged: (String value) {
            /*
            if (town == value.trim()) {
              return;
            }
            setState(() {
              town = value.trim();
              controller.reload();
            });
             */
            developer.log('PREVED on changed $value');
          },
        ),
        SearchResults<T>(searchPattern: searchPatternNotifier),
        /*
        Expanded(
            child: EndlessPaginationListView<T>(
                loadMore: (pageIndex) {
                  if (T == Venue) {
                    return DBService.instance
                        .getPage<T>(pageIndex, pageSize, searchPattern ?? "");
                  }
                  return TeamsHttpService.instance.getPage(
                      apiMethod<T>(), pageIndex + 1, pageSize,
                      searchPattern: searchPattern);
                },
                paginationDelegate: EndlessPaginationDelegate(
                  pageSize: pageSize,
                ),
                controller: controller,
                itemBuilder: (
                  context, {
                  required item,
                  required index,
                  required totalItems,
                }) {
                  return ListTile(
                      title: Text(
                        item.title,
                        //style: _biggerFont,
                      ),
                      subtitle: Text(
                        item.subtitle,
                      ),
                      trailing: InkWell(
                        child: Icon(
                          DBService.instance.isFavorite(item.globalId)
                              ? Icons.favorite
                              : Icons.favorite_border,
                        ),
                        onTap: () {
                          setState(() {
                            DBService.instance.flipIsFavorite(item.globalId);
                          });
                        },
                      ));
                }))

         */
      ],
    );
  }
}

class LazyApiLoader<T extends ApiItem> {
  String? searchPattern;
  List<T> data;
  int totalItems;

  LazyApiLoader(this.data, this.totalItems, {this.searchPattern});

  Future<void> _fetchData() async {
    int nextPage = data.length ~/ APILoader.kItemsPerPage + 1;
    developer.log('PREVED fetchdata at $nextPage');
    final nextBatch =
        await APILoader.getPage<T>(nextPage, searchPattern: searchPattern);
    data.addAll(nextBatch);
  }

  Future<T?> getAt(int index) async {
    if (index < 0 || index >= totalItems) {
      return null;
    }
    while (index >= data.length) {
      await _fetchData();
    }
    return data[index];
  }
}

class StreamLoader<T extends ApiItem> {
  late final StreamController<T> _controller;
  int page = 1;
  String? searchPattern;
  StreamLoader({this.searchPattern}) {
    _controller = StreamController<T>(onListen: _loadData, onResume: _loadData);
  }

  Stream<T> get stream => _controller.stream;

  void _loadData() async {
    while (!_controller.isClosed && !_controller.isPaused) {
      final nextBatch =
          await APILoader.getPage<T>(page++, searchPattern: searchPattern);
      for (final item in nextBatch) {
        _controller.add(item as T);
      }
      if (nextBatch.length < APILoader.kItemsPerPage) {
        await _controller.close();
      }
    }
  }
}

class SearchResults<T extends ApiItem> extends StatefulWidget {
  final ValueNotifier<String> searchPattern;
  const SearchResults({super.key, required this.searchPattern});

  @override
  State<StatefulWidget> createState() {
    return _SearchResultsState<T>();
  }
}

class _SearchResultsState<T extends ApiItem> extends State<SearchResults<T>> {
  List<T> items = [];
  int page = 1;
  int more = 1;
  StreamSubscription<List<T>>? dataSub;

  void _updateItems(List<T> newItems) {
    setState(() {
      dataSub?.cancel();
      dataSub = null;
      items.addAll(newItems);
      more = newItems.length == APILoader.kItemsPerPage ? 1 : 0;
    });
  }

  void _loadMore() {
    dataSub?.cancel();
    dataSub = APILoader.getPage<T>(page++, searchPattern: widget.searchPattern.value).asStream().listen(_updateItems);
  }

  @override
  void initState() {
    super.initState();
    _loadMore();
    widget.searchPattern.addListener(resetState);
  }

  void resetState() {
    setState(() {
      items = [];
      page = 1;
      more = 1;
      _loadMore();
    });
  }

  @override
  void dispose() {
    widget.searchPattern.removeListener(resetState);
    dataSub?.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (items.length + more == 0) {
      return const Text("No search results");
    }
    developer.log('length ${items.length} ');
    return Expanded(child: ListView.builder(
        itemCount: items.length + more,
        itemBuilder: (context, index) {
          if (dataSub == null && more > 0 && index + 10 > items.length) {
            _loadMore();
          }
          developer.log('$index');
          if (index < items.length) {
            return SingleApiItem<T>(item: items[index]);
          }
          return Center(child: CircularProgressIndicator());
        }),
    );
  }
}

class SingleApiItem<T extends ApiItem> extends StatelessWidget {
  final T item;
  const SingleApiItem({super.key, required this.item});

  @override
  Widget build(context) {
    return ListTile(
      title: Text(item.title),
      subtitle: Text(item.subtitle),
    );
  }
}
