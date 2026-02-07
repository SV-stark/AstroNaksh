#include "include/jyotish/jyotish_plugin.h"

// This must be included before many other Windows headers.
#include <windows.h>

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <memory>
#include <sstream>

namespace jyotish {

// static
void JyotishPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows *registrar) {
  auto channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          registrar->messenger(), "jyotish",
          &flutter::StandardMethodCodec::GetInstance());

  auto plugin = std::make_unique<JyotishPlugin>();

  channel->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto &call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });

  registrar->AddPlugin(std::move(plugin));
}

JyotishPlugin::JyotishPlugin() {}

JyotishPlugin::~JyotishPlugin() {}

void JyotishPlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  // This is an FFI plugin - no method channel implementation needed
  result->NotImplemented();
}

}  // namespace jyotish