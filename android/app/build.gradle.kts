plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

// ✅ 1. local.properties 파일을 읽기 위한 코드를 추가합니다.
// 이 코드는 프로젝트 루트의 local.properties 파일이 있는지 확인하고,
// 파일이 존재하면 그 안의 모든 속성(properties)을 읽어옵니다.
val localProperties = java.util.Properties()
val localPropertiesFile = rootProject.file("local.properties")
if (localPropertiesFile.exists()) {
    localPropertiesFile.reader().use { reader ->
        localProperties.load(reader)
    }
}

val flutterVersionCode: String by project
val flutterVersionName: String by project

android {
    namespace = "com.example.timemarket_frontend"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = "11"
    }

    defaultConfig {
        applicationId = "com.example.timemarket_frontend"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutterVersionCode.toInt()
        versionName = flutterVersionName

        // ✅ 2. manifestPlaceholders 문법을 Kotlin 형식으로 수정하고,
        // 위에서 읽어온 localProperties에서 API 키를 가져옵니다.
        manifestPlaceholders["GOOGLE_MAPS_API_KEY"] = localProperties.getProperty("google.maps.apiKey")
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}