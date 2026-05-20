import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../services/mqtt_service.dart';

class UserScreen extends StatefulWidget {
  const UserScreen({super.key});

  @override
  State<UserScreen> createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {

  final MQTTService mqttService = MQTTService(
    clientId: dotenv.env['MQTT_CLIENT_ID_USER'] ?? 'user_client',
  );

  GoogleMapController? mapController;

  BitmapDescriptor? vanMarkerIcon;

  LatLng? currentPosition = MQTTService.lastKnownLocation;

  bool hasReceivedLocation = MQTTService.lastKnownLocation != null;

  @override
  void initState() {
    super.initState();

    loadVanMarkerIcon();
    connectMQTT();
  }

  Future<void> loadVanMarkerIcon() async {
    final icon = await _createVanMarkerIcon();

    if (!mounted) {
      return;
    }

    setState(() {
      vanMarkerIcon = icon;
    });
  }

  Future<BitmapDescriptor> _createVanMarkerIcon() async {
    const double size = 120;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final center = Offset(size / 2, size / 2);

    final circlePaint = Paint()
      ..color = Color(0xFF1565C0)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, size / 2, circlePaint);

    final iconPainter = TextPainter(textDirection: TextDirection.ltr);
    iconPainter.text = TextSpan(
      text: String.fromCharCode(Icons.local_shipping.codePoint),
      style: TextStyle(
        fontSize: 72,
        fontFamily: Icons.local_shipping.fontFamily,
        package: Icons.local_shipping.fontPackage,
        color: Colors.white,
      ),
    );
    iconPainter.layout();
    iconPainter.paint(
      canvas,
      Offset(
        (size - iconPainter.width) / 2,
        (size - iconPainter.height) / 2,
      ),
    );

    final image = await recorder.endRecording().toImage(
      size.toInt(),
      size.toInt(),
    );
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    return BitmapDescriptor.fromBytes(byteData!.buffer.asUint8List());
  }

  Future<void> connectMQTT() async {

    mqttService.onLocationUpdate = (lat, lng) {

      print("Updating UI: $lat, $lng");

      final newPosition = LatLng(lat, lng);

      setState(() {
        currentPosition = newPosition;
        hasReceivedLocation = true;
      });

      mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: newPosition,
            zoom: 16,
          ),
        ),
      );
    };

    await mqttService.connect();

    mqttService.subscribeToLocation();
  }

  @override
  Widget build(BuildContext context) {

    if (!hasReceivedLocation) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("User"),
      ),

      body: GoogleMap(

        initialCameraPosition: CameraPosition(
          target: currentPosition!,
          zoom: 16,
        ),

        onMapCreated: (controller) {
          mapController = controller;
        },

        markers: {
          Marker(
            markerId: const MarkerId("van"),
            position: currentPosition!,
            icon: vanMarkerIcon ?? BitmapDescriptor.defaultMarker,
          ),
        },
      ),
    );
  }
}