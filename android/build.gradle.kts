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

// Force compileSdk on subprojects that reference flutter.compileSdkVersion
// (fixes android_intent_plus build.gradle referencing undefined 'flutter' property)
subprojects {
    project.plugins.whenPluginAdded {
        if (this is com.android.build.gradle.api.AndroidBasePlugin) {
            project.extensions.configure<com.android.build.gradle.BaseExtension> {
                compileSdkVersion(36)
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
