import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// 读取 android/key.properties（口令文件，已 gitignore，不入仓库）
// 文件缺失时走 debug 签名，保证没配密钥的机器也能构建
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystorePropertiesFile.inputStream().use { keystoreProperties.load(it) }
}

android {
    namespace = "com.creativestudio.flutter_creative_studio"
    compileSdk = flutter.compileSdkVersion
    // 不声明 ndkVersion：本项目插件均无原生 C++ 代码，声明了会强制 Gradle
    // 安装对应版本 NDK（下载大且国内网络常超时）。将来引入需要 NDK 的插件时再加回。

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.creativestudio.flutter_creative_studio"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        // key.properties 存在且字段齐全时才创建 release 签名配置
        if (keystorePropertiesFile.exists() &&
            keystoreProperties["keyAlias"] != null &&
            !keystoreProperties["storePassword"].toString().startsWith("<")
        ) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // 有 release 密钥配置则用它；否则回退 debug 签名（仅本机自用，不可分发）
            signingConfig =
                if (signingConfigs.findByName("release") != null) {
                    signingConfigs.getByName("release")
                } else {
                    signingConfigs.getByName("debug")
                }

            // ---- 体积优化三件套 ----
            // 1. R8 代码压缩/混淆/优化（未引用代码与资源被裁掉）
            isMinifyEnabled = true
            // 2. 资源压缩（配合 R8，删未被引用的资源）
            isShrinkResources = true
            // 3. Dart 侧混淆 + 符号表（崩溃堆栈可反解，注意保存 map 文件）
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
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
