// lib/services/device_info.dart
import 'dart:async';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart'; // For BuildContext in detectDeviceType
import 'package:flutter/services.dart';

class DeviceInfoService {
  static final DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();

  Future<Map<String, dynamic>> getDeviceData() async {
    Map<String, dynamic> deviceData = {};

    try {
      if (kIsWeb) {
        deviceData = _readWebBrowserInfo(await deviceInfoPlugin.webBrowserInfo);
      } else {
        deviceData = switch (defaultTargetPlatform) {
          TargetPlatform.android =>
            _readAndroidBuildData(await deviceInfoPlugin.androidInfo),
          TargetPlatform.iOS =>
            _readIosDeviceInfo(await deviceInfoPlugin.iosInfo), // Corrected here
          TargetPlatform.windows =>
            _readWindowsDeviceInfo(await deviceInfoPlugin.windowsInfo),
          TargetPlatform.macOS =>
            _readMacOsDeviceInfo(await deviceInfoPlugin.macOsInfo),
          // Added Linux for completeness, though you might not target it
          TargetPlatform.linux =>
            _readLinuxDeviceInfo(await deviceInfoPlugin.linuxInfo),
          _ => <String, dynamic>{'Error:': 'Platform not supported'},
        };
      }
    } on PlatformException {
      deviceData = <String, dynamic>{'Error:': 'Failed to get platform version.'};
    }

    return deviceData;
  }

  String detectDeviceType(BuildContext context) {
    // This method might be better placed outside if it only needs MediaQuery,
    // or ensure context is always available when called.
    if (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS) {
      final double screenWidth = MediaQuery.of(context).size.width;
      if (screenWidth > 600) { // Arbitrary breakpoint for tablets
        return 'Tablet';
      } else {
        return 'Mobile';
      }
    } else if (kIsWeb) {
      return 'Web Browser';
    }
     else {
      return 'Computer'; // For Windows, macOS, Linux desktop
    }
  }

  Map<String, dynamic> _readAndroidBuildData(AndroidDeviceInfo build) {
    return <String, dynamic>{
      'board': build.board,
      'brand': build.brand,
      'device': build.device,
      'fingerprint': build.fingerprint,
      'hardware': build.hardware,
      'host': build.host,
      'id': build.id,
      'manufacturer': build.manufacturer,
      'model': build.model,
      'product': build.product,
      'isPhysicalDevice': build.isPhysicalDevice,
      'version.sdkInt': build.version.sdkInt, // Example of accessing nested version info
    };
  }

  Map<String, dynamic> _readIosDeviceInfo(IosDeviceInfo data) {
    return <String, dynamic>{
      'name': data.name,
      'systemName': data.systemName,
      'systemVersion': data.systemVersion,
      'model': data.model, // e.g., "iPhone", "iPad"
      'localizedModel': data.localizedModel, // e.g., "iPhone 13 Pro"
      'identifierForVendor': data.identifierForVendor,
      'isPhysicalDevice': data.isPhysicalDevice,
      'utsname.sysname:': data.utsname.sysname, // More detailed system info
      'utsname.nodename:': data.utsname.nodename,
      'utsname.release:': data.utsname.release,
      'utsname.version:': data.utsname.version,
      'utsname.machine:': data.utsname.machine, // e.g., "iPhone13,2"
    };
  }

  Map<String, dynamic> _readWebBrowserInfo(WebBrowserInfo data) {
    return <String, dynamic>{
      'browserName': data.browserName.name, // Using .name for enum
      'appCodeName': data.appCodeName,
      'appName': data.appName,
      'appVersion': data.appVersion,
      'deviceMemory': data.deviceMemory, // May be null
      'language': data.language,
      'languages': data.languages, // List of languages
      'platform': data.platform,
      'userAgent': data.userAgent, // Useful for more detailed browser info
      'vendor': data.vendor,
      'hardwareConcurrency': data.hardwareConcurrency, // May be null
    };
  }

  Map<String, dynamic> _readMacOsDeviceInfo(MacOsDeviceInfo data) {
    return <String, dynamic>{
      'computerName': data.computerName,
      'hostName': data.hostName,
      'arch': data.arch,
      'model': data.model,
      'kernelVersion': data.kernelVersion,
      'osRelease': data.osRelease,
      'systemGUID': data.systemGUID, // May be null
    };
  }

  Map<String, dynamic> _readWindowsDeviceInfo(WindowsDeviceInfo data) {
    return <String, dynamic>{
      'numberOfCores': data.numberOfCores,
      'computerName': data.computerName,
      'systemMemoryInMegabytes': data.systemMemoryInMegabytes,
      'userName': data.userName, // Added this from your previous code
      'deviceId': data.deviceId,
      'productId': data.productId,
    };
  }

  // Added for Linux
  Map<String, dynamic> _readLinuxDeviceInfo(LinuxDeviceInfo data) {
    return <String, dynamic>{
      'name': data.name,
      'version': data.version,
      'id': data.id,
      'idLike': data.idLike,
      'versionCodename': data.versionCodename,
      'versionId': data.versionId,
      'prettyName': data.prettyName,
      'buildId': data.buildId,
      'variant': data.variant,
      'variantId': data.variantId,
      'machineId': data.machineId,
    };
  }
}