package com.jyotish

import androidx.annotation.NonNull

import io.flutter.embedding.engine.plugins.FlutterPlugin

/** JyotishPlugin */
class JyotishPlugin: FlutterPlugin {
  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    // This is an FFI plugin - no platform channel implementation needed
    // The actual native code is accessed via Dart FFI
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
  }
}