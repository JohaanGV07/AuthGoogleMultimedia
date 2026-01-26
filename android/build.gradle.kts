// Este bloque es NECESARIO al principio del archivo
buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        // Asegúrate de que la versión de Kotlin coincida con tu proyecto
        // Si tienes problemas, prueba con una versión más reciente como "1.9.0"
        classpath("com.android.tools.build:gradle:8.0.0") // O la versión que uses
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:1.8.0") 
        
        // El plugin de Google Services es vital para Firebase
        classpath("com.google.gms:google-services:4.4.2")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}