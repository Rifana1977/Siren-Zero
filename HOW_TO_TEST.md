# 🚀 TERMINAL TESTING GUIDE - Step by Step

## 🎯 Three Ways to Test (Choose One)

---

## METHOD 1: Quick Test (Easiest - 2 minutes) ⭐ RECOMMENDED

This tests mesh networking in isolation without modifying your main app.

### Step 1: Open Terminal
```bash
cd D:\Siren-Zero
```

### Step 2: Check Everything
```bash
# Make sure packages are installed
flutter pub get

# Check for errors
flutter analyze
```

### Step 3: Connect Your Device
```bash
# List available devices
flutter devices
```

You should see something like:
```
SM G950F (mobile) • XXXXXXXXXX • android-arm64 • Android 10 (API 29)
Chrome (web)      • chrome     • web-javascript • Google Chrome 122.0
Windows (desktop) • windows    • windows-x64    • Microsoft Windows
```

### Step 4: Run the Mesh Test App
```bash
flutter run -t lib/test_mesh.dart
```

### What You'll See:

**In Terminal:**
```
Launching lib\test_mesh.dart on SM G950F...
🚀 Initializing Mesh Network Test...
📱 Device ID: android_abc123xyz
📱 Device Name: Samsung SM-G950F
⚠️  Mesh network initialization failed: Exception: Ditto not configured
📝 Note: This is OK for testing UI without Ditto credentials
💡 You can still test UI by simulating messages!
✓ Built build\app\outputs\flutter-apk\app-debug.apk
Syncing files to device SM G950F...
Flutter run key commands.
r Hot reload. 🔥🔥🔥
R Hot restart.
h List all available interactive commands.
d Detach (terminate "flutter run" but leave application running).
c Clear the screen
q Quit (terminate the application on the device).

Running with sound null safety

An Observatory debugger and profiler on SM G950F is available at: http://127.0.0.1:xxxxx
The Flutter DevTools debugger and profiler on SM G950F is available at: http://127.0.0.1:xxxxx
```

**On Your Phone:**
- Mesh Network Test screen opens
- Shows mesh status (will show "0 peers" without Ditto)
- Test buttons are clickable!

### Step 5: Test the Features

**On your phone, try these buttons:**

1. **"Simulate Incoming SOS"** ← Click this first!
   - You'll see a notification
   - SOS appears in the list below
   - Check the SOS Monitor view

