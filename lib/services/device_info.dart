// lib/services/device_info.dart
import 'dart:async';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart'; // Needed for BuildContext/MediaQuery in detectDeviceType
import 'package:flutter/services.dart'; // Needed for PlatformException

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
            _readIosDeviceInfo(await deviceInfoPlugin.iosInfo),
          TargetPlatform.windows =>
            _readWindowsDeviceInfo(await deviceInfoPlugin.windowsInfo),
          TargetPlatform.macOS =>
            _readMacOsDeviceInfo(await deviceInfoPlugin.macOsInfo),
           TargetPlatform.linux => // Added back Linux for completeness
            _readLinuxDeviceInfo(await deviceInfoPlugin.linuxInfo),
          // Fuchsia or other platforms will fall here
          _ => <String, dynamic> {
              'Error:': 'Platform not fully supported by device_info_plus'
            },
        };
      }
    } on PlatformException catch (e) { // Catch exception object for logging
      print("DeviceInfoService PlatformException in getDeviceData: $e");
      deviceData = <String, dynamic> {'Error:': 'Failed to get platform version details.'}; // Added "details"
    } catch (e) { // Catch other unexpected errors
       print("DeviceInfoService General Exception in getDeviceData: $e");
       deviceData = <String, dynamic> {'Error:': 'An unexpected error occurred getting device info.'}; // Added "info"
    }

    return deviceData;
  }

   // Made BuildContext nullable and added mounted check for safety
  String detectDeviceType(BuildContext? context) {
     // Use MediaQuery only if context is provided and valid
    if (!kIsWeb && context != null && context.mounted) {
        try {
             final double screenWidth = MediaQuery.of(context).size.width;
             if (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS) {
               if (screenWidth > 600) { // Standard breakpoint for tablets
                 return 'Tablet';
               } else {
                 return 'Mobile';
               }
             }
        } catch (e) {
             print("DeviceInfoService Error using MediaQuery in detectDeviceType: $e");
             // Fallback below if MediaQuery fails
        }
    }


     // Fallback based on platform if context is not available or platform isn't mobile/tablet
      if (kIsWeb) {
       return 'Web Browser';
     } else if (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS) {
       // Default to Mobile if MediaQuery failed on these platforms
       return 'Mobile';
     } else if (defaultTargetPlatform == TargetPlatform.windows || defaultTargetPlatform == TargetPlatform.macOS || defaultTargetPlatform == TargetPlatform.linux) {
       return 'Computer';
     } else {
       return 'Unknown Device Type'; // For other platforms like Fuchsia or unsupported
     }
  }


  Map<String, dynamic> _readAndroidBuildData(AndroidDeviceInfo build) {
    return <String, dynamic> {
      'board': build.board,
      'brand': build.brand,
      'device': build.device, // This is the hardware device name, not the user-set name
      'fingerprint': build.fingerprint,
      'hardware': build.hardware,
      'host': build.host,
      'id': build.id, // Android OS Build ID (like "SQ1A.211205.008") - this is probably what 'deviceId' in the target string meant for Android
      'manufacturer': build.manufacturer,
      'model': build.model, // Marketing model name (like "Pixel 5")
      'product': build.product,
      'isPhysicalDevice': build.isPhysicalDevice,
      'version.sdkInt': build.version.sdkInt, // Added back version info
      'version.release': build.version.release, // Added back version info
    };
  }

  Map<String, dynamic> _readIosDeviceInfo(IosDeviceInfo data) {
    return <String, dynamic> {
      'name': data.name, // User-set device name (e.g., "John's iPhone") - NOT good for consistent ID
      'systemName': data.systemName, // iOS
      'systemVersion': data.systemVersion, // 15.0
      'model': data.model, // iPhone, iPad, etc.
      // 'modelName': data.modelName, // <<< REMOVED: This getter does not exist in device_info_plus IosDeviceInfo
      'localizedModel': data.localizedModel, // iPhone 13 Pro, iPad Air (5th generation) - Use this for marketing name
      'identifierForVendor': data.identifierForVendor, // UUID - good for internal app tracking, not external display
      'isPhysicalDevice': data.isPhysicalDevice,
      'utsname.sysname:': data.utsname.sysname, // Darwin
      'utsname.nodename:': data.utsname.nodename, // hostname
      'utsname.release:': data.utsname.release, // 21.1.0
      'utsname.version:': data.utsname.version, // Darwin Kernel Version 21.1.0:Tues Oct 26 10:35:59 PDT 2021; root:xnu-8019.41.2~1/RELEASE_ARM64_T8101
      'utsname.machine:': data.utsname.machine, // iPhone13,2 - Technical hardware identifier - Good candidate for 'deviceId'
    };
  }

  Map<String, dynamic> _readWebBrowserInfo(WebBrowserInfo data) {
    return <String, dynamic> {
      'browserName': data.browserName.name, // chrome, firefox, safari
      'appCodeName': data.appCodeName,
      'appName': data.appName,
      'appVersion': data.appVersion, // Contains browser version and often OS info
      'deviceMemory': data.deviceMemory, // May be null
      'language': data.language,
      'platform': data.platform, // Win32, MacIntel, Linux x86_64
      'userAgent': data.userAgent, // Detailed string
      'vendor': data.vendor, // Google Inc.
      // No direct equivalent for board/id/deviceId
    };
  }

  Map<String, dynamic> _readMacOsDeviceInfo(MacOsDeviceInfo data) {
    return <String, dynamic> {
      'computerName': data.computerName, // User-set name
      'hostName': data.hostName,
      'arch': data.arch,
      'model': data.model, // Macmini9,1 (Technical identifier)
      'kernelVersion': data.kernelVersion,
      'osRelease': data.osRelease, // 21.5.0 (macOS version)
      'systemGUID': data.systemGUID, // UUID - could potentially map to 'deviceId' if needed
       // No direct equivalent for brand/board/id (Android build ID)
    };
  }

   Map<String, dynamic> _readLinuxDeviceInfo(LinuxDeviceInfo data) {
    return <String, dynamic>{
      'name': data.name, // User-set hostname?
      'version': data.version, // Specific version string
      'id': data.id, // Distribution ID (e.g. "ubuntu")
      'idLike': data.idLike, // Parent distribution IDs
      'versionCodename': data.versionCodename,
      'versionId': data.versionId, // Version number (e.g. "22.04")
      'prettyName': data.prettyName, // e.g. "Ubuntu 22.04.1 LTS"
      'buildId': data.buildId,
      'variant': data.variant,
      'variantId': data.variantId,
      'machineId': data.machineId, // UUID - could potentially map to 'deviceId' if needed
       // No direct equivalent for brand/board
    };
  }


  Map<String, dynamic> _readWindowsDeviceInfo(WindowsDeviceInfo data) {
    return <String, dynamic> {
      'numberOfCores': data.numberOfCores,
      'computerName': data.computerName, // User-set name
      'systemMemoryInMegabytes': data.systemMemoryInMegabytes,
      'userName': data.userName, // User name
       'deviceId': data.deviceId, // UUID - could map to 'deviceId'
       'productId': data.productId, // Windows Product ID
       'majorVersion': data.majorVersion, // 10
       'minorVersion': data.minorVersion, // 0
       'buildNumber': data.buildNumber, // 19045
       'platformId': data.platformId, // 2
       'csdVersion': data.csdVersion, // "" or service pack info
       // No direct equivalent for brand/board/id (Android build ID)
    };
  }

  // Removed the incorrect _getDeviceInfo and deviceName state variables
}