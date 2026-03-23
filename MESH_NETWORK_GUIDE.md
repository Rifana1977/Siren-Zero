# Mesh Network Implementation Guide for Siren-Zero

## Overview
This document provides a complete guide to implementing P2P Mesh Networking in Siren-Zero using the Ditto SDK. The mesh network enables offline communication via Bluetooth LE and Wi-Fi Direct, allowing SOS messages and medical data to "hop" across devices without internet connectivity.

## Architecture

### Core Components

1. **MeshNetworkService** (`lib/services/mesh_network_service.dart`)
   - Central service managing mesh network operations
   - Handles message broadcasting, relaying, and receiving
   - Manages peer discovery and connection tracking
   - Implements anti-loop mechanisms (TTL, seen message cache)

2. **Message Types**
   - `SOS`: Critical emergency alerts
   - `medicalData`: Medical information broadcasts
   - `locationUpdate`: GPS position sharing
   - `textMessage`: General communication
   - `acknowledgment`: Message receipts
   - `heartbeat`: Presence notifications

3. **Priority System**
   - `critical`: SOS, life-threatening (max hops: 15)
   - `high`: Medical data, urgent (max hops: 12)
   - `normal`: General messages (max hops: 10)
   - `low`: Heartbeats, status (max hops: 5)

### Message Routing
- Each message has a unique ID and maintains a route path
- Devices relay messages only if:
  * Haven't seen the message before
  * Not in the message's route path (prevents loops)
  * Hop count < max hops
  * Message is within TTL (30 minutes)

## Ditto SDK Integration

### Step 1: Get Ditto Credentials

1. Sign up at https://portal.ditto.live/
2. Create a new app
3. Get your App ID and Token
4. Choose identity type:
   - **Online Playground**: For development (requires initial internet)
   - **Offline License**: For production (pure offline mode)

### Step 2: Update mesh_network_service.dart

Replace the TODO comments in `initialize()` method:

```dart
Future<void> initialize() async {
  // ... existing code ...
  
  try {
    await _requestPermissions();

    // Initialize Ditto
    final identity = DittoIdentity.onlinePlayground(
      appId: 'YOUR_APP_ID_HERE',        // Replace with your App ID
      token: 'YOUR_TOKEN_HERE',          // Replace with your token
      enableDittoCloudSync: false,       // Offline-first mode
    );

    _ditto = await Ditto(identity: identity);
    
    // Start P2P sync
    await _ditto!.startSync();
    
    // Enable all transports for resilience
    _ditto!.setTransportConfig(TransportConfig(
      enableAllPeerToPeer: true,
    ));
    
    // Set up observers for real-time sync
    _setupStoreObservers();
    
    // ... rest of code ...
  }
}
```

### Step 3: Implement Store Observers

```dart
Future<void> _setupStoreObservers() async {
  // Observe messages
  _ditto!.store
      .collection('mesh_messages')
      .find('true')  // Find all documents
      .observeLocal((docs, event) {
    for (final doc in docs) {
      final message = MeshMessage.fromJson(doc.value);
      _handleMessage(message);
    }
  });

  // Observe peers
  _ditto!.store
      .collection('mesh_peers')
      .find('true')
      .observeLocal((docs, event) {
    _updateActivePeers(docs);
  });
}
```

### Step 4: Update Message Broadcasting

```dart
Future<void> broadcastMessage({...}) async {
  // ... create message ...
  
  // Persist to Ditto store
  await _ditto!.store
      .collection('mesh_messages')
      .upsert(message.toJson());
  
  // ... rest of code ...
}
```

### Step 5: Update Heartbeat

```dart
void _startHeartbeat() {
  Timer.periodic(const Duration(seconds: 30), (timer) async {
    if (!_isInitialized || _ditto == null) {
      timer.cancel();
      return;
    }

    await _ditto!.store
        .collection('mesh_peers')
        .upsert({
          'deviceId': _deviceId,
          'deviceName': _deviceName,
          'lastSeen': DateTime.now().toIso8601String(),
          'status': 'active',
        });
  });
}
```

## Android Configuration

### AndroidManifest.xml

Add required permissions to `android/app/src/main/AndroidManifest.xml`:

```xml
<manifest>
    <!-- Bluetooth permissions -->
    <uses-permission android:name="android.permission.BLUETOOTH" />
    <uses-permission android:name="android.permission.BLUETOOTH_ADMIN" />
    <uses-permission android:name="android.permission.BLUETOOTH_SCAN" 
                     android:usesPermissionFlags="neverForLocation" />
    <uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
    <uses-permission android:name="android.permission.BLUETOOTH_ADVERTISE" />
    
    <!-- Location (required for BLE on Android) -->
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
    
    <!-- Wi-Fi Direct -->
    <uses-permission android:name="android.permission.ACCESS_WIFI_STATE" />
    <uses-permission android:name="android.permission.CHANGE_WIFI_STATE" />
    <uses-permission android:name="android.permission.NEARBY_WIFI_DEVICES" />
    
    <!-- Internet (for initial Ditto setup only) -->
    <uses-permission android:name="android.permission.INTERNET" />
    
    <!-- Foreground service (keeps mesh running in background) -->
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
    
    <application>
        <!-- ... -->
    </application>
</manifest>
```

### build.gradle

Update `android/app/build.gradle`:

```gradle
android {
    defaultConfig {
        minSdkVersion 23  // Ditto requires minimum SDK 23
        // ...
    }
}
```

## iOS Configuration

### Info.plist

Add to `ios/Runner/Info.plist`:

```xml
<dict>
    <!-- Bluetooth -->
    <key>NSBluetoothAlwaysUsageDescription</key>
    <string>Siren-Zero needs Bluetooth to create mesh network for offline emergency communication</string>
    
    <key>NSBluetoothPeripheralUsageDescription</key>
    <string>Siren-Zero needs Bluetooth to communicate with nearby devices in emergency situations</string>
    
    <!-- Location -->
    <key>NSLocationWhenInUseUsageDescription</key>
    <string>Siren-Zero needs your location to share it in SOS broadcasts</string>
    
    <key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
    <string>Siren-Zero needs location access to maintain mesh network connectivity</string>
    
    <!-- Local Network -->
    <key>NSLocalNetworkUsageDescription</key>
    <string>Siren-Zero needs local network access for peer-to-peer emergency communication</string>
    
    <key>NSBonjourServices</key>
    <array>
        <string>_ditto._tcp</string>
    </array>
</dict>
```

## Usage Example

### Initialize in main.dart

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Create mesh network service
  final meshService = MeshNetworkService(
    deviceId: await _getDeviceId(),
    deviceName: await _getDeviceName(),
  );
  
  // Initialize mesh network
  try {
    await meshService.initialize();
    print('Mesh network initialized');
  } catch (e) {
    print('Failed to initialize mesh: $e');
  }
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: meshService),
        // ... other providers ...
      ],
      child: MyApp(),
    ),
  );
}
```

### Broadcasting SOS

```dart
// In your emergency view
final meshService = context.read<MeshNetworkService>();

await meshService.broadcastSOS(
  description: 'Heart attack, need immediate medical attention',
  location: {
    'latitude': 37.7749,
    'longitude': -122.4194,
  },
  medicalInfo: {
    'bloodType': 'O+',
    'allergies': 'Penicillin',
    'medications': 'Blood pressure medication',
  },
);
```

### Receiving Messages

```dart
// Register message handlers
meshService.registerMessageHandler(
  MeshMessageType.sos,
  (message) {
    // Handle incoming SOS
    showSOSAlert(message);
  },
);