2. **"Open SOS Broadcast View"**
   - Opens the full SOS form
   - Try filling it out (won't actually send without Ditto)

3. **"Open SOS Monitor View"**
   - Shows all SOS messages
   - Should see the simulated one

4. **"View Statistics"**
   - Click the mesh status widget at top
   - See device info and stats

### Terminal Commands During Test:
```bash
r      # Hot reload (reload changes instantly)
R      # Hot restart (restart app)
q      # Quit and stop app
```

---

## METHOD 2: Test with Your Existing App (3 minutes)

This runs your full Siren-Zero app with mesh networking added.

### Step 1: Update Your Main
```bash
# First, backup your current main.dart
cp lib/main.dart lib/main.backup.dart

# Option A: Use the mesh-enabled version
cp lib/main_with_mesh.dart lib/main.dart

# OR Option B: Just run the mesh version directly
flutter run -t lib/main_with_mesh.dart
```

### Step 2: Run
```bash
flutter run
```

### What You'll See:
```
🚀 Starting Siren-Zero with Mesh Network...
✅ Mesh network initialized: android_abc123
📱 Device: Samsung SM-G950F
Launching lib\main.dart on SM G950F...
```

Your Siren-Zero app will open normally, but now with mesh networking running in the background!

---

## METHOD 3: Build APK and Install Manually (5 minutes)

Build an APK you can install and test without USB cable.

### Step 1: Build APK
```bash
# Build debug APK with mesh test
flutter build apk --debug -t lib/test_mesh.dart

# Or build your main app with mesh
flutter build apk --debug -t lib/main_with_mesh.dart
```

### Step 2: Find APK
```bash
# APK will be at:
# D:\Siren-Zero\build\app\outputs\flutter-apk\app-debug.apk

# Copy to desktop or email to yourself
cp build/app/outputs/flutter-apk/app-debug.apk ~/Desktop/mesh-test.apk
```

### Step 3: Install on Phone
1. Enable "Install from Unknown Sources" on your Android phone
2. Transfer APK to phone (USB, email, cloud)
3. Tap APK file to install
4. Open the app

---

## 🧪 Testing Checklist

### ✅ Basic Test (Single Device)
```bash
flutter run -t lib/test_mesh.dart
```

**On Phone:**
- [ ] App opens successfully
- [ ] Mesh status shows at top
- [ ] Click "Simulate Incoming SOS"
- [ ] See notification appear
- [ ] Message appears in list
- [ ] Click "Open SOS Monitor"
- [ ] See the SOS message there

### ✅ Advanced Test (Two Devices)

**Prerequisites:**
- Get Ditto credentials from https://portal.ditto.live/
- Update `lib/services/mesh_network_service.dart` line 250

**Terminal:**
```bash
# Install on Device 1
flutter run -t lib/test_mesh.dart -d DEVICE_1_ID

# Install on Device 2 (in another terminal)
flutter run -t lib/test_mesh.dart -d DEVICE_2_ID
```

**Test:**
- [ ] Both devices show "Connected"
- [ ] Both show "1 peer" in mesh status
- [ ] Device 1: Click "Send Test SOS"
- [ ] Device 2: Receives notification
- [ ] Device 2: See SOS in monitor

---

## 🐛 Common Terminal Issues

### Issue 1: "Unable to locate Android SDK"
```bash
# Check flutter doctor
flutter doctor

# Fix if needed:
flutter doctor --android-licenses
```

### Issue 2: "No devices found"
```bash
# Make sure USB debugging is enabled on phone
# Connect phone via USB
# On phone: Allow USB debugging when prompted

# Check again:
flutter devices
```

### Issue 3: "Gradle build failed"
```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter run -t lib/test_mesh.dart
```

### Issue 4: "Could not find module 'X'"
```bash
# Reinstall dependencies
flutter pub get
flutter pub upgrade

# Check for errors
flutter analyze
```

### Issue 5: App crashes immediately
```bash
# Check terminal output for errors
# Run with verbose logging:
flutter run -t lib/test_mesh.dart -v

# Check device logs:
flutter logs
```

---

## 📊 What to Look for in Terminal

### ✅ Successful Run:
```
✓ Built build\app\outputs\flutter-apk\app-debug.apk
Syncing files to device...
🚀 Initializing Mesh Network Test...
✅ Mesh network initialized successfully!
🔗 Connected peers: 0

Flutter run key commands...
```

### ❌ Failed Run:
```
FAILURE: Build failed with an exception.
[ERROR] Some error message...
```

### ⚠️ Expected Warning (Without Ditto):
```
⚠️ Mesh network initialization failed: Exception...
📝 Note: This is OK for testing UI
```

---

## 🎮 Interactive Commands While Running

While app is running, press these keys in terminal:

```
r    - Hot reload (reload UI changes without restarting)
R    - Hot restart (full restart)
p    - Show performance overlay
P    - Hide performance overlay
o    - Toggle platform
s    - Save screenshot
q    - Quit
h    - Help (show all commands)
```

---

## 📝 Quick Command Reference

```bash
# Basic test
flutter run -t lib/test_mesh.dart

# Specific device
flutter run -t lib/test_mesh.dart -d DEVICE_ID

# Verbose output
flutter run -t lib/test_mesh.dart -v

# With Ditto credentials (after configuring)
flutter run -t lib/test_mesh.dart --release

# Build APK
flutter build apk --debug -t lib/test_mesh.dart

# Check everything
flutter analyze
flutter doctor
flutter devices

# Clean if issues
flutter clean && flutter pub get
```

---

## 🎯 Expected Output Examples

### Terminal Output (Successful):
```
$ flutter run -t lib/test_mesh.dart
Launching lib\test_mesh.dart on SM G950F in debug mode...
Running Gradle task 'assembleDebug'...
✓ Built build\app\outputs\flutter-apk\app-debug.apk
Installing build\app\outputs\flutter-apk\app-debug.apk...
Debug service listening on ws://127.0.0.1:50505/xxxxx

🚀 Initializing Mesh Network Test...
📱 Device ID: android_abc123
📱 Device Name: Samsung SM-G950F
⚠️ Mesh network initialization failed
💡 You can still test UI by simulating messages!

Synced 0.0MB
```

### Phone Screen:
```
┌─────────────────────────────────┐
│ Mesh Network Test               │
│                      🔴 0 peers │
├─────────────────────────────────┤
│ Mesh Network                    │
│ Disconnected                    │
│                                 │
│ Connected Peers: 0              │
│ Messages Sent: 0                │
│ Messages Received: 0            │
│ Messages Relayed: 0             │
├─────────────────────────────────┤
│ Test Actions                    │
│                                 │
│ 🆘 Send Test SOS                │
│ 📥 Simulate Incoming SOS        │
│ 🚨 Open SOS Broadcast View      │
│ 📊 Open SOS Monitor View        │
├─────────────────────────────────┤
│ Send Text Message               │
│ [Type a message...        ]     │
└─────────────────────────────────┘
```

---

## ✅ Success Criteria

You'll know it's working when:

1. ✅ App builds without errors
2. ✅ App opens on your phone
3. ✅ Mesh status widget appears
4. ✅ You can click "Simulate Incoming SOS"
5. ✅ Notification appears
6. ✅ Message shows in list
7. ✅ Can navigate to SOS monitor
8. ✅ Can open SOS broadcast view

---

## 🎉 You're Done!

The mesh network is working! Even without Ditto credentials, you can:
- ✅ Test all UI components
- ✅ See how messages flow
- ✅ Understand the interface
- ✅ Prepare for production deployment

**Next Steps:**
1. Get Ditto credentials for real mesh networking
2. Test on 2+ devices to see actual message hopping
3. Integrate into your emergency response workflows

---

## 📞 Need Help?

If you see errors:
1. Copy the error message
2. Check `ISSUES_FIXED.md` for solutions
3. Run `flutter doctor` to check setup
4. Run `flutter clean` and try again

---

**Ready to test? Just run:**
```bash
cd D:\Siren-Zero
flutter run -t lib/test_mesh.dart
```

🚀 **Let's go!**
