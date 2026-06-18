import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_lake/data/services/support_diagnostics_service.dart';

void main() {
  group('SupportDeviceDetails', () {
    test('maps approved Android fields only', () {
      final version = AndroidBuildVersion.setMockInitialValues(
        codename: 'REL',
        incremental: '123',
        previewSdkInt: 0,
        release: '16',
        sdkInt: 36,
      );
      final info = AndroidDeviceInfo.setMockInitialValues(
        version: version,
        board: 'private-board',
        bootloader: 'private-bootloader',
        brand: 'Google',
        device: 'private-device',
        display: 'private-display',
        fingerprint: 'private-fingerprint',
        hardware: 'private-hardware',
        host: 'private-host',
        id: 'private-id',
        manufacturer: 'Google',
        model: 'Pixel 10',
        product: 'private-product',
        name: 'User device name',
        supported32BitAbis: const [],
        supported64BitAbis: const ['arm64-v8a'],
        supportedAbis: const ['arm64-v8a'],
        tags: 'release-keys',
        type: 'user',
        isPhysicalDevice: true,
        freeDiskSize: 1,
        totalDiskSize: 2,
        systemFeatures: const [],
        isLowRamDevice: false,
        physicalRamSize: 8192,
        availableRamSize: 4096,
      );

      final details = SupportDeviceDetails.fromDeviceInfo(info);

      expect(details.platform, 'Android');
      expect(details.osVersion, '16');
      expect(details.manufacturer, 'Google');
      expect(details.model, 'Pixel 10');
      expect(details.toString(), isNot(contains('private-fingerprint')));
      expect(details.toString(), isNot(contains('private-id')));
    });

    test('maps iOS without exposing vendor identifier or device name', () {
      final info = IosDeviceInfo.setMockInitialValues(
        name: 'Personal iPhone',
        systemName: 'iOS',
        systemVersion: '26.5',
        model: 'iPhone',
        modelName: 'iPhone 16 Pro',
        localizedModel: 'iPhone',
        freeDiskSize: 1,
        totalDiskSize: 2,
        identifierForVendor: 'private-vendor-id',
        isPhysicalDevice: true,
        isiOSAppOnMac: false,
        isiOSAppOnVision: false,
        physicalRamSize: 8192,
        availableRamSize: 4096,
        utsname: IosUtsname.setMockInitialValues(
          sysname: 'Darwin',
          nodename: 'private-hostname',
          release: '1',
          version: '1',
          machine: 'iPhone17,1',
        ),
      );

      final details = SupportDeviceDetails.fromDeviceInfo(info);

      expect(details.platform, 'iOS');
      expect(details.osVersion, '26.5');
      expect(details.manufacturer, 'Apple');
      expect(details.model, 'iPhone 16 Pro');
      expect(details.toString(), isNot(contains('private-vendor-id')));
      expect(details.toString(), isNot(contains('Personal iPhone')));
    });

    test('maps web browser without using the user agent', () {
      final info = WebBrowserInfo(
        appCodeName: 'Mozilla',
        appName: 'Netscape',
        appVersion: '5.0',
        deviceMemory: 8,
        language: 'en',
        languages: const ['en'],
        platform: 'MacIntel',
        product: 'Gecko',
        productSub: '20030107',
        userAgent: 'Chrome private-user-agent',
        vendor: 'Google Inc.',
        vendorSub: '',
        maxTouchPoints: 0,
        hardwareConcurrency: 8,
      );

      final details = SupportDeviceDetails.fromDeviceInfo(info);

      expect(details.platform, 'Web');
      expect(details.osVersion, '5.0');
      expect(details.manufacturer, isNull);
      expect(details.model, isNull);
      expect(details.toString(), isNot(contains('private-user-agent')));
    });
  });
}
