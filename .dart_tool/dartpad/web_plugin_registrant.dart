// Flutter web plugin registrant file.
//
// Generated file. Do not edit.
//

// @dart = 2.13
// ignore_for_file: type=lint

import 'package:flutter_sound_web/flutter_sound_web.dart';
import 'package:fluttertoast/fluttertoast_web.dart';
import 'package:record_web/record_web.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';

void registerPlugins([final Registrar? pluginRegistrar]) {
  final Registrar registrar = pluginRegistrar ?? webPluginRegistrar;
  FlutterSoundPlugin.registerWith(registrar);
  FluttertoastWebPlugin.registerWith(registrar);
  RecordPluginWeb.registerWith(registrar);
  registrar.registerMessageHandler();
}
