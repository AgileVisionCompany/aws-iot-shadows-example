package io.agilevision.reinventory

import com.amazonaws.amplify.Amplify
import com.amazonaws.amplify.amplify_auth_cognito.AuthCognito
import io.agilevision.reinventory.native.FlutterBridgePlugin
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugins.pathprovider.PathProviderPlugin
import io.flutter.plugins.urllauncher.UrlLauncherPlugin

class MainActivity: FlutterActivity() {

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        // super.configureFlutterEngine(flutterEngine)

        // now all native plugins are registered by hands

        // Used a wrapper for AuthCognito plugin due to the bug in its implementation.
        // Amplify uses static variables and their lifecycle is longer than the Flutter Engine lifecycle.
        // Amplify configuration process is allowed only once, so when the plugin is going to
        // be recreated -> it fails, because it tries to configure Amplify again.
        // Thrown exception halts the setup of other plugins.
        // So the workaround is to create a wrapper plugin: AuthCognitoPluginWrapper, which
        // just catches the exception from AuthCognito and suppresses it.
        flutterEngine.plugins.add(AuthCognitoPluginWrapper(AuthCognito()))
        flutterEngine.plugins.add(Amplify())
        flutterEngine.plugins.add(PathProviderPlugin())
        flutterEngine.plugins.add(UrlLauncherPlugin())

        // custom plugin for bi-directional communication with Flutter
        flutterEngine.plugins.add(FlutterBridgePlugin())

        // initializing LEDs controller
        val flutterBridgePlugin = flutterEngine.plugins[FlutterBridgePlugin::class.java] as FlutterBridgePlugin
        LedsShadowController().setup(applicationContext, flutterBridgePlugin.flutterBridge)
    }

}
