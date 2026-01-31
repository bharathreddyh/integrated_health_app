plugins {
    id("com.android.application") apply false
    id("org.jetbrains.kotlin.android") apply false
    // ⚠️ Do NOT include Flutter plugin here
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Force compileSdk for all subprojects (fixes android_intent_plus missing compileSdk)
subprojects {
    afterEvaluate {
        if (project.hasProperty("android")) {
            val android = project.extensions.getByName("android")
            if (android is com.android.build.gradle.BaseExtension) {
                if (android.compileSdkVersion == null) {
                    android.compileSdkVersion(36)
                }
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
