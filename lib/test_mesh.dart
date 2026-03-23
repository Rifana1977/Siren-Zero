import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/mesh_network_service.dart';
import 'services/device_info_helper.dart';
import 'views/mesh_network_test_view.dart';
import 'views/mesh_sos_view.dart';
import 'views/mesh_sos_monitor_view.dart';

/// MESH NETWORK TEST RUNNER
/// Use this to test mesh features independently
/// Run with: flutter run -t lib/test_mesh.dart

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  debugPrint('🚀 Initializing Mesh Network Test...');
  
  MeshNetworkService meshService;
  try {
    final deviceId = await DeviceInfoHelper.getDeviceId();
    final deviceName = await DeviceInfoHelper.getDeviceName();
    
    debugPrint('📱 Device ID: $deviceId');
    debugPrint('📱 Device Name: $deviceName');
    
    meshService = MeshNetworkService(
      deviceId: deviceId,
      deviceName: deviceName,
    );
    
    await meshService.initialize();
    debugPrint('✅ Mesh network initialized successfully!');
    debugPrint('🔗 Connected peers: ${meshService.connectedPeersCount}');
  } catch (e) {
    debugPrint('⚠️  Mesh network initialization failed: $e');
    debugPrint('📝 Note: This is OK for testing UI without Ditto credentials');
    debugPrint('💡 You can still test UI by simulating messages!');
    
    // Create fallback service for testing
    meshService = MeshNetworkService(
      deviceId: 'test_device',
      deviceName: 'Test Device',
    );
  }

  runApp(
    ChangeNotifierProvider.value(
      value: meshService,
      child: const MeshTestApp(),
    ),
  );
}

class MeshTestApp extends StatelessWidget {
  const MeshTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mesh Network Test',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const MeshNetworkTestView(),
      routes: {
        '/mesh-sos': (context) => const MeshSOSView(),
        '/mesh-sos-monitor': (context) => const MeshSOSMonitorView(),
      },
    );
  }
}
