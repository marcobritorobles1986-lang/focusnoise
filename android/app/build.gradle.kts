plugins {
    id("com.android.application")
    id("kotlin-android")
    // El plugin de Flutter debe ir después de Android/Kotlin
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.focusnoise"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    defaultConfig {
        applicationId = "com.example.focusnoise"
        minSdk = maxOf(21, flutter.minSdkVersion)
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        vectorDrawables { useSupportLibrary = true }
    }

    buildTypes {
        // ✅ DEBUG: no shrink, no minify (evita el error)
        debug {
            isMinifyEnabled = false
            isShrinkResources = false
        }

        // ✅ RELEASE (elige una de las dos opciones):
        // Opción A: sin shrink ni minify (simple)
        release {
            isMinifyEnabled = false
            isShrinkResources = false
            signingConfig = signingConfigs.getByName("debug") // (cámbialo por tu firma real después)
            isMinifyEnabled = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }

        // --- Opción B (si quieres optimizar en release):
        // release {
        //     isMinifyEnabled = true        // activa R8 (code shrink)
        //     isShrinkResources = true      // ahora sí puedes reducir recursos
        //     signingConfig = signingConfigs.getByName("debug")
        //     proguardFiles(
        //         getDefaultProguardFile("proguard-android-optimize.txt"),
        //         "proguard-rules.pro"
        //     )
        // }
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
    // ✅ Usa una versión existente en repos
    implementation("androidx.core:core-splashscreen:1.0.1")
    implementation("com.google.android.material:material:1.12.0") // <-- agrega esto
    // Resto de dependencias de plugins Flutter se inyectan automáticamente
}
