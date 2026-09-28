plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.kustom.fossfit"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true      // ✅ Kotlin DSL syntax
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"                           // ✅ Kotlin DSL prefers string
    }

    defaultConfig {
        applicationId = "com.kustom.fossfit"
        minSdk = if (flutter.minSdkVersion < 21) 21 else flutter.minSdkVersion  // Force >= 21 for desugaring
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("localRelease") {
            keyAlias = "localrelease"
            keyPassword = "!nt3r4ct1v"
            storeFile = file(System.getProperty("user.home") + "/fossfit.keystore")
            storePassword = "!nt3r4ct1v"
        }
    }

    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("localRelease")
            ndk {
                debugSymbolLevel = "NONE"
            }
            isMinifyEnabled = false          // ✅ Kotlin DSL
            isShrinkResources = false        // ✅ Kotlin DSL
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                file("proguard-rules.pro")
            )
        }
    }
}

dependencies {
    implementation("com.squareup.okhttp3:okhttp:4.11.0")
    add("coreLibraryDesugaring", "com.android.tools:desugar_jdk_libs:2.1.5")
}

flutter {
    source = "../.."
}