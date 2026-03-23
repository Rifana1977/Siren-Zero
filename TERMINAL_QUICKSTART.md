# 🚀 QUICK START - Copy & Paste Commands

## ✅ Fastest Test (30 seconds)

```bash
cd D:\Siren-Zero
flutter run -t lib/test_mesh.dart
```

That's it! Your mesh test app will open on your phone.

---

## 📱 You Have a Samsung Device Connected!

I can see: **SM A127F (Android 13)** is ready!

---

## 🎯 Three Simple Options

### Option 1: Use the Script (Easiest) ⭐

**Windows:**
```cmd
cd D:\Siren-Zero
test_mesh.bat
```

**Linux/Mac:**
```bash
cd D:\Siren-Zero
chmod +x test_mesh.sh
./test_mesh.sh
```

Then press `1` and hit Enter. Done!

---

### Option 2: Direct Command (Fastest)

```bash
cd D:\Siren-Zero
flutter run -t lib/test_mesh.dart
```

**Wait 30-60 seconds while it builds, then:**
- App opens on your Samsung phone
- Click "Simulate Incoming SOS" button
- See it work!

---

### Option 3: Your Full App with Mesh

```bash
cd D:\Siren-Zero
flutter run -t lib/main_with_mesh.dart
```

Your complete Siren-Zero app opens with mesh networking enabled.

---

## 🎮 While App is Running

Press these keys in terminal:

- `r` = Reload changes (hot reload)
- `R` = Restart app
- `q` = Quit
- `h` = Help

---

## 🧪 Testing on Your Samsung Phone

### Step 1: Run the App
```bash
flutter run -t lib/test_mesh.dart
```

### Step 2: On Your Phone

You'll see a screen like this:

```
┌────────────────────────────┐
│ Mesh Network Test          │
│                  🔴 0 peers│
├────────────────────────────┤
│ Test Actions               │
│                            │
│ [Send Test SOS]            │ ← Click this (won't work without Ditto)
│ [Simulate Incoming SOS]    │ ← Click this! (works immediately)
│ [Open SOS Broadcast View]  │
│ [Open SOS Monitor View]    │
└────────────────────────────┘
```

### Step 3: Test It!

1. Click **"Simulate Incoming SOS"**
   - You'll see a red notification
   - Message appears in list below

2. Click **"Open SOS Monitor View"**
   - See the simulated SOS message
   - View details

3. Click back, then **"Open SOS Broadcast View"**
   - See the full emergency form
   - Try filling it out

That's it! You've tested the mesh network UI!

---

## 📊 What You'll See in Terminal

```
$ flutter run -t lib/test_mesh.dart

Launching lib\test_mesh.dart on SM A127F...
Running Gradle task 'assembleDebug'...
✓ Built build\app\outputs\flutter-apk\app-debug.apk

🚀 Initializing Mesh Network Test...
📱 Device ID: android_abc123
📱 Device Name: Samsung SM-A127F
⚠️ Mesh network initialization failed: [No Ditto credentials]
📝 Note: This is OK for testing UI

Installing build\app\outputs\flutter-apk\app-debug.apk...
Synced 52.5MB

Flutter run key commands.
r Hot reload.
R Hot restart.
q Quit.
```

---

## ⚡ Troubleshooting

### "No devices found"
```bash
# Make sure phone is connected via USB
# Enable USB Debugging on phone
flutter devices
```

### Build fails
```bash
# Clean and try again
flutter clean
flutter pub get
flutter run -t lib/test_mesh.dart
```

### App crashes
```bash
# Run with verbose output to see errors
flutter run -t lib/test_mesh.dart -v
```

---

## 🎉 SUCCESS! What Next?

Once basic test works:

### Test with Real Mesh (2 Devices)

1. Get Ditto credentials: https://portal.ditto.live/
2. Update `lib/services/mesh_network_service.dart` line 250
3. Install on 2 phones
4. Send SOS from one, receive on other!

---

## 📝 Commands Cheat Sheet

```bash
# Test mesh network
flutter run -t lib/test_mesh.dart

# Your full app with mesh
flutter run -t lib/main_with_mesh.dart

# Check devices
flutter devices

# Build APK
flutter build apk --debug -t lib/test_mesh.dart

# Clean build
flutter clean && flutter pub get

# Check for errors
flutter analyze
```

---

## 🚀 READY TO GO!

Just open your terminal and run:

```bash
cd D:\Siren-Zero
flutter run -t lib/test_mesh.dart
```

**Or use the script:**

```cmd
cd D:\Siren-Zero
test_mesh.bat
```

Press `1` → Enter → Wait 30 seconds → Test on your Samsung phone!

---

**Need detailed help?** Check `HOW_TO_TEST.md`
