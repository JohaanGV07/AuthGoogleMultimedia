plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.johan.project"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.johan.project"
        
        // --- CAMBIO 1: SUBIR MINSDK ---
        minSdk = 23 // Antes ponía flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        
        // --- CAMBIO 2: ACTIVAR MULTIDEX ---
        multiDexEnabled = true 
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

dependencies {
    // --- CAMBIO 3: AÑADIR DEPENDENCIA DE MULTIDEX (Opcional pero recomendado) ---
    implementation("androidx.multidex:multidex:2.0.1")
}

flutter {
    source = "../.."
}