import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Load keystore properties from key.properties file if it exists
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
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
        // Note: applicationId is set per flavor, not in defaultConfig
        versionCode = 1
        versionName = "1.0.0"
    }

    // Disable lint for release builds to avoid cache issues
    lint {
        checkReleaseBuilds = false
        abortOnError = false
    }

    // Signing configurations
    signingConfigs {
        if (keystorePropertiesFile.exists()) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                // storeFile path from key.properties is relative to app directory
                val storeFilePath = keystoreProperties["storeFile"] as String
                storeFile = file(storeFilePath)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
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
            // CRITICAL: This must be uz.wedy.business for merchant app
            applicationId = "uz.wedy.business"
            resValue("string", "app_name", "Wedy Biznes")
            versionCode = 3
            versionName = "1.0.2"
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
            // Use release signing config if keystore exists, otherwise fall back to debug
            if (keystorePropertiesFile.exists()) {
                signingConfig = signingConfigs.getByName("release")
            } else {
                // Fallback to debug signing for development/testing
                signingConfig = signingConfigs.getByName("debug")
            }
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

// Task to print applicationId for each variant (for debugging)
tasks.register("printApplicationIds") {
    doLast {
        android.applicationVariants.all {
            println("Variant: ${name} -> applicationId: ${applicationId}")
        }
    }
}

// Disable lint tasks to avoid cache issues
tasks.matching { it.name.contains("lint") }.configureEach {
    enabled = false
}
