import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:endless/endless.dart';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

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
      return ApiItemListWithSearch<Team>();
    }
    if (body == Body.players) {
      return ApiItemListWithSearch<Player>();
    }
    if (body == Body.towns) {
      return const ApiItemList<Town>();
    }
    if (body == Body.countries) {
      return const ApiItemList<Country>();
    }
    if (body == Body.venues) {
      return ApiItemListWithSearch<Venue>();
    }
    return const Text('Not reached');
  }
}

class ApiItem {
  static const kGlobalIdKey = '@id';
  static const kTypeKey = '@type';
  static const kIdKey = 'id';
  static const kNameKey = 'name';

  late final String globalId;
  final String type;
  final int? id;
  final String? name;

  String get title => name ?? 'null';
  String get subtitle => 'id: $id';

  static String generateGlobalId(String type, int id) {
    return "/${apiMethodFromString(type)}/$id";
  }

  static int getIdFromGlobalId(String globalId) {
    final tokens = globalId.split('/');
    assert(tokens.length == 3);
    return int.parse(tokens[2]);
  }

  ApiItem(this.type, this.id, this.name) {
    globalId = generateGlobalId(type, id!);
  }
  ApiItem.fromJson(Map<String, dynamic> json)
      : globalId = json[kGlobalIdKey],
        type = json[kTypeKey],
        id = json[kIdKey],
        name = json[kNameKey] {
    if (id != null) {
      assert(globalId == generateGlobalId(type, id!));
    }
  }
  Map<String, dynamic> toJson() {
    return {
      kGlobalIdKey: globalId,
      kTypeKey: type,
      kIdKey: id,
      kNameKey: name,
    };
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
      case TeamSeason.jsonType:
        return TeamSeason(json);
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
  static const kTownKey = 'town';
  static const String jsonType = "Team";
  late final Town? town;
  Team(Map<String, dynamic> json) : super.fromJson(json) {
    final maybeTown = ApiItem.maybeBuildFromJson(json[kTownKey]);
    if (maybeTown != null) {
      town = maybeTown as Town;
    } else {
      town = null;
    }
  }

  @override
  String get subtitle => 'id: $id, ${town?.name}, ${town?.country?.name}';

  @override
  Map<String, dynamic> toJson() {
    var res = super.toJson();
    if (town != null) {
      res[kTownKey] = town!.toJson();
    }
    return res;
  }

  @override
  String toString() {
    return jsonEncode(toJson());
  }
}

class Player extends ApiItem {
  static const kSurnameKey = 'surname';
  static const kPatronymicKey = 'patronymic';
  static const String jsonType = "Player";
  final String surname;
  final String? patronymic;
  Player(Map<String, dynamic> json)
      : surname = json[kSurnameKey],
        patronymic = json[kPatronymicKey],
        super.fromJson(json);

  @override
  String get title => '$name $surname';

  @override
  Map<String, dynamic> toJson() {
    var res = super.toJson();
    res[kSurnameKey] = surname;
    if (patronymic != null) {
      res[kPatronymicKey] = patronymic!;
    }
    return res;
  }
}

class Town extends ApiItem {
  static const kCountryKey = 'country';
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

