# 🚨 Mesh Network Quick Start Guide

## ⚡ 5-Minute Integration

### 1. Get Ditto Credentials (2 minutes)

1. Go to: https://portal.ditto.live/
2. Sign up / Log in
3. Click "Create New App"
4. Name it "Siren-Zero"
5. Copy your **App ID** and **Token**

### 2. Update Mesh Service (1 minute)

Open `lib/services/mesh_network_service.dart` and find line ~250:

```dart
// TODO: Initialize Ditto SDK here
```

Replace with your Ditto credentials.

### 3. Test It!

```bash
flutter run
```

See full implementation details in `MESH_IMPLEMENTATION_SUMMARY.md`

## 📱 Quick Commands

Navigate to SOS broadcast:
```dart
Navigator.pushNamed(context, '/mesh-sos');
```

Monitor incoming alerts:
```dart
Navigator.pushNamed(context, '/mesh-sos-monitor');
```

## 📚 Documentation

- **Quick Start**: This file
- **Implementation Summary**: `MESH_IMPLEMENTATION_SUMMARY.md` (detailed integration steps)
- **Comprehensive Guide**: `MESH_NETWORK_GUIDE.md` (complete reference)
