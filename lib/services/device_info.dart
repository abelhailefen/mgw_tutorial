// lib/services/device_info.dart
import 'dart:async';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart'; // For BuildContext in detectDeviceType and getFormattedDeviceString
import 'package:flutter/services.dart'; // For PlatformException

class DeviceInfoService {
  static final DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();

  // Original method to get the detailed map (keep if needed elsewhere)
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
          TargetPlatform.linux =>
            _readLinuxDeviceInfo(await deviceInfoPlugin.linuxInfo),
          // Added Fuchsia for completeness
          TargetPlatform.fuchsia =>
            <String, dynamic>{'Error:': 'Fuchsia platform info not directly supported by device_info_plus'},
          // Default case for any other unexpected platforms
          _ => <String, dynamic> {
              'Error:': 'Platform not supported'
            },
        };
      }
    } on PlatformException catch (e) {
      deviceData = <String, dynamic> {'Error:': 'Failed to get platform version details: ${e.message}'};
    } catch (e) {
       deviceData = <String, dynamic> {'Error:': 'An unexpected error occurred getting device info: $e'};
    }

    return deviceData;
  }

  String detectDeviceType(BuildContext context) {
    // This method might be better placed outside if it only needs MediaQuery,
    // or ensure context is always available when called.
     // Safely check for context validity before using MediaQuery
    if (!kIsWeb && context != null && ModalRoute.of(context) != null && ModalRoute.of(context)!.isActive) {
         try {
           final double screenWidth = MediaQuery.of(context).size.width;
            if (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS) {
                if (screenWidth > 600) { // Arbitrary breakpoint for tablets
                  return 'Tablet';
                } else {
                  return 'Mobile';
                }
            }
         } catch (e) {
             // Fallback below if MediaQuery fails
             print("Error using MediaQuery in detectDeviceType: $e");
         }
    }

     // Fallback based on platform if MediaQuery not available or platform isn't mobile
      if (kIsWeb) {
       return 'Web Browser';
     } else if (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS) {
       // Default to Mobile if MediaQuery detection failed on these platforms
       return 'Mobile';
     } else if (defaultTargetPlatform == TargetPlatform.windows || defaultTargetPlatform == TargetPlatform.macOS || defaultTargetPlatform == TargetPlatform.linux) {
       return 'Computer';
     } else {
       return 'Unknown Device Type'; // For other platforms like Fuchsia or unsupported
     }
  }

  // <<< NEW METHOD TO GET FORMATTED STRING >>>
  Future<String> getFormattedDeviceString(BuildContext context) async {
      String deviceType = "Unknown";
      String brandModel = "Unknown Device";
      String osInfo = "Unknown OS";

      // First, determine the device type (relies on context if possible)
      // Ensure context is valid before passing it
      if (context != null && ModalRoute.of(context) != null && ModalRoute.of(context)!.isActive) {
           deviceType = detectDeviceType(context);
      } else {
           // Fallback type if context is not valid
           deviceType = (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS)
                          ? "Mobile"
                          : (defaultTargetPlatform == TargetPlatform.windows || defaultTargetPlatform == TargetPlatform.macOS || defaultTargetPlatform == TargetPlatform.linux)
                            ? "Computer"
                            : kIsWeb ? "Web Browser" : "Unknown";
           print("Context not active for MediaQuery in getFormattedDeviceString, using platform default for deviceType: $deviceType");
      }


      // Then, get platform-specific details and format the string
      try {
         final deviceData = await getDeviceData(); // Use the existing method

         // If deviceData contains an error from getDeviceData, report that
         if (deviceData.containsKey('Error:')) {
              String errorMsg = deviceData['Error:'] ?? 'Failed to get details';
              return '$deviceType - $errorMsg';
         }


        // --- Construct the simple brand/model/OS string based on platform ---
        if (kIsWeb) {
           brandModel = deviceData['browserName'] ?? 'Web Browser';
           osInfo = deviceData['platform'] ?? 'Unknown Platform';
           if (deviceData.containsKey('vendor') && deviceData['vendor'] != null && deviceData['vendor'].isNotEmpty) {
               brandModel += " (${deviceData['vendor']})";
           }
        } else {
           switch (defaultTargetPlatform) {
              case TargetPlatform.android:
                brandModel = "${deviceData['brand'] ?? 'UnknownBrand'} ${deviceData['model'] ?? 'UnknownModel'}";
                // FIX: Use 'version.release' for user-facing Android version
                final androidRelease = deviceData['version.release'];
                 // FIX: Set to UnknownOS if version.release is null or empty
                if (androidRelease != null && androidRelease.isNotEmpty) {
                    osInfo = "Android $androidRelease";
                } else {
                    osInfo = "UnknownOS";
                }
                break;
              case TargetPlatform.iOS:
                brandModel = "${deviceData['localizedModel'] ?? deviceData['model'] ?? 'UnknownModel'}";
                osInfo = "${deviceData['systemName'] ?? 'iOS'} ${deviceData['systemVersion'] ?? ''}".trim();
                 if (deviceData.containsKey('utsname.machine:') && deviceData['utsname.machine:'] != null && !brandModel.contains(deviceData['utsname.machine:'])) {
                     brandModel = "${deviceData['localizedModel'] ?? deviceData['model'] ?? 'UnknownModel'} (${deviceData['utsname.machine:']})";
                 }
                break;
              case TargetPlatform.windows:
                 brandModel = "${deviceData['computerName'] ?? 'Windows Computer'}";
                 // Using major.minor.build for Windows version if available, otherwise generic Windows
                 String winVersion = '';
                 if (deviceData.containsKey('majorVersion') && deviceData['majorVersion'] != null) {
                     winVersion = "${deviceData['majorVersion']}.${deviceData['minorVersion'] ?? '0'}";
                     if (deviceData.containsKey('buildNumber') && deviceData['buildNumber'] != null) {
                         winVersion += ".${deviceData['buildNumber']}";
                     }
                 }
                 osInfo = winVersion.isNotEmpty ? "Windows $winVersion" : "Windows";
                break;
              case TargetPlatform.macOS:
                 brandModel = "${deviceData['model'] ?? 'Mac'}";
                 osInfo = "macOS ${deviceData['osRelease'] ?? ''}".trim();
                break;
               case TargetPlatform.linux:
                  brandModel = deviceData['prettyName'] ?? 'Linux Computer';
                  osInfo = deviceData['version'] ?? '';
                  if (osInfo.isEmpty) osInfo = deviceData['id'] ?? 'Linux';
                  osInfo = "Linux ${osInfo}".trim();
                  break;
               case TargetPlatform.fuchsia:
              // Default case for any other platforms
              default:
                 brandModel = "Unknown Native Device"; // Or be more specific if possible
                 osInfo = "Unknown Native OS";
                 break;
           }
        }
        // --- End of simple string construction ---

         // Combine into the final simple string
         String finalDeviceInfo = '$deviceType - $brandModel, $osInfo';

         // Cap the length to be safe for typical database columns (e.g., 255 chars)
         if (finalDeviceInfo.length > 250) { // Arbitrary limit, adjust if needed
             finalDeviceInfo = finalDeviceInfo.substring(0, 250) + "...";
         }
         print("Generated Simple Device Info String: $finalDeviceInfo");
         return finalDeviceInfo;

      } on PlatformException catch (e) {
         print("PlatformException getting device info in service: $e");
         // If getting detailed info fails, use a generic string based on the detected type
         String finalDeviceInfo = '$deviceType - Failed to get details: ${e.message}';
          if (finalDeviceInfo.length > 250) {
              finalDeviceInfo = finalDeviceInfo.substring(0, 250) + "...";
          }
          print("Generated Error Device Info String: $finalDeviceInfo");
         return finalDeviceInfo;
      } catch (e) {
         print("General error getting device info in service: $e");
         // If any other error occurs, use a generic string
         String finalDeviceInfo = '$deviceType - Failed to get details: $e';
          if (finalDeviceInfo.length > 250) {
              finalDeviceInfo = finalDeviceInfo.substring(0, 250) + "...";
          }
          print("Generated General Error Device Info String: $finalDeviceInfo");
         return finalDeviceInfo;
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
      'version.sdkInt': build.version.sdkInt,
      'version.release': build.version.release, // Keep release version
      'version.codename': build.version.codename,
      'version.baseOS': build.version.baseOS,
      'version.previewSdkInt': build.version.previewSdkInt,
      'version.incremental': build.version.incremental,
      'supported32BitAbis': build.supported32BitAbis,
      'supported64BitAbis': build.supported64BitAbis,
      'supportedAbis': build.supportedAbis,
      'display': build.display,
      'bootloader': build.bootloader,
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
      'utsname.sysname:': data.utsname.sysname,
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
    // Removed potentially problematic fields like suiteMask, productType, servicePackMajor/Minor
    return <String, dynamic>{
      'numberOfCores': data.numberOfCores,
      'computerName': data.computerName,
      'systemMemoryInMegabytes': data.systemMemoryInMegabytes,
      'userName': data.userName,
      'deviceId': data.deviceId,
      'productId': data.productId,
      'majorVersion': data.majorVersion,
      'minorVersion': data.minorVersion,
      'buildNumber': data.buildNumber,
      'platformId': data.platformId,
      'csdVersion': data.csdVersion,
    };
  }

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
      'machineId': data.machineId, // May be null
    };
  }
}