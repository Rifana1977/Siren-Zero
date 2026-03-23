plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "ai.runanywhere.runanywhere_starter"
    
    // 📍 FIX: Explicitly set to 33 or higher for Android 13 permissions
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "ai.runanywhere.runanywhere_starter"
        
        // 📍 FIX: Ensure minSdk is high enough for the Mesh SDK
        minSdk = 24 
        
        // 📍 FIX: Target 33 or 34 so Android 13/14 permissions are active
        targetSdk = 36
        
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}