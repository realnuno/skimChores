// Top-level build.gradle.kts (Kotlin DSL)

import org.gradle.api.tasks.Delete
import org.gradle.api.Project
import org.gradle.api.initialization.resolve.RepositoriesMode
import java.io.File

buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.google.gms:google-services:4.4.0")
    }
}

// Apply repositories for all subprojects
allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Configure shared build directory
val newBuildDir = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.set(newBuildDir)

subprojects {
    val newSubprojectBuildDir = newBuildDir.dir(name)
    layout.buildDirectory.set(newSubprojectBuildDir)
    evaluationDependsOn(":app")
}

// Define clean task
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
