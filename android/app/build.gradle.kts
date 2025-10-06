plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android") // ✅ Kotlin DSL plugin ID
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.integrated_health_app"
    compileSdk = 36// ✅ 36 isn’t officially released yet; safest to use 34 for now
    ndkVersion = "27.0.12077973"

    defaultConfig {
        applicationId = "com.example.integrated_health_app"
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = 1
        versionName = "1.0"
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = "11"
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = true
            isShrinkResources = true   // ✅ correct in Kotlin DSL
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // ✅ No need to redeclare stdlib — the Kotlin Android plugin adds it automatically
    // If you still want explicit stdlib version:
    implementation("org.jetbrains.kotlin:kotlin-stdlib:1.9.22")
}
