package io.agilevision.reinventory.native

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodChannel

class FlutterBridgePlugin : FlutterPlugin {

    val flutterBridge = FlutterBridge()

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        val channel = MethodChannel(binding.binaryMessenger, DEFAULT_CHANNEL)
        flutterBridge.initialize(channel)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        flutterBridge.dispose()
    }

}