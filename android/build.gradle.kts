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

subprojects {
    val injectNamespace = { proj: Project ->
        val androidExt = proj.extensions.findByName("android")
        if (androidExt is com.android.build.gradle.LibraryExtension) {
            if (androidExt.namespace == null) {
                androidExt.namespace = proj.group.toString()
            }
        }
    }

    if (project.state.executed) {
        injectNamespace(project)
    } else {
        afterEvaluate {
            injectNamespace(this)
        }
    }
}
