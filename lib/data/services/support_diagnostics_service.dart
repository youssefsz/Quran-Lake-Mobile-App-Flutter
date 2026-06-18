import 'dart:ui';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../models/support_feedback.dart';

abstract interface class SupportDiagnosticsProvider {
  Future<SupportDiagnostics> collect(Locale locale);
}

typedef PackageInfoLoader = Future<PackageInfo> Function();

class DeviceSupportDiagnosticsProvider implements SupportDiagnosticsProvider {
  final DeviceInfoPlugin _deviceInfoPlugin;
  final PackageInfoLoader _packageInfoLoader;

  DeviceSupportDiagnosticsProvider({
    DeviceInfoPlugin? deviceInfoPlugin,
    PackageInfoLoader? packageInfoLoader,
  }) : _deviceInfoPlugin = deviceInfoPlugin ?? DeviceInfoPlugin(),
       _packageInfoLoader = packageInfoLoader ?? PackageInfo.fromPlatform;

  @override
  Future<SupportDiagnostics> collect(Locale locale) async {
    final results = await Future.wait<Object>([
      _packageInfoLoader(),
      _deviceInfoPlugin.deviceInfo,
    ]);
    final packageInfo = results[0] as PackageInfo;
    final deviceInfo = results[1] as BaseDeviceInfo;
    final deviceDetails = SupportDeviceDetails.fromDeviceInfo(deviceInfo);

    return SupportDiagnostics(
      appName: 'Quran Lake',
      appVersion: packageInfo.version,
      buildNumber: packageInfo.buildNumber,
      platform: deviceDetails.platform,
      osVersion: deviceDetails.osVersion,
      deviceManufacturer: deviceDetails.manufacturer,
      deviceModel: deviceDetails.model,
      locale: locale,
    );
  }
}

class SupportDeviceDetails {
  final String platform;
  final String? osVersion;
  final String? manufacturer;
  final String? model;

  const SupportDeviceDetails({
    required this.platform,
    this.osVersion,
    this.manufacturer,
    this.model,
  });

  factory SupportDeviceDetails.fromDeviceInfo(BaseDeviceInfo info) {
    return switch (info) {
      AndroidDeviceInfo android => SupportDeviceDetails(
        platform: 'Android',
        osVersion: _nonEmpty(android.version.release),
        manufacturer: _nonEmpty(android.manufacturer),
        model: _nonEmpty(android.model),
      ),
      IosDeviceInfo ios => SupportDeviceDetails(
        platform: ios.systemName,
        osVersion: _nonEmpty(ios.systemVersion),
        manufacturer: 'Apple',
        model: _nonEmpty(ios.modelName) ?? _nonEmpty(ios.model),
      ),
      MacOsDeviceInfo macos => SupportDeviceDetails(
        platform: 'macOS',
        osVersion:
            '${macos.majorVersion}.${macos.minorVersion}.${macos.patchVersion}',
        manufacturer: 'Apple',
        model: _nonEmpty(macos.modelName) ?? _nonEmpty(macos.model),
      ),
      WindowsDeviceInfo windows => SupportDeviceDetails(
        platform: 'Windows',
        osVersion: [
          _nonEmpty(windows.productName),
          _nonEmpty(windows.displayVersion),
        ].whereType<String>().join(' '),
        manufacturer: null,
        model: null,
      ),
      LinuxDeviceInfo linux => SupportDeviceDetails(
        platform: 'Linux',
        osVersion:
            _nonEmpty(linux.version) ??
            _nonEmpty(linux.versionId) ??
            _nonEmpty(linux.prettyName),
        manufacturer: null,
        model: null,
      ),
      WebBrowserInfo web => SupportDeviceDetails(
        platform: 'Web',
        osVersion: _nonEmpty(web.appVersion),
        manufacturer: null,
        model: null,
      ),
      _ => const SupportDeviceDetails(platform: 'Unknown'),
    };
  }

  static String? _nonEmpty(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}
