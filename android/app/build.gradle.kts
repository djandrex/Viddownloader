import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    // (Kotlin is applied automatically by the Flutter plugin; see android.builtInKotlin.)
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing: android/key.properties is created by the GitHub Actions
// workflow (or by you, locally). Without it, release builds fall back to the
// debug key so local builds never break. Never commit key.properties or the .jks.
val keystoreProperties = Properties().apply {
    val file = rootProject.file("key.properties")
    if (file.exists()) file.inputStream().use { load(it) }
}
val hasReleaseKey = keystoreProperties.getProperty("storeFile") != null

// Package native libraries (yt-dlp/Python/FFmpeg) only for the ABIs Flutter is
// building for. `flutter build apk --target-platform android-arm,android-arm64`
// gives a phone-only APK, and `flutter run` on an x86_64 emulator still works.
val abiByFlutterPlatform = mapOf(
    "android-arm" to "armeabi-v7a",
    "android-arm64" to "arm64-v8a",
    "android-x64" to "x86_64",
)
val targetAbis: List<String> =
    (project.findProperty("target-platform") as String?)
        ?.split(',')
        ?.mapNotNull { abiByFlutterPlatform[it.trim()] }
        ?.takeIf { it.isNotEmpty() }
        ?: listOf("armeabi-v7a", "arm64-v8a")

android {
    namespace = "io.github.djandrex.viddownloader"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "io.github.djandrex.viddownloader"
        minSdk = 26
        targetSdk = flutter.targetSdkVersion
        // From pubspec.yaml, or --build-name/--build-number in the release workflow.
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        ndk {
            abiFilters.clear()
            abiFilters.addAll(targetAbis)
        }
    }

    signingConfigs {
        if (hasReleaseKey) {
            create("release") {
                storeFile = rootProject.file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName(if (hasReleaseKey) "release" else "debug")
            // R8 is enabled by the Flutter plugin; proguard-rules.pro is added automatically.
        }
    }

    packaging {
        jniLibs {
            // youtubedl-android runs Python/FFmpeg binaries from the extracted
            // native library folder, so libraries must be extracted on install.
            useLegacyPackaging = true
        }
    }

    testOptions {
        unitTests.isReturnDefaultValues = true
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

dependencies {
    // yt-dlp + Python + FFmpeg packaged for Android.
    implementation("io.github.junkfood02.youtubedl-android:library:0.18.1")
    implementation("io.github.junkfood02.youtubedl-android:ffmpeg:0.18.1")

    implementation("androidx.work:work-runtime-ktx:2.11.2")
    implementation("androidx.core:core-ktx:1.18.0")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.11.0")

    testImplementation("junit:junit:4.13.2")
}
