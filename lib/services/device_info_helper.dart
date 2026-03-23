import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// Helper class for device identification in mesh network
class DeviceInfoHelper {
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  static const _uuid = Uuid();
  
  /// Get unique device ID for mesh network
  /// Generates stable ID that persists across app sessions
  static Future<String> getDeviceId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Check if we already have a stored ID
      String? storedId = prefs.getString('mesh_device_id');
      if (storedId != null && storedId.isNotEmpty) {
        return storedId;
      }
      
      // Generate new ID based on platform
      String deviceId;
      
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        // Use device ID if available, otherwise generate UUID
        deviceId = androidInfo.id.isNotEmpty 
            ? 'android_${androidInfo.id}'
            : 'android_${_uuid.v4()}';
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        // iOS doesn't provide stable device ID, use UUID
        deviceId = 'ios_${iosInfo.identifierForVendor ?? _uuid.v4()}';
      } else {
        // Web or other platforms
        deviceId = 'unknown_${_uuid.v4()}';
      }
      
      // Store for future use
      await prefs.setString('mesh_device_id', deviceId);
      
      return deviceId;
    } catch (e) {
      debugPrint('Error getting device ID: $e');
      // Fallback to random UUID
      final fallbackId = 'fallback_${_uuid.v4()}';
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('mesh_device_id', fallbackId);
      } catch (_) {}
      return fallbackId;
    }
  }
  
  /// Get human-readable device name for mesh network
  static Future<String> getDeviceName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Check if user has set a custom name
      String? customName = prefs.getString('mesh_device_name');
      if (customName != null && customName.isNotEmpty) {
        return customName;
      }
      
      // Generate name from device info
      String deviceName;
      
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        final manufacturer = androidInfo.manufacturer;
        final model = androidInfo.model;
        deviceName = '${manufacturer.isNotEmpty ? manufacturer : "Android"} ${model.isNotEmpty ? model : "Device"}';
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        final name = iosInfo.name;
        final model = iosInfo.model;
        deviceName = '${name.isNotEmpty ? name : "iOS"} ${model.isNotEmpty ? model : "Device"}';
      } else {
        deviceName = 'Unknown Device';
      }
      
      return deviceName;
    } catch (e) {
      debugPrint('Error getting device name: $e');
      return 'Unknown Device';
    }
  }
  
  /// Set custom device name for mesh network
  static Future<void> setDeviceName(String name) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('mesh_device_name', name);
    } catch (e) {
      debugPrint('Error setting device name: $e');
    }
  }
  
  /// Get comprehensive device info for debugging
  static Future<Map<String, dynamic>> getDeviceInfo() async {
    final info = <String, dynamic>{};
    
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        info.addAll({
          'platform': 'Android',
          'manufacturer': androidInfo.manufacturer,
          'model': androidInfo.model,
          'version': androidInfo.version.release,
          'sdk': androidInfo.version.sdkInt,
          'device': androidInfo.device,
          'brand': androidInfo.brand,
        });
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        info.addAll({
          'platform': 'iOS',
          'name': iosInfo.name,
          'model': iosInfo.model,
          'systemName': iosInfo.systemName,
          'systemVersion': iosInfo.systemVersion,
          'localizedModel': iosInfo.localizedModel,
        });
      }
      
      info['deviceId'] = await getDeviceId();
      info['deviceName'] = await getDeviceName();
    } catch (e) {
      debugPrint('Error getting device info: $e');
    }
    
    return info;
  }
  
  /// Check if device supports mesh networking
  static Future<MeshCapabilities> checkMeshCapabilities() async {
    final capabilities = MeshCapabilities();
    
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        // Android 6.0 (API 23) and above support BLE
        capabilities.hasBluetooth = androidInfo.version.sdkInt >= 23;
        // Android 4.1 (API 16) and above support Wi-Fi Direct
        capabilities.hasWifiDirect = androidInfo.version.sdkInt >= 16;
        capabilities.isSupported = capabilities.hasBluetooth;
      } else if (Platform.isIOS) {
        // iOS 5.0 and above support BLE
        // All modern iOS devices support mesh networking
        capabilities.hasBluetooth = true;
        capabilities.hasWifiDirect = false; // iOS doesn't support Wi-Fi Direct
        capabilities.isSupported = true;
      } else {
        capabilities.isSupported = false;
      }
    } catch (e) {
      debugPrint('Error checking capabilities: $e');
      capabilities.isSupported = false;
    }
    
    return capabilities;
  }
  
  /// Reset device identity (use with caution)
  static Future<void> resetDeviceIdentity() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('mesh_device_id');
      await prefs.remove('mesh_device_name');
    } catch (e) {
      debugPrint('Error resetting device identity: $e');
    }
  }
}

/// Mesh networking capabilities of the device
class MeshCapabilities {
  bool isSupported = false;
  bool hasBluetooth = false;
  bool hasWifiDirect = false;
  String? unsupportedReason;
  
  Map<String, dynamic> toJson() => {
    'isSupported': isSupported,
    'hasBluetooth': hasBluetooth,
    'hasWifiDirect': hasWifiDirect,
    'unsupportedReason': unsupportedReason,
  };
  
  @override
  String toString() {
    if (isSupported) {
      final features = <String>[];
      if (hasBluetooth) features.add('BLE');
      if (hasWifiDirect) features.add('Wi-Fi Direct');
      return 'Mesh networking supported: ${features.join(', ')}';
    } else {
      return 'Mesh networking not supported${unsupportedReason != null ? ': $unsupportedReason' : ''}';
    }
  }
}
