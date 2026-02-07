#ifndef FLUTTER_PLUGIN_JYOTISH_PLUGIN_H_
#define FLUTTER_PLUGIN_JYOTISH_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

namespace jyotish {

class JyotishPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  JyotishPlugin();

  virtual ~JyotishPlugin();

  // Disallow copy and assign.
  JyotishPlugin(const JyotishPlugin&) = delete;
  JyotishPlugin& operator=(const JyotishPlugin&) = delete;

 private:
  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

}  // namespace jyotish

#endif  // FLUTTER_PLUGIN_JYOTISH_PLUGIN_H_