plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
   keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.kustom.fossfit"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true 
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        applicationId = "com.kustom.fossfit"
        minSdk = if (flutter.minSdkVersion < 21) 21 else flutter.minSdkVersion 
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

   signingConfigs {
       release {
           keyAlias keystoreProperties['keyAlias']
           keyPassword keystoreProperties['keyPassword']
           storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
           storePassword keystoreProperties['storePassword']
       }
   }
   buildTypes {
       profile {
           if (keystorePropertiesFile.exists()) {
               signingConfig signingConfigs.release
           }
           buildConfigField "long", "BUILD_TIME", "0L"
       }
       debug {
           if (keystorePropertiesFile.exists()) {
               signingConfig signingConfigs.release
           }
           buildConfigField "long", "BUILD_TIME", "0L"
       }
       release {
           signingConfig signingConfigs.release
           buildConfigField "long", "BUILD_TIME", "0L"
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