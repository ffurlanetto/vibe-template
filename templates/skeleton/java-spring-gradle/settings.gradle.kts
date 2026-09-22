rootProject.name = "@@PROJECT_KEBAB@@"

pluginManagement {
    repositories {
        // Central first: it serves the same plugin artifacts and is reachable
        // from restricted networks where the plugin portal's redirects are not.
        mavenCentral()
        gradlePluginPortal()
    }
}
