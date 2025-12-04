import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.aolappointment.v2"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true // ✅ Required for flutter_local_notifications
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.aolappointment.v2"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        
        // Support for 16KB memory page sizes (required for Android 15+)
        ndk {
            abiFilters += listOf("arm64-v8a")
        }
    }
    
    // Configure packaging for 16 KB page size support
    packaging {
        jniLibs {
            // Use uncompressed native libraries for 16 KB alignment
            // AGP 8.5.1+ handles 16 KB alignment automatically with uncompressed libs
            useLegacyPackaging = false
            // Exclude old MLKit native libraries that don't support 16KB page sizes
            // These are from older MLKit versions (< 17.3.0) that don't support Android 15+
            excludes += listOf(
                "**/libimage_processing_util_jni.so"  // Old MLKit library - not compatible with 16KB
            )
        }
        
        resources {
            // Exclude duplicate MLKit model files if any
            excludes += listOf(
                "META-INF/*.kotlin_module",
                "META-INF/AL2.0",
                "META-INF/LGPL2.1"
            )
        }
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
            storeFile = keystoreProperties["storeFile"]?.let { file(it) }
            storePassword = keystoreProperties["storePassword"] as String?
        }
    }

    buildTypes {
        release {
            // Use release signing config if keystore properties exist, otherwise use debug
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            isMinifyEnabled = true
            isShrinkResources = false // Don't shrink resources - can cause issues with MLKit
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

flutter {
    source = "../.."
    // Explicitly disable deferred components - we don't use Play Store dynamic features
    // This prevents R8 from looking for Play Core SplitCompat classes
}

dependencies {
    implementation("org.jetbrains.kotlin:kotlin-stdlib")
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4") // ✅ Required for Java 8+ features & flutter_local_notifications 19.x
    
    // MLKit barcode scanning for mobile_scanner plugin
    // Version 17.3.0+ supports 16KB memory page sizes for Android 15+
    // This bundled dependency includes native libraries (libbarhopper_v3.so) and all internal modules
    // DO NOT add other MLKit dependencies - they are pulled automatically as transitive dependencies
    implementation("com.google.mlkit:barcode-scanning:17.3.0")
}
