plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.tabebik.tabebik_user"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    defaultConfig {
        applicationId = "com.tabebik.tabebik_user"
        // Firebase Auth requires minSdk 23 or higher.
        minSdk = maxOf(flutter.minSdkVersion, 23)
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (System.getenv("CI") == "true") {
                storeFile = file(
                    requireNotNull(System.getenv("CM_KEYSTORE_PATH")) {
                        "CM_KEYSTORE_PATH is missing. Check Codemagic android_signing configuration."
                    }
                )
                storePassword = requireNotNull(System.getenv("CM_KEYSTORE_PASSWORD")) {
                    "CM_KEYSTORE_PASSWORD is missing from Codemagic."
                }
                keyAlias = requireNotNull(System.getenv("CM_KEY_ALIAS")) {
                    "CM_KEY_ALIAS is missing from Codemagic."
                }
                keyPassword = requireNotNull(System.getenv("CM_KEY_PASSWORD")) {
                    "CM_KEY_PASSWORD is missing from Codemagic."
                }
            }
        }
    }

    buildTypes {
        release {
            // Use the uploaded Codemagic keystore in CI; keep debug signing for local testing.
            signingConfig = if (System.getenv("CI") == "true") {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_11
    }
}

flutter {
    source = "../.."
}

// Enable Google Services when the Firebase config file exists.
if (file("google-services.json").exists()) {
    apply(plugin = "com.google.gms.google-services")
}
