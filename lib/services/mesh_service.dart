import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:permission_handler/permission_handler.dart';

class MeshService {
  static final MeshService _instance = MeshService._internal();
  factory MeshService() => _instance;

  MeshService._internal() {
    print("🚀 MeshService initialized");
  }

  final Strategy strategy = Strategy.P2P_POINT_TO_POINT;

  Set<String> connectedDevices = {};
  Set<String> receivedMessages = {};

  Function(String message)? onMessageReceived;
  VoidCallback? onDevicesChanged; // 🔥 UI update trigger

  // 🔥 Permissions
  Future<void> initPermissions() async {
    await Permission.location.request();
    await Permission.bluetooth.request();
    await Permission.bluetoothScan.request();
    await Permission.bluetoothConnect.request();
    await Permission.bluetoothAdvertise.request();
    await Permission.nearbyWifiDevices.request();
  }

  // 🔥 Advertising (host)
  Future<void> startAdvertising() async {
    await Nearby().startAdvertising(
      "SirenZero",
      strategy,
      onConnectionInitiated: (id, info) {
        Nearby().acceptConnection(
          id,
          onPayLoadRecieved: (endid, payload) {
            if (payload.type == PayloadType.BYTES) {
              String msg = String.fromCharCodes(payload.bytes!);
              _handleMessage(msg);
            }
          },
        );
      },
      onConnectionResult: (id, status) {
        print("📡 STATUS: $status");

        if (status == Status.CONNECTED) {
          connectedDevices.add(id);
          onDevicesChanged?.call(); // 🔥 update UI
          print("✅ CONNECTED: $id");
        }
      },
      onDisconnected: (id) {
        connectedDevices.remove(id);
        onDevicesChanged?.call(); // 🔥 update UI
        print("❌ DISCONNECTED: $id");
      },
    );
  }

  // 🔥 Discovery
  Future<void> startDiscovery() async {
    print("🔍 Discovery started");

    await Nearby().startDiscovery(
      "SirenZero",
      strategy,
      onEndpointFound: (id, name, serviceId) {
  print("🔥 FOUND DEVICE: $id $name");

  // ❌ avoid duplicate
  if (connectedDevices.contains(id)) return;

  print("⚡ AUTO CONNECTING TO: $id");

  Nearby().requestConnection(
    "AutoUser",
    id,
    onConnectionInitiated: (id, info) {
      Nearby().acceptConnection(
        id,
        onPayLoadRecieved: (endid, payload) {
          if (payload.type == PayloadType.BYTES) {
            String msg = String.fromCharCodes(payload.bytes!);
            _handleMessage(msg);
          }
        },
      );
    },
    onConnectionResult: (id, status) {
      print("📡 STATUS: $status");

      if (status == Status.CONNECTED) {
        connectedDevices.add(id);
        onDevicesChanged?.call();
        print("✅ AUTO CONNECTED: $id");
      }
    },
    onDisconnected: (id) {
      connectedDevices.remove(id);
      onDevicesChanged?.call();
    },
  );
},
      onEndpointLost: (id) {},
    );
  }

  // 🔥 Send message
  Future<void> sendMessage(String message) async {
    Uint8List bytes = Uint8List.fromList(message.codeUnits);

    for (var id in connectedDevices) {
      try {
        await Nearby().sendBytesPayload(id, bytes);
        print("📤 SENT TO: $id");
      } catch (e) {
        print("❌ SEND FAILED: $e");
      }
    }
  }

  // 🔥 Receive handler
  void _handleMessage(String msg) {
    print("🔥 GLOBAL RECEIVED: $msg"); // ✅ ADD THIS

    if (receivedMessages.contains(msg)) return;

    receivedMessages.add(msg);

    if (onMessageReceived != null) {
      onMessageReceived!(msg);
  }
}

  void stopAll() {
    Nearby().stopAllEndpoints();
    Nearby().stopAdvertising();
    Nearby().stopDiscovery();
  }
}