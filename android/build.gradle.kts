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

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
