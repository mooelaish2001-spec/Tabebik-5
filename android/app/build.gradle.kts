plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "app.tabibak.tabibak_center"
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
        applicationId = "app.tabibak.tabibak_center"
        // Firebase Auth يتطلب minSdk 23 على الأقل
        minSdk = maxOf(flutter.minSdkVersion, 23)
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // للتجربة فقط: يُوقَّع بمفتاح debug. للنشر أنشئ مفتاح توقيع (راجع README_AR.md).
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

// Firebase: يُفعَّل تلقائياً عند وجود google-services.json في هذا المجلد (وإلا يعمل التطبيق بالوضع التجريبي)
if (file("google-services.json").exists()) {
    apply(plugin = "com.google.gms.google-services")
}
