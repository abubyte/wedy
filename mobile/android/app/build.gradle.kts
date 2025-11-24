plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "uz.wedy"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Versions are now set per flavor (client/merchant)
        // Default values (will be overridden by flavors)
        versionCode = 1
        versionName = "1.0.0"
    }

    // Product flavors for different app types and environments
    flavorDimensions += listOf("app", "environment")
    
    productFlavors {
        // App types
        create("client") {
            dimension = "app"
            applicationId = "uz.wedy.app"
            resValue("string", "app_name", "Wedy")
            versionCode = 1
            versionName = "1.0.0"
        }
        
        create("merchant") {
            dimension = "app"
            applicationId = "uz.wedy.business"
            resValue("string", "app_name", "Wedy Biznes")
            versionCode = 1
            versionName = "1.0.0"
        }
        
        // Environments
        create("dev") {
            dimension = "environment"
            applicationIdSuffix = ".dev"
            versionNameSuffix = "-dev"
        }
        
        create("staging") {
            dimension = "environment"
            applicationIdSuffix = ".staging"
            versionNameSuffix = "-staging"
        }
        
        create("prod") {
            dimension = "environment"
        }
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
        
        debug {
            isMinifyEnabled = false
        }
    }
}

flutter {
    source = "../.."
}
