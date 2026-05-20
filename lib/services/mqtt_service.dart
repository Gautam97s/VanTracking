import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class MQTTService {

  MQTTService({required this.clientId});

  final String clientId;

  late MqttServerClient client;

  Function(double lat, double lng)? onLocationUpdate;

  static LatLng? lastKnownLocation;

  String _envString(String key, String fallback) {
    return dotenv.env[key] ?? fallback;
  }

  int _envInt(String key, int fallback) {
    return int.tryParse(dotenv.env[key] ?? '') ?? fallback;
  }

  Future<void> connect() async {

    final host = _envString(
      'MQTT_HOST',
      'efcf1900.ala.asia-southeast1.emqxsl.com',
    );
    final port = _envInt('MQTT_PORT', 8883);
    final username = _envString('MQTT_USERNAME', 'gautam');
    final password = _envString('MQTT_PASSWORD', 'Gautam2005');

    client = MqttServerClient.withPort(
      host,
      clientId,
      port,
    );

    client.secure = true;

    client.keepAlivePeriod = 20;

    client.logging(on: true);

    client.onConnected = () {
      print("MQTT Connected");
    };

    client.onDisconnected = () {
      print("MQTT Disconnected");
    };

    client.connectionMessage = MqttConnectMessage()
      .withClientIdentifier(clientId)
        .startClean();

    try {

      await client.connect(username, password);

      print("Connection Successful");

    } catch (e) {

      print("Connection Error: $e");

      client.disconnect();
    }
  }

  void publishLocation(double lat, double lng) {
    lastKnownLocation = LatLng(lat, lng);

    final locationTopic = _envString('MQTT_LOCATION_TOPIC', 'van/1/location');

    print(
      "MQTT State: "
      "${client.connectionStatus?.state}"
    );

    if (client.connectionStatus?.state !=
        MqttConnectionState.connected) {

      print("MQTT Not Connected");

      return;
    }

    final builder = MqttClientPayloadBuilder();

    builder.addString(
      jsonEncode({
        "lat": lat,
        "lng": lng,
        "time": DateTime.now().toString(),
      }),
    );

    client.publishMessage(
      locationTopic,
      MqttQos.atLeastOnce,
      builder.payload!,
      retain: true,
    );

    print("Location Published");
  }

  void subscribeToLocation() {

    final locationTopic = _envString('MQTT_LOCATION_TOPIC', 'van/1/location');

    print("Subscribing...");

    client.subscribe(
      locationTopic,
      MqttQos.atLeastOnce,
    );

    client.updates!.listen((messages) {

      print("Message Received");

      final recMess =
      messages[0].payload as MqttPublishMessage;

      final payload =
      MqttPublishPayload.bytesToStringAsString(
        recMess.payload.message,
      );

      print(payload);

      final data = jsonDecode(payload);

      final lat = (data["lat"] as num).toDouble();
      final lng = (data["lng"] as num).toDouble();

      print("Parsed: $lat, $lng");

      onLocationUpdate?.call(lat, lng);
    });
  }
}