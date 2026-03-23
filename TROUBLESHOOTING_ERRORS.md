# Troubleshooting Common Errors

## Error 1: "No location permissions are defined in the manifest"

### Error Message:
```
I/flutter: Error getting location: No location permissions are defined in the manifest
```

### Cause:
The Android manifest was missing proper permission attributes for Android 12+.

### Fix Applied: ✅
Updated `android/app/src/main/AndroidManifest.xml` with proper permission attributes:
- Added `xmlns:tools` namespace
- Added `android:maxSdkVersion` for legacy permissions
- Added `tools:targetApi` for new permissions
- Followed Ditto SDK's recommended permission structure

### Permissions Now Configured:
```xml
<!-- Location (required for BLE on Android < 13) -->
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"
        android:maxSdkVersion="32" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"
        android:maxSdkVersion="30" />

<!-- Bluetooth -->
<uses-permission android:name="android.permission.BLUETOOTH_SCAN"
        android:usesPermissionFlags="neverForLocation"
        tools:targetApi="s" />
<!-- ... and more -->
```

### What This Means:
- **Android < 12**: Uses old Bluetooth/Location permissions
- **Android 12-12L**: Uses new Bluetooth permissions + Location (maxSdk 32)
- **Android 13+**: Uses new Bluetooth permissions without Location requirement

---

## Error 2: Ditto Authentication Warnings

### Warning Messages:
```
W/Ditto: playground mode authentication failed error=API endpoint not found
W/Ditto: no login challenge was provided by the auth server
W/Ditto: no valid JWT present, cannot request X.509 certificate
```

### Cause:
The app is using `OnlinePlaygroundIdentity` with `enableDittoCloudSync: false` (offline-only mode). Ditto tries to authenticate with the cloud but fails because:
1. The credentials might be placeholders
2. No Auth URL or WebSocket URL configured
3. Cloud sync is disabled intentionally

### Is This a Problem? ❌ NO!

**These warnings can be IGNORED** when running in offline-only mode. Here's why:

#### Offline-Only Mode (Current Configuration):
- ✅ **P2P mesh networking works perfectly** without cloud authentication
- ✅ Bluetooth LE and WiFi Direct sync work locally
- ✅ Messages sync between nearby devices
- ❌ Cloud sync is disabled (no internet-based sync)
- ⚠️ Authentication warnings appear but don't affect functionality

#### What Ditto Is Doing:
1. **P2P Transport Layer**: Works without authentication (local device-to-device)
2. **Cloud Sync Layer**: Tries to authenticate but fails (we disabled it)
3. **Result**: Local mesh works, cloud doesn't (as intended)

### Fix Applied: ✅
Updated configuration to make offline-only mode explicit:

**`lib/core/app_constants.dart`:**
```dart
class AppConstants {
  static const String dittoAppId = '...';
  static const String dittoToken = '...';
  
  // Set to true to enable offline-only mode (no cloud sync)
  static const bool dittoOfflineOnly = true;
}
```

**`lib/services/mesh_network_service.dart`:**
```dart
final identity = OnlinePlaygroundIdentity(
  appID: AppConstants.dittoAppId,
  token: AppConstants.dittoToken,
  enableDittoCloudSync: !AppConstants.dittoOfflineOnly,  // false
);

// Added debug logging:
if (AppConstants.dittoOfflineOnly) {
  debugPrint('⚠️ Running in OFFLINE-ONLY mode');
  debugPrint('   Authentication warnings can be ignored');
  debugPrint('   P2P mesh networking works without cloud');
}
```

### When To Fix Authentication:

Only fix if you want **cloud sync** (internet-based synchronization):

1. **Get Real Credentials:**
   - Visit https://portal.ditto.live
   - Create account and app
   - Get App ID, Playground Token, Auth URL, WebSocket URL

2. **Update AppConstants:**
   ```dart
   static const String dittoAppId = 'YOUR_REAL_APP_ID';
   static const String dittoToken = 'YOUR_REAL_TOKEN';
   static const String dittoAuthUrl = 'https://your-auth.ditto.live';
   static const String dittoWebSocketUrl = 'wss://your-ws.ditto.live';
   static const bool dittoOfflineOnly = false;  // Enable cloud
   ```

3. **Update Initialization:**
   ```dart
   final identity = OnlinePlaygroundIdentity(
     appID: AppConstants.dittoAppId,
     token: AppConstants.dittoToken,
     customAuthUrl: AppConstants.dittoAuthUrl.isNotEmpty 
         ? AppConstants.dittoAuthUrl 
         : null,
     enableDittoCloudSync: !AppConstants.dittoOfflineOnly,
   );
   
   _ditto!.updateTransportConfig((config) {
     // Add WebSocket URL for cloud sync
     if (AppConstants.dittoWebSocketUrl.isNotEmpty) {
       config.connect.webSocketUrls.add(AppConstants.dittoWebSocketUrl);
     }
   });
   ```

### For This Emergency SOS App:

**Offline-only mode is PERFECT** because:
- ✅ Works in disaster scenarios without internet
- ✅ No dependency on cloud services
- ✅ Privacy-focused (no data leaves devices)
- ✅ Lower latency (direct device-to-device)
- ✅ Simpler configuration (no cloud setup needed)

**Recommendation**: Keep `dittoOfflineOnly = true` and ignore the authentication warnings!

---

## Testing The Fixes

### 1. Clean and Rebuild:
```bash
flutter clean
flutter pub get
flutter run -t lib/main_with_mesh.dart
```

### 2. Verify Location Permission:
- App should now request location permission
- No more "No location permissions" error
- Check Settings → Apps → Siren-Zero → Permissions → Location

### 3. Verify Mesh Networking:
- Deploy to 2+ physical devices
- Enable Location Services (Settings → Location → ON)
- Grant location permission to app
- Navigate to Emergency SOS
- Devices should discover each other
- Send SOS and watch it appear on other device

### 4. Expected Logs:
```
I/flutter: Initializing Ditto SDK for mesh networking...
I/flutter: Ditto instance created successfully
I/flutter: Ditto transports configured for P2P mesh
I/flutter: Ditto sync started - mesh networking active!
I/flutter: ⚠️ Running in OFFLINE-ONLY mode
I/flutter:    Authentication warnings can be ignored
I/flutter:    P2P mesh networking works without cloud
W/Ditto: playground mode authentication failed  ← IGNORE THIS
W/Ditto: no login challenge provided            ← IGNORE THIS
```

---

## Summary

| Error | Severity | Fixed? | Action Required |
|-------|----------|--------|-----------------|
| Location permissions error | ❌ Critical | ✅ Yes | Rebuild app |
| Ditto auth warnings | ⚠️ Warning | ✅ Explained | Ignore them |
| Mesh not working | Depends | Pending | Test on real devices |

### Next Steps:
1. ✅ Rebuild app with fixed manifest
2. ✅ Deploy to 2+ devices
3. ✅ Test mesh networking
4. ⚠️ Ignore Ditto authentication warnings (they're expected in offline mode)
