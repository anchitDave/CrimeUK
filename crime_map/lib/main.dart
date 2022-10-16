import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert' show json;
import 'crime.dart';
import 'dart:ui' as ui;

void main() => runApp(MyApp());

Map<MarkerId, Marker> markers =
    <MarkerId, Marker>{}; // CLASS MEMBER, MAP OF MARKS
Map<String, Uint8List> images = <String, Uint8List>{};

Future<List<Crime>> fetchCrimesFromUKDataset(
    LatLng ll1, LatLng ll2, LatLng ll3, LatLng ll4) async {
  final response = await http.get(Uri.parse(
      'https://data.police.uk/api/crimes-street/all-crime?poly=${ll1.latitude},${ll1.longitude}:${ll2.latitude},${ll2.longitude}:${ll4.latitude},${ll4.longitude}:${ll3.latitude},${ll3.longitude}&date=2021-01'));
  List responseJson = json.decode(response.body.toString());
  List<Crime> userList = createCrimeList(responseJson);
  return userList;
}

List<Crime> createCrimeList(List data) {
  List<Crime> list = [];
  for (int i = 0; i < data.length; i++) {
    String category = data[i]["category"];
    String latitude = data[i]["location"]["latitude"];
    String longitude = data[i]["location"]["longitude"];
    Crime temp =
        Crime(category: category, latitude: latitude, longitude: longitude);
    list.add(temp);
  }
  return list;
}

Future<Uint8List> getBytesFromAsset(String path, int width) async {
  ByteData data = await rootBundle.load(path);
  ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(),
      targetWidth: width);
  ui.FrameInfo fi = await codec.getNextFrame();
  return (await fi.image.toByteData(format: ui.ImageByteFormat.png))!
      .buffer
      .asUint8List();
}

void PopulateImageMap() async {
  images["criminal-damage-arson"] =
      await getBytesFromAsset('assets/arson.png', 100);
  images["bicycle-theft"] = await getBytesFromAsset('assets/bicycle.png', 100);
  images["burglary"] = await getBytesFromAsset('assets/ninja.png', 100);
  images["possession-of-weapons"] =
      await getBytesFromAsset('assets/pistol.png', 100);
  images["shoplifting"] = await getBytesFromAsset('assets/shoplift.png', 100);
  images["theft-from-the-person"] =
      await getBytesFromAsset('assets/robbery.png', 100);
  images["robbery"] = await getBytesFromAsset('assets/robbery.png', 100);
  images["vehicle-crime"] = await getBytesFromAsset('assets/vehicle.png', 100);
  images["drugs"] = await getBytesFromAsset('assets/pills.png', 100);
  images["default"] = await getBytesFromAsset('assets/default.png', 100);
  images["blank"] = await getBytesFromAsset('assets/blank.png', 100);
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    PopulateImageMap();
    return MaterialApp(
      title: 'Flutter Google Maps Demo',
      home: MapSample(),
    );
  }
}

class MapSample extends StatefulWidget {
  @override
  State<MapSample> createState() => MapSampleState();
}

class MapSampleState extends State<MapSample> {
  Completer<GoogleMapController> _controller = Completer();

  static final CameraPosition _london = CameraPosition(
    target: LatLng(51.509865, -0.118092),
    zoom: 14.4746,
  );

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: AppBar(title: const Text("Crime map of the UK")),
      body: GoogleMap(
        mapType: MapType.normal,
        initialCameraPosition: _london,
        onMapCreated: (GoogleMapController controller) {
          _controller.complete(controller);
        },
        markers: Set<Marker>.of(markers.values), // YOUR MARKS IN MAP
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _searchCrimeHere,
        label: Text('Search Here'),
      ),
    );
  }

  Future<void> _searchCrimeHere() async {
    final GoogleMapController controller = await _controller.future;
    // controller.animateCamera(CameraUpdate.newCameraPosition(_kLake));

    // var width = MediaQuery.of(context).size.width.toInt();
    // var height = MediaQuery.of(context).size.height.toInt();
    var height = WidgetsBinding.instance.window.physicalSize.height.toInt();
    var width = WidgetsBinding.instance.window.physicalSize.width.toInt();
    var Coord1 = await controller.getLatLng(ScreenCoordinate(x: 0, y: 0));
    var Coord2 = await controller.getLatLng(ScreenCoordinate(x: width, y: 0));
    var Coord3 = await controller.getLatLng(ScreenCoordinate(x: 0, y: height));
    var Coord4 =
        await controller.getLatLng(ScreenCoordinate(x: width, y: height));

    var Crimes = await fetchCrimesFromUKDataset(Coord1, Coord2, Coord3, Coord4);

    markers.clear();
    _addMarkers(Crimes);
    // print(Coords.)
    // controller.getLatLng(screenCoordinate)
  }

  void _addMarkers(List<Crime> crimes) {
    for (int i = 0; i < crimes.length; i++) {
      //without default pin
      if (images.containsKey(crimes[i].category)) {
        var markerId = MarkerId(i.toString());
        final Marker marker = Marker(
            markerId: markerId,
            position: LatLng(
              double.parse(crimes[i].latitude),
              double.parse(crimes[i].longitude),
            ),
            infoWindow: InfoWindow(title: crimes[i].category),
            icon: BitmapDescriptor.fromBytes(images[crimes[i].category]!));

        setState(() {
          markers[markerId] = marker;
        });
      }

      // setState(() {
      //   markers[markerId] = marker;
      // });

      // //with default pin
      // for (int i = 0; i < crimes.length; i++) {
      //   var markerId = MarkerId(i.toString());
      //   final Marker marker = Marker(
      //     markerId: markerId,
      //     position: LatLng(
      //       double.parse(crimes[i].latitude),
      //       double.parse(crimes[i].longitude),
      //     ),
      //     infoWindow: InfoWindow(title: crimes[i].category),
      //     icon: images.containsKey(crimes[i].category)
      //         ? BitmapDescriptor.fromBytes(images[crimes[i].category]!)
      //         : BitmapDescriptor.fromBytes(images["default"]!),
      //   );

      //   setState(() {
      //     markers[markerId] = marker;
      //   });
      // }

    }
  }
}