  @override
  Map<String, dynamic> toJson() {
    var res = super.toJson();
    if (country != null) {
      res[kCountryKey] = country!.toJson();
    }
    return res;
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

class TeamSeason extends ApiItem {
  static const String kIdPlayerKey = "idplayer";
  static const String kIdSeasonKey = "idseason";
  static const String kIdTeamKey = "idteam";
  static const String kDateAddedKey = "dateAdded";
  static const String kDateRemovedKey = "dateRemoved";
  static const String kPlayerNumberKey = "playerNumber";

  static const String jsonType = "TeamSeason";

  late final int idPlayer;
  late final int idSeason;
  late final int idTeam;
  late final DateTime? dateAdded;
  late final DateTime? dateRemoved;
  late final int isCaptain;
  TeamSeason(Map<String, dynamic> json) : super.fromJson(json) {
    idPlayer = json[kIdPlayerKey];
    idSeason = json[kIdSeasonKey];
    idTeam = json[kIdTeamKey];
    dateAdded = DateTime.tryParse(json[kDateAddedKey] ?? "");
    dateRemoved = DateTime.tryParse(json[kDateRemovedKey] ?? "");
    isCaptain = json[kPlayerNumberKey];
  }
}

class Venue extends ApiItem {
  static const kTownKey = 'town';
  static const String jsonType = "Venue";
  final Town town;
  Venue(Map<String, dynamic> json)
      : town = ApiItem.maybeBuildFromJson(json[kTownKey])! as Town,
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

  @override
  Map<String, dynamic> toJson() {
    var res = super.toJson();
    res[kTownKey] = town.toJson();
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
  if (T == TeamSeason) {
    return "seasons";
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

  static Future<List<T>> getPage<T extends ApiItem>(
      {int? page, String? searchPattern, Team? team}) async {
    String method = apiMethod<T>();
    Map<String, dynamic> options = {};
    if (page != null) {
      options['page'] = page.toString();
      options['itemsPerPage'] = kItemsPerPage.toString();
    }

    if (searchPattern != null && searchPattern.isNotEmpty) {
      final searchParams = await getSearchParams<T>(searchPattern);
      options.addAll(searchParams);
    }
    if (T == TeamSeason) {
      options['idseason'] = '57';
      assert(team != null);
      method = 'teams/${team!.id}/$method';
    }
    developer.log('get options $options');
    final response = await http.get(Uri.https(apiAddress, '/$method', options));

    if (response.statusCode != 200) {
      throw Exception('Failed to load $method: ${response.reasonPhrase}');
    }
    final result = json.decode(response.body);
    return List.generate(result['hydra:member'].length, (i) {
      T item = ApiItem.maybeBuildFromJson(result['hydra:member'][i])! as T;
      DBService.instance.addToCache(item);
      return item;
    });
  }

  /*
  static Future<LazyApiLoader<T>> getLazyApiLoader<T extends ApiItem>(int page,
      {String? searchPattern}) async {
    final String method = apiMethod<T>();
    Map<String, dynamic> options = {
      'page': page.toString(),
      'itemsPerPage': kItemsPerPage.toString()
    };
    if (searchPattern != null && searchPattern.isNotEmpty) {
      final searchParams = await getSearchParams<T>(searchPattern);
      options.addAll(searchParams);
    }
    if (T == TeamSeason) {
      options['idseason'] = ['56', '57'];
    }
    final response = await http.get(Uri.https(apiAddress, '/$method', options));

    if (response.statusCode != 200) {
      throw Exception('Failed to load $method: ${response.reasonPhrase}');
    }
    final result = json.decode(response.body);
    List<T> data = List.generate(result['hydra:member'].length, (i) {
      T item = ApiItem.maybeBuildFromJson(result['hydra:member'][i])! as T;
      DBService.instance.addToCache(item);
      return item;
    });
    return LazyApiLoader<T>(data, result['hydra:totalItems']);
  }
   */

  static Future<T> getByGlobalId<T extends ApiItem>(String globalId) async {
    developer.log('get by global id $globalId');
    ApiItem? maybeFromCache = await DBService.instance.getFromCache(globalId);
    if (maybeFromCache != null) {
      return maybeFromCache as T;
    }

    final response = await http.get(Uri.https(apiAddress, globalId));
    if (response.statusCode != 200) {
      throw Exception('Failed to load $globalId: ${response.reasonPhrase}');
    }
    final result = json.decode(response.body);
    T item = ApiItem.maybeBuildFromJson(result)! as T;
    DBService.instance.addToCache(item);
    return item;
  }

  static Future<List<String>> fetchBasePlayers(Team team) async {
    List<TeamSeason> teamSeasons =
        await APILoader.getPage<TeamSeason>(team: team);
    teamSeasons = teamSeasons.where((e) => e.dateRemoved == null).toList();

    developer.log('PREVED fetched ${teamSeasons.length}');
    teamSeasons.sort((TeamSeason a, TeamSeason b) {
      if (a.idSeason != b.idSeason) {
        return b.idSeason - a.idSeason;
      }
      if (a.isCaptain != b.isCaptain) {
        return b.isCaptain - a.isCaptain;
      }
      if (a.dateAdded != null && b.dateAdded != null) {
        return a.dateAdded!.compareTo(b.dateAdded!);
      }
      return a.idPlayer - b.idPlayer;
    });

    List<String> basePlayersGlobalIds = teamSeasons
        .map((e) => ApiItem.generateGlobalId(Player.jsonType, e.idPlayer))
        .toList();
    if (teamSeasons.isNotEmpty && teamSeasons[0].isCaptain == 0) {
      basePlayersGlobalIds.insert(0, '');
    }
    await DBService.instance.setBasePlayers(team, basePlayersGlobalIds);
    return basePlayersGlobalIds;
  }

  /*
  Stream<ApiItem> ratingStream(String path) async* {
    final response = await http.get(Uri.parse(apiUrl + path));
    if (response.statusCode != 20j0) {
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
          return APILoader.getPage<T>(page: pageIndex + 1);
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

enum PlayerFlag {
  cap,
  base,
  leg,
}

String flagToString(PlayerFlag flag) {
  switch (flag) {
    case PlayerFlag.base:
      return 'B';
    case PlayerFlag.cap:
      return 'C';
    case PlayerFlag.leg:
      return 'L';
  }
}

class DBService extends ChangeNotifier {
  static DBService instance = DBService();

  late Future<Database> futureDB;
  Database? db;

  SharedPreferences? sharedPrefs;

  static const String kFavoritesTable = "favorites";
  static const String kCacheTable = "CacheTable";
  late Map<String, bool> favorites;

  DBService() {
    openDB();
  }

  Future<void> openDB() async {
    final venuesTableName = apiMethod<Venue>();
    final townsTableName = apiMethod<Town>();
    final countryTableName = apiMethod<Country>();

    futureDB = openDatabase(
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
        //await db.execute(
        //'CREATE TABLE IF NOT EXISTS $kFavoritesTable(global_id STRING PRIMARY KEY, is_favorite BOOLEAN)');
        //await db.execute(
        //'CREATE TABLE IF NOT EXISTS $kFavoritesTable(global_id STRING PRIMARY KEY, is_favorite BOOLEAN)');
        await db.execute(
            'CREATE TABLE IF NOT EXISTS $kCacheTable(global_id STRING PRIMARY KEY, json STRING)');

        // Delete not favorite
        //await db.delete(kFavoritesTable, where: "is_favorite = ?", whereArgs: [0]);

        /*
        {
          // load favorites
          final favs = await db.query(kFavoritesTable);
          for (final fav in favs) {
            developer.log('load favorites ${fav.toString()}');
            favorites[fav["global_id"] as String] =
                (fav["is_favorite"] as int) == 1;
          }
          notifyListeners();
        }
         */
      },
      version: 1,
    );

    sharedPrefs = await SharedPreferences.getInstance();
    // load favorites
    final favList = sharedPrefs!.getStringList(kFavoritesTable) ?? [];
    favorites = {};
    for (final fav in favList) {
      favorites[fav] = true;
    }

    db = await futureDB;
  }

  bool isFavorite(String globalId) {
    //final result = await (await db).query(kFavoritesTable, where: "global_id = ?", whereArgs: [globalId]);
    //if (result.isEmpty) {
    //return false;
    //}
    //return result[0]["is_favorite"]! as bool;
    return favorites[globalId] ?? false;
  }

  void flipIsFavorite(String globalId) async {
    final prefs = await SharedPreferences.getInstance();
    favorites[globalId] = !isFavorite(globalId);
    await prefs.setStringList(kFavoritesTable,
        favorites.keys.where((element) => isFavorite(element)).toList());
    notifyListeners();
    /*
    db
        .insert(
            kFavoritesTable,
            {
              "global_id": globalId,
              "is_favorite": isFavorite(globalId) ? 1 : 0
            },
            conflictAlgorithm: ConflictAlgorithm.replace)
        .then((value) => developer.log('Inserted as $value'));

     */
  }

  static const kSelectedPrefix = "selected";

  static String selectedKey(Player player) =>
      "$kSelectedPrefix${player.globalId}";
  bool isSelected(Player player, Team team) {
    if (sharedPrefs == null) {
      return false;
    }
    return sharedPrefs!.getString(selectedKey(player)) == team.globalId;
  }

  static const int kMaxLrpLength = 10;
  void flipIsSelected(Player player, Team team) async {
    final prefs = await SharedPreferences.getInstance();
    if (isSelected(player, team)) {
      prefs.remove(selectedKey(player));
    } else {
      await prefs.setString(selectedKey(player), team.globalId);
      List<String> lrp = await getLRP(team);
      lrp.remove(player.globalId);
      lrp.insert(0, player.globalId);
      if (lrp.length > kMaxLrpLength) {
        lrp.length = kMaxLRPLength;
      }
      await prefs.setStringList(getLRPKey(team), lrp);
    }
    notifyListeners();
  }

  static const kSelectedTeamsKey = "selectedTeams";
  bool isSelectedTeam(Team team) {
    if (sharedPrefs == null) {
      return false;
    }
    return (sharedPrefs!.getStringList(kSelectedTeamsKey) ?? [])
        .contains(team.globalId);
  }

  void flipIsSelectedTeam(Team team) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> selectedTeams = prefs.getStringList(kSelectedTeamsKey) ?? [];
    if (selectedTeams.contains(team.globalId)) {
      selectedTeams.remove(team.globalId);
    } else {
      selectedTeams.add(team.globalId);
    }
    await prefs.setStringList(kSelectedTeamsKey, selectedTeams);
    notifyListeners();
  }

  static const kMaxLRPLength = 10;
  static const kLRPPrefix = "LRP";
  static String getLRPKey(Team team) => "$kLRPPrefix${team.globalId}";

  // Returns the list of players selected for teamId. At most kMaxRPLength
  Future<List<String>> getLRP(Team team) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(getLRPKey(team)) ?? [];
  }

  static String getBaseCrewKey(Team team) => "base_${team.globalId}";
  Future<void> setBasePlayers(Team team, List<String> globalIds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(getBaseCrewKey(team), globalIds);
  }

  PlayerFlag getPlayerFlag(Team team, Player player) {
    List<String> basePlayers =
        sharedPrefs!.getStringList(getBaseCrewKey(team)) ?? [];
    if (basePlayers.isEmpty || !basePlayers.contains(player.globalId)) {
      return PlayerFlag.leg;
    }
    if (basePlayers[0] == player.globalId) {
      return PlayerFlag.cap;
    }
    return PlayerFlag.base;
  }

  Future<void> addToCache(ApiItem item) async {
    final localDB = await futureDB;
    localDB.insert(
        kCacheTable,
        {
          "global_id": item.globalId,
          "json": jsonEncode(item),
        },
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<ApiItem?> getFromCache(String globalId) async {
    final localdb = await futureDB;
    final result = await localdb
        .query(kCacheTable, where: "global_id = ?", whereArgs: [globalId]);
    if (result.length != 1) {
      return null;
    }
    return ApiItem.maybeBuildFromJson(jsonDecode(result[0]['json']! as String));
  }

  Future<List<T>> fetchFavorites<T extends ApiItem>(
      {String? searchPattern, Team? team}) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    List<T> res = [];

    var favIds = prefs.getStringList(kFavoritesTable) ?? [];
    favIds.sort((a, b) {
      return ApiItem.getIdFromGlobalId(a) - ApiItem.getIdFromGlobalId(b);
    });

    for (final globalId
        in favIds.where((element) => element.contains(apiMethod<T>()))) {
      T item = await APILoader.getByGlobalId<T>(globalId);
      res.add(item);
    }
    return res;
  }

  List<String> getFavoritesIds<T extends ApiItem>() {
    List<String> res = [];
    var keys = favorites.keys
        .where((element) => element.contains(apiMethod<T>()))
        .toList();
    keys.sort((a, b) {
      return ApiItem.getIdFromGlobalId(a) - ApiItem.getIdFromGlobalId(b);
    });
    return keys;
  }

  Future<int?> findTownId(String name) async {
    final tableName = apiMethod<Town>();
    final localDB = await futureDB;
    final results = await localDB.query(tableName,
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
    final localDB = await futureDB;
    final results = await localDB.query(tableName,
        columns: ["country_id"],
        where: "UPPER(country_name) = UPPER(?)",
        whereArgs: [name]);
    if (results.length != 1) {
      return null;
    }
    return results[0]["country_id"] as int;
  }

  Future<void> updateCache() async {
    final localDB = await futureDB;
    fetchData<Venue>(localDB);
    fetchData<Town>(localDB);
    fetchData<Country>(localDB);
  }

  Future<void> fetchData<T extends ApiItem>(Database db) async {
    final tableName = apiMethod<T>();
    int count = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM $tableName'))!;
    developer.log('PREVED $count in $tableName');
    for (int page = count ~/ APILoader.kItemsPerPage;; page++) {
      var data = await APILoader.getPage<T>(page: page + 1);
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
    final localDB = await futureDB;
    final dbList = await localDB.rawQuery(
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

class ApiItemListWithSearch<T extends ApiItem> extends StatelessWidget {
  ApiItemListWithSearch({super.key});

  final ValueNotifier<String> searchPatternNotifier = ValueNotifier<String>("");

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        TextField(
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search),
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
    final nextBatch = await APILoader.getPage<T>(
        page: nextPage, searchPattern: searchPattern);
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
      final nextBatch = await APILoader.getPage<T>(
          page: page++, searchPattern: searchPattern);
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

class MultipleSourceLoader<T extends ApiItem> {
  final Team? team;
  final String searchPattern;
  // The result
  List<T> items = [];

  // The set of global ids built from items list. Used to avoid duplicates in the items list.
  Set<String> globalIds = {};

  int nextPage = -1;
  bool isMore = true;

  MultipleSourceLoader({this.team, required this.searchPattern}) {
    if (team != null) {
      assert(T == Player);
    }
  }

  int get uiItemsCount => items.length + (isMore ? 1 : 0);

  Future<void> loadMore() async {
    assert(isMore);

    if (nextPage < 0) {
      // Initial load for least recent players.
      if (team != null) {
        final List<String> lrp = await DBService.instance.getLRP(team!);
        await _addAll(lrp);
      }

      // Load favorites.
      final List<T> favorites = await DBService.instance.fetchFavorites<T>();
      for (final T item in favorites) {
        _maybeAdd(item);
      }

      nextPage = 0;
      return;
    }

    if (nextPage == 0) {
      if (team != null) {
        // load base crews.
        await _addAll(await APILoader.fetchBasePlayers(team!));
      }
      nextPage = 1;
      return;
    }

    if (nextPage > 0) {
      final nextBatch = await APILoader.getPage<T>(
          page: nextPage++, searchPattern: searchPattern);
      for (final T item in nextBatch) {
        _maybeAdd(item);
      }
      isMore = nextBatch.length == APILoader.kItemsPerPage;
      return;
    }
  }

  Future<void> _addAll(List<String> more) async {
    developer.log('PREVED _addAll $more');
    for (final globalId in more) {
      if (globalIds.contains(globalId)) {
        continue;
      }
      T item = (await APILoader.getByGlobalId(globalId)) as T;
      _maybeAdd(item);
    }
  }

  void _maybeAdd(T item) {
    if (globalIds.contains(item.globalId)) {
      return;
    }
    globalIds.add(item.globalId);
    items.add(item);
  }
}

class _SearchResultsState<T extends ApiItem> extends State<SearchResults<T>> {
  MultipleSourceLoader<T>? loader;

  StreamSubscription<void>? dataSub;

  void _updateItems(void event) {
    developer.log('_update items ${loader!.items.length}');
    setState(() {
      dataSub = null;
    });
  }

  void _loadMore() {
    dataSub?.cancel();
    dataSub = loader!.loadMore().asStream().listen(_updateItems);
  }

/*
  void _maybeUpdateFavorites() {
    final newFavoritesIds = DBService.instance.getFavoritesIds<T>();
    if (favoritesIds == newFavoritesIds) {
      return;
    }
    favoritesIds = newFavoritesIds;
    DBService.instance.fetchFavorites<T>().then((value) {
      setState(() {
        favorites = value;
      });
    });
  }
     */

  @override
  void initState() {
    super.initState();
    widget.searchPattern.addListener(resetState);
  }

  void resetState() {
    TeamInherited? teamInherited = TeamInherited.of(super.context);
    setState(() {
      loader = MultipleSourceLoader(
          searchPattern: widget.searchPattern.value, team: teamInherited?.team);
    });
    _loadMore();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    resetState();
  }

  @override
  void dispose() {
    widget.searchPattern.removeListener(resetState);
    dataSub?.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalLength = loader!.uiItemsCount;
    if (totalLength == 0) {
      return const Text("No search results");
    }
    return Expanded(
      child: ListView.builder(
          itemCount: totalLength,
          itemBuilder: (context, index) {
            if (dataSub == null && loader!.isMore && index + 10 > totalLength) {
              developer.log('PREVED load online');
              _loadMore();
            }

            if (index < loader!.items.length) {
              return SingleApiItem<T>(item: loader!.items[index]);
            }
            return Center(child: CircularProgressIndicator());
          }),
    );
  }
}

class SingleLoadingItem<T extends ApiItem> extends StatelessWidget {
  final String globalId;
  late final Future<T> item;
  SingleLoadingItem({super.key, required this.globalId}) {
    item = APILoader.getByGlobalId<T>(globalId);
  }
  @override
  Widget build(context) {
    return FutureBuilder<T>(
        future: item,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return SingleApiItem(item: snapshot.requireData);
          }
          if (snapshot.hasError) {
            return Text('${snapshot.error}');
          }
          return const Center(child: CircularProgressIndicator());
        });
  }
}

class SingleApiItem<T extends ApiItem> extends StatefulWidget {
  final T item;
  const SingleApiItem({super.key, required this.item});

  @override
  State<StatefulWidget> createState() {
    return _SingleApiItemState<T>();
  }
}

class _SingleApiItemState<T extends ApiItem> extends State<SingleApiItem<T>> {
  @override
  void initState() {
    super.initState();
    DBService.instance.addListener(_onDBChange);
  }

  void _onDBChange() {
    setState(() {});
  }

  @override
  void dispose() {
    DBService.instance.removeListener(_onDBChange);
    super.dispose();
  }

  @override
  Widget build(context) {
    Widget? leading;
    void Function()? onTap;
    void Function()? onLongPressed;
    TeamInherited? teamInherited = TeamInherited.of(context);
    if (T == Player && teamInherited != null) {
      leading = SizedBox.shrink(child: Row(children: <Widget>[
        Checkbox(
            value: DBService.instance
                .isSelected(widget.item as Player, teamInherited.team),
            onChanged: (bool? value) {
              if (value! ==
                  DBService.instance
                      .isSelected(widget.item as Player, teamInherited.team)) {
                return;
              }
              DBService.instance
                  .flipIsSelected(widget.item as Player, teamInherited.team);
            }),
            Text(flagToString(DBService.instance
                .getPlayerFlag(teamInherited.team, widget.item as Player))),
      ]));
      onTap = () {
        DBService.instance
            .flipIsSelected(widget.item as Player, teamInherited.team);
      };
    }

    if (T == Team) {
      leading = Checkbox(
        value: DBService.instance.isSelectedTeam(widget.item as Team),
        onChanged: (bool? value) {
          if (value! ==
              DBService.instance.isSelectedTeam(widget.item as Team)) {
            return;
          }
          DBService.instance.flipIsSelectedTeam(widget.item as Team);
        },
      );
      onTap = () {
        DBService.instance.flipIsSelectedTeam(widget.item as Team);
      };
      onLongPressed = () {
        Navigator.of(context).push(MaterialPageRoute<void>(builder: (context) {
          return TeamChoiceCrewView(team: widget.item as Team);
        }));
      };
    }
    return ListTile(
      title: Text(widget.item.title),
      subtitle: Text(widget.item.subtitle),
      trailing: IconButton(
        icon: Icon(
          DBService.instance.isFavorite(widget.item.globalId)
              ? Icons.favorite
              : Icons.favorite_border,
        ),
        onPressed: () {
          DBService.instance.flipIsFavorite(widget.item.globalId);
        },
      ),
      leading: leading,
      onTap: onTap,
      onLongPress: onLongPressed,
    );
  }
}

class TeamInherited extends InheritedWidget {
  final Team team;
  const TeamInherited({super.key, required this.team, required super.child});

  static TeamInherited? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<TeamInherited>();
  }

  @override
  bool updateShouldNotify(TeamInherited oldWidget) =>
      team.id != oldWidget.team.id;
}

class TeamChoiceCrewView extends StatelessWidget {
  final Team team;
  const TeamChoiceCrewView({super.key, required this.team});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(team.name!),
      ),
      body: TeamInherited(
        team: team,
        child: ApiItemListWithSearch<Player>(),
      ),
    );
  }
}
