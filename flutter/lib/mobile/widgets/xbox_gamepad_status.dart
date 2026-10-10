import 'package:flutter/foundation.dart';

/// Live Android device list shared by the native input callback and Setup tab.
final ValueNotifier<List<Map<String, dynamic>>> connectedGamepadDevices =
    ValueNotifier<List<Map<String, dynamic>>>(const []);
