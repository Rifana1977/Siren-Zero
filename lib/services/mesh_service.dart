import 'dart:typed_data';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:permission_handler/permission_handler.dart';

class MeshService {
  static final MeshService _instance = MeshService._internal();
  factory MeshService() => _instance;
  MeshService._internal(){
  print("🚀 MeshService initialized");
  }
  final Strategy strategy = Strategy.P2P_POINT_TO_POINT;

  // 🔥 Only store endpoint IDs (no ConnectionInfo needed)
  Set<String> connectedDevices = {};

  Function(String message)? onMessageReceived;

  // 🔥 Request permissions
  Future<void> initPermissions() async {
    await Permission.location.request();
    await Permission.bluetooth.request();
    await Permission.bluetoothScan.request();
    await Permission.bluetoothConnect.request();
    await Permission.bluetoothAdvertise.request(); // 🔥 ADD THIS
    await Permission.nearbyWifiDevices.request();
  }

  // 🔥 Start Advertising (Host)
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
              print("📩 RECEIVED: $msg");
              _handleMessage(msg);
            }
          },
        );
      },
      onConnectionResult: (id, status) {
        if (status == Status.CONNECTED) {
          connectedDevices.add(id); // ✅ FIXED
        }
      },
      onDisconnected: (id) {
        connectedDevices.remove(id);
      },
    );
  }

  // 🔥 Start Discovery (Find devices)
  Future<void> startDiscovery() async {
    print("🔍 Discovery started");
    await Nearby().startDiscovery(
      "SirenZero",
      strategy,
      onEndpointFound: (id, name, serviceId) {
        print("🔥 FOUND DEVICE: $id $name");
        // ✅ Prevent duplicate connection
        if (connectedDevices.contains(id)) {
          print("⚠️ Already connected to $id");
          return;
        }
        Nearby().requestConnection(
          "User",
          id,
          onConnectionInitiated: (id, info) {
            print("CONNECTION INITIATED: $id");
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
            print("STATUS: $status");
            if (status == Status.CONNECTED) {
              connectedDevices.add(id); // ✅ FIXED
              print("Connected to $id");
            }
          },
          onDisconnected: (id) {
            connectedDevices.remove(id);
          },
        );
      },
      onEndpointLost: (id) {},
    );
  }

  // 🔥 Send message to all connected peers
  Future<void> sendMessage(String message) async {
  Uint8List bytes = Uint8List.fromList(message.codeUnits);

  print("📤 SENDING: $message to ${connectedDevices.length} devices");

  for (var id in connectedDevices) {
    try {
      await Nearby().sendBytesPayload(id, bytes);
      print("✅ SENT TO: $id"); // 🔥 ADD
    } catch (e) {
      print("❌ SEND FAILED TO $id: $e");
    }
  }
}

  // 🔥 MESH LOGIC (basic relay + dedup)
  Set<String> receivedMessages = {};

  void _handleMessage(String msg) {
  if (receivedMessages.contains(msg)) return;

  receivedMessages.add(msg);

  print("📩 RECEIVED: $msg");

  if (onMessageReceived != null) {
    onMessageReceived!(msg);
  }
}

  // 🔥 Stop everything (optional cleanup)
  void stopAll() {
    Nearby().stopAllEndpoints();
    Nearby().stopAdvertising();
    Nearby().stopDiscovery();
  }
}