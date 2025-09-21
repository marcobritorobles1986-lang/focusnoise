// android/app/build.gradle.kts

import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // El plugin de Flutter debe ir después de Android/Kotlin
    id("dev.flutter.flutter-gradle-plugin")
}

// === Firma con keystore (lee android/key.properties) ===
// CORRECTO (el archivo está en android/key.properties)
val keystorePropertiesFile = rootProject.file("key.properties")

val keystoreProperties = Properties().apply {
    if (keystorePropertiesFile.exists()) {
        load(FileInputStream(keystorePropertiesFile))
    }
}

// ❗ Ajusta tu package único
val appId = "com.example.focusnoise" // <-- cámbialo a com.tuempresa.focusnoise

android {
    namespace = appId

    // Usa 36 si lo tienes instalado; si no, cambia a 35.
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    defaultConfig {
        applicationId = appId
        minSdk = maxOf(21, flutter.minSdkVersion)
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        vectorDrawables { useSupportLibrary = true }
    }

    // Configuración de firma
    signingConfigs {
        // Config "release" que leerá tu key.properties
        create("release") {
            if (keystorePropertiesFile.exists()) {
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String?
                keyAlias = keystoreProperties["keyAlias"] as String?
                keyPassword = keystoreProperties["keyPassword"] as String?
            } else {
                println("WARN: android/key.properties no encontrado; release quedará sin firma.")
            }
        }
    }

    buildTypes {
        // DEBUG: sin shrink/minify
        getByName("debug") {
            isMinifyEnabled = false
            isShrinkResources = false
        }

        // ⚠️ IMPORTANTE: no crear otro "release"; modifica el existente
        getByName("release") {
            // Usa la firma de release definida arriba
            signingConfig = signingConfigs.getByName("release")

            // Mantén simple por ahora (sin ofuscación)
            isMinifyEnabled = false
            isShrinkResources = false

            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }
    kotlinOptions { jvmTarget = JavaVersion.VERSION_11.toString() }

    packaging {
        resources {
            excludes += "/META-INF/{AL2.0,LGPL2.1}"
        }
    }
}

dependencies {
    implementation("androidx.core:core-splashscreen:1.0.1")
    implementation("com.google.android.material:material:1.12.0")
    // Plugins de Flutter se inyectan solos
}
