#include "include/jyotish/jyotish_plugin.h"

#include <flutter_linux/flutter_linux.h>
#include <gtk/gtk.h>
#include <sys/utsname.h>

#include <cstring>

#define JYOTISH_PLUGIN(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), jyotish_plugin_get_type(), \
                              JyotishPlugin))

struct _JyotishPlugin {
  GObject parent_instance;
};

G_DEFINE_TYPE(JyotishPlugin, jyotish_plugin, g_object_get_type())

// Called when a method call is received from Flutter.
static void jyotish_plugin_handle_method_call(
    JyotishPlugin* self,
    FlMethodCall* method_call) {
  // This is an FFI plugin - no method channel implementation needed
  fl_method_call_respond_not_implemented(method_call, nullptr);
}

static void jyotish_plugin_dispose(GObject* object) {
  G_OBJECT_CLASS(jyotish_plugin_parent_class)->dispose(object);
}

static void jyotish_plugin_class_init(JyotishPluginClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = jyotish_plugin_dispose;
}

static void jyotish_plugin_init(JyotishPlugin* self) {}

static void method_call_cb(FlMethodChannel* channel, FlMethodCall* method_call,
                           gpointer user_data) {
  JyotishPlugin* plugin = JYOTISH_PLUGIN(user_data);
  jyotish_plugin_handle_method_call(plugin, method_call);
}

void jyotish_plugin_register_with_registrar(FlPluginRegistrar* registrar) {
  JyotishPlugin* plugin = JYOTISH_PLUGIN(
      g_object_new(jyotish_plugin_get_type(), nullptr));

  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  g_autoptr(FlMethodChannel) channel =
      fl_method_channel_new(fl_plugin_registrar_get_messenger(registrar),
                            "jyotish",
                            FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(channel, method_call_cb,
                                            g_object_ref(plugin),
                                            g_object_unref);

  g_object_unref(plugin);
}