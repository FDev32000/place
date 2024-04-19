import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';

class PlaceDetail extends StatefulWidget {
  final String placeId;

  PlaceDetail({required this.placeId});

  @override
  // ignore: library_private_types_in_public_api
  _PlaceDetailState createState() => _PlaceDetailState();
}

class _PlaceDetailState extends State<PlaceDetail> {
  late SharedPreferences prefs;
  List<FavoritePlaces> favoritePlaces = [];
  FavoritePlaces? place;

  @override
  void initState() {
    super.initState();
    initSharedPreferences();
    fetchDetails(widget.placeId).then((value) => setState(() => place = value));
  }

  initSharedPreferences() async {
    prefs = await SharedPreferences.getInstance();
    favoritePlaces = (prefs.getStringList('favoritePlaces') ?? [])
        .map((jsonString) => FavoritePlaces.fromMap(json.decode(jsonString)))
        .toList();
    setState(() {});
  }

  Future<FavoritePlaces> fetchDetails(String id) async {
    http.Response response;
    response = await http.get(Uri.parse(
        'https://catalog.api.2gis.com/3.0/items/byid?id=$id&key=19bcf602-be3c-4e75-aab5-1c9476b12cbc'));
    if (response.statusCode == 200) {
      Map<String, dynamic> data = json.decode(response.body)['result']['items'][0];
      return FavoritePlaces(
        id: data['id'] ?? '',
        name: data['name'] ?? '',
        addressName: data['address_name'] ?? '',
        fullName: data['full_name'] ?? '',
        purposeName: data['purpose_name'] ?? '',
        type: data['type'] ?? '',
        addressComment: data['address_comment'] ?? '',
        buildingName: data['building_name'] ?? '',
        contextRubrics: (data['context_rubrics'] as List?)
            ?.map((e) => ContextRubric.fromJson(e))
            .toList(),
      );
    }
    return FavoritePlaces(id: '', name: '', addressName: '', fullName: '', purposeName: '', type: '', addressComment: '', buildingName: '', contextRubrics: []);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Details'),
        actions: [
          IconButton(
            icon: Icon(
              isFavorite(place) ? Icons.favorite : Icons.favorite_border,
              color: isFavorite(place) ? Colors.red : Colors.black,
            ),
            onPressed: () {
              if (place != null) {
                toggleFavorite(place!);
              }
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              "assets/back.jpg",
              fit: BoxFit.cover,
            ),
          ),
          Container(
            padding: EdgeInsets.all(16.0),
            constraints: BoxConstraints.expand(
              height: MediaQuery.of(context).size.height,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(10.0),
              ),
              padding: EdgeInsets.all(16.0),
              child: place == null
                ? Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        place?.name ?? '',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Адрес: ${place?.addressName ?? ''}',
                        style: TextStyle(fontSize: 18, fontStyle: FontStyle.italic, color: Colors.white),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Тип: ${place?.purposeName ?? ''}',
                        style: TextStyle(fontSize: 18, fontStyle: FontStyle.italic, color: Colors.white),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Полное название: ${place?.fullName ?? ''}',
                        style: TextStyle(fontSize: 18, fontStyle: FontStyle.italic, color: Colors.white),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Комментарий: ${place?.addressComment ?? ''}',
                        style: TextStyle(fontSize: 18, fontStyle: FontStyle.italic, color: Colors.white),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Название здания: ${place?.buildingName ?? 'Нет названия здания'}',
                        style: TextStyle(fontSize: 18, fontStyle: FontStyle.italic, color: Colors.white),
                      ),
                      SizedBox(height: 10),
                      if (place?.contextRubrics != null) ...[
                        Text(
                          'Категории:',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        SizedBox(height: 5),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: (place?.contextRubrics as List?)?.cast<Map<String, dynamic>>()
                              .map<Widget>(
                                (rubric) => Text(
                                  '- ${rubric['name'] ?? 'Нет названия категории'}',
                                  style: TextStyle(fontSize: 16, color: Colors.white),
                                ),
                              )
                              .toList() ?? [],
                        ),
                      ],
                    ],
                  ),
                ),
            ),
          ),
        ],
      ),
    );
  }

  bool isFavorite(FavoritePlaces? place) {
    if (place == null) return false;
    return favoritePlaces.any((favorite) => favorite.id == place.id);
  }

  void toggleFavorite(FavoritePlaces place) {
    if (isFavorite(place)) {
      favoritePlaces.removeWhere((favorite) => favorite.id == place.id);
      prefs.setStringList('favoritePlaces', favoritePlaces.map((place) => jsonEncode(place.toMap())).toList());
    } else {
      favoritePlaces.add(place);
      prefs.setStringList('favoritePlaces', favoritePlaces.map((place) => jsonEncode(place.toMap())).toList());
    }
    setState(() {});
  }
}