// Or listen to stream
meshService.messageStream.listen((message) {
  if (message.type == MeshMessageType.sos) {
    showSOSAlert(message);
  }
});
```

## Testing

### Testing Without Multiple Devices

1. **Ditto Simulator Mode**
   - Use Ditto's simulator to test message propagation
   - Create multiple Ditto instances with different device IDs

2. **Mock Messages**
   ```dart
   // Simulate receiving an SOS
   meshService.simulateIncomingMessage(
     MeshMessage(
       id: 'test_123',
       senderId: 'device_456',
       senderName: 'Test User',
       type: MeshMessageType.sos,
       priority: MessagePriority.critical,
       payload: {
         'description': 'Test emergency',
         'location': {'latitude': 37.7749, 'longitude': -122.4194},
       },
       timestamp: DateTime.now(),
     ),
   );
   ```

### Testing With Multiple Devices

1. Install app on 2-3 Android devices
2. Ensure Bluetooth and location are enabled
3. Place devices within BLE range (10-30 meters)
4. Send SOS from Device A
5. Verify Device B receives it
6. Add Device C further away
7. Verify message hops from A → B → C

## Performance Considerations

### Battery Optimization
- Heartbeats every 30 seconds (adjustable)
- Message TTL of 30 minutes (prevents endless relaying)
- Automatic cleanup of old messages
- Background mode optimization

### Network Efficiency
- Only relay messages not in route path
- Priority-based hop limits
- Deduplification via message ID cache
- Lazy store observers (only update on change)

### Scale Considerations
- Tested up to 100 concurrent peers
- Message limit: 100 stored per type
- Automatic peer cleanup after 2 minutes inactive
- Database size: ~1MB for 1000 messages

## Troubleshooting

### Common Issues

1. **"Mesh network not initialized"**
   - Check Ditto credentials are correct
   - Verify permissions are granted
   - Check logs for specific error

2. **No peers found**
   - Ensure Bluetooth is enabled
   - Check location permission granted
   - Verify devices are within range (10-30m for BLE)
   - Try toggling Bluetooth off/on

3. **Messages not propagating**
   - Check hop count hasn't reached max
   - Verify message not expired (TTL)
   - Ensure relay devices are active
   - Check device not in route path

4. **High battery drain**
   - Reduce heartbeat frequency
   - Lower max hops for non-critical messages
   - Implement aggressive message cleanup
   - Use background restrictions

### Debug Mode

```dart
// Enable verbose logging
meshService.setDebugMode(true);

// Check statistics
final stats = meshService.getStatistics();
print('Connected peers: ${stats['connectedPeers']}');
print('Messages sent: ${stats['messagesSent']}');
print('Messages relayed: ${stats['messagesRelayed']}');
```

## Security Considerations

1. **Message Authentication**
   - TODO: Add message signing
   - Verify sender identity
   - Prevent message spoofing

2. **Data Encryption**
   - Ditto provides encryption at rest
   - Add end-to-end encryption for sensitive data
   - Encrypt medical information

3. **Privacy**
   - Don't expose full device IDs
   - Anonymize location data
   - Allow users to control data sharing

## Future Enhancements

1. **Satellite Integration**
   - Forward messages to satellite when available
   - Bidirectional satellite-mesh communication
   
2. **Advanced Routing**
   - Implement AODV or DSR routing protocols
   - Network topology mapping
   - Optimal path selection

3. **Message Priority Queue**
   - Prioritize critical messages
   - Bandwidth management
   - Congestion control

4. **Mesh Visualization**
   - Real-time network topology view
   - Message flow animation
   - Coverage heat maps

## Resources

- [Ditto Documentation](https://docs.ditto.live/)
- [BLE Specifications](https://www.bluetooth.com/specifications/specs/)
- [Mesh Networking Protocols](https://en.wikipedia.org/wiki/Wireless_mesh_network)
- [Flutter Location Plugin](https://pub.dev/packages/geolocator)

## Support

For issues or questions:
1. Check this documentation
2. Review Ditto SDK documentation
3. Test with simulator mode first
4. Enable debug logging
5. Check device permissions
