plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.ultsukulu"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true // ✅ Enable desugaring
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.ultsukulu"
        // ✅ Keep using flutter's minSdk or set a specific value
        minSdk = flutter.minSdkVersion ?: 21  // Use flutter's minSdk or fallback to 21
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        
        // ✅ Enable multidex if needed for larger apps
        multiDexEnabled = true
    }

    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("debug")
            // ✅ Optimize for release builds
            isMinifyEnabled = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }

    // ✅ Add packaging options to avoid conflicts
    packaging {
        resources {
            pickFirsts += setOf("**/libc++_shared.so", "**/libjsc.so")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // ✅ Core library desugaring for Java 8+ APIs on older Android versions
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
    
    // ✅ Support for local notifications and scheduling
    implementation("androidx.work:work-runtime:2.8.1")
    implementation("androidx.work:work-runtime-ktx:2.8.1")
    
    // ✅ Support for exact alarms (Android 12+)
    implementation("androidx.core:core:1.10.1")
    
    // ✅ Multidex support if app becomes large
    implementation("androidx.multidex:multidex:2.0.1")
}
