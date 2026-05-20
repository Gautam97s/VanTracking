import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';

import '../services/mqtt_service.dart';

class DriverScreen extends StatefulWidget {
  const DriverScreen({super.key});

  @override
  State<DriverScreen> createState() => _DriverScreenState();
}

class _DriverScreenState extends State<DriverScreen> {

  final MQTTService mqttService = MQTTService(
    clientId: dotenv.env['MQTT_CLIENT_ID_DRIVER'] ?? 'driver_client',
  );

  bool isBroadcasting = false;

  @override
  void initState() {
    super.initState();

    connectMQTT();
  }

  Future<void> connectMQTT() async {
    await mqttService.connect();
  }

  void startBroadcasting() async {

    LocationPermission permission;

    permission = await Geolocator.requestPermission();

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return;
    }

    setState(() {
      isBroadcasting = true;
    });

    final currentPosition = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    mqttService.publishLocation(
      currentPosition.latitude,
      currentPosition.longitude,
    );

    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen((Position position) {

      print(
        "GPS: "
        "${position.latitude}, "
        "${position.longitude}"
      );

      mqttService.publishLocation(
        position.latitude,
        position.longitude,
      );
    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text("Driver"),
      ),

      body: Center(
        child: ElevatedButton(

          onPressed: isBroadcasting
              ? null
              : startBroadcasting,

          child: Text(
            isBroadcasting
                ? "Broadcasting..."
                : "Start Broadcasting",
          ),
        ),
      ),
    );
  }
}