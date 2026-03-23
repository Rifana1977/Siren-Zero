import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:siren_zero/services/mesh_network_service.dart';
import 'package:siren_zero/services/device_info_helper.dart';
import 'package:siren_zero/services/model_service.dart';
import 'package:siren_zero/theme/app_theme.dart';
import 'package:siren_zero/views/siren_zero_home_view.dart';
import 'package:siren_zero/views/mesh_sos_view.dart';
import 'package:siren_zero/views/mesh_sos_monitor_view.dart';
import 'package:runanywhere/runanywhere.dart';
import 'package:runanywhere_llamacpp/runanywhere_llamacpp.dart';
import 'package:runanywhere_onnx/runanywhere_onnx.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize the AI Brain
  await RunAnywhere.initialize();
  await LlamaCpp.register();
  await Onnx.register();
  ModelService.registerDefaultModels();

  // 2. Request all permissions for Android 13/16
  Map<Permission, PermissionStatus> statuses = await [
    Permission.location,
    Permission.bluetoothScan,
    Permission.bluetoothConnect,
    Permission.bluetoothAdvertise,
    Permission.nearbyWifiDevices,
  ].request();

  debugPrint('📍 Location Status: ${statuses[Permission.location]}');
  debugPrint('📍 Bluetooth Status: ${statuses[Permission.bluetoothScan]}');

  // 3. Initialize Mesh Network (The Nerves)
  MeshNetworkService? meshService;
  try {
    final deviceId = await DeviceInfoHelper.getDeviceId();
    final deviceName = await DeviceInfoHelper.getDeviceName();
    
    meshService = MeshNetworkService(
      deviceId: deviceId,
      deviceName: deviceName,
    );
    
    // 📍 THE FIX: We call initialize regardless of the "denied" status.
    // This allows the P2P radio to start using whatever permissions it HAS.
    await meshService.initialize();
    debugPrint('✅ Mesh network successfully forced: $deviceId');

  } catch (e) {
    debugPrint('⚠️ Mesh initialization failed: $e');
    // Ensure we still provide a service object to the Provider to prevent UI crashes
    meshService = MeshNetworkService(
      deviceId: 'fallback',
      deviceName: 'Offline Device',
    );
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ModelService()),
        ChangeNotifierProvider.value(value: meshService), 
      ],
      child: const SirenZeroApp(),
    ),
  );
}

class SirenZeroApp extends StatelessWidget {
  const SirenZeroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Siren-Zero',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const SirenZeroHomeView(),
      routes: {
        '/mesh-sos': (context) => const MeshSOSView(),
        '/mesh-sos-monitor': (context) => const MeshSOSMonitorView(),
      },
    );
  }
}