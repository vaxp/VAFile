import 'dart:io';
import 'package:flutter/material.dart';
import '../domain/vaxp.dart';

class DeviceDetectionService {
  static List<DeviceInfo>? _cachedDevices;

  /// Detect all mounted storage devices on the system with caching
  /// Only updates cache when devices actually change
  static Future<List<DeviceInfo>> detectDevices() async {
    final currentDevices = await _detectDevicesFromSystem();

    // Compare with cached devices
    if (_cachedDevices != null && _devicesListsAreEqual(_cachedDevices!, currentDevices)) {
      // Devices haven't changed, return cached list
      return _cachedDevices!;
    }

    // Devices have changed, update cache
    _cachedDevices = currentDevices;
    return currentDevices;
  }

  /// Check if two device lists are identical
  static bool _devicesListsAreEqual(List<DeviceInfo> list1, List<DeviceInfo> list2) {
    if (list1.length != list2.length) return false;

    for (int i = 0; i < list1.length; i++) {
      if (list1[i] != list2[i]) return false;
    }

    return true;
  }

  /// Internal method to detect devices from the system without caching
  static Future<List<DeviceInfo>> _detectDevicesFromSystem() async {
    final devices = <DeviceInfo>[];

    try {
      // Read /etc/mtab to get all mounted filesystems
      final mtabFile = File('/etc/mtab');
      if (!await mtabFile.exists()) {
        return devices;
      }

      final contents = await mtabFile.readAsString();
      final lines = contents.split('\n');

      for (final line in lines) {
        if (line.isEmpty) continue;

        final parts = line.split(' ');
        if (parts.length < 4) continue;

        final devicePath = parts[0];
        final mountPoint = parts[1];
        final fileSystem = parts[2];

        // Skip certain mount points and filesystems
        if (_shouldSkipMountPoint(mountPoint, fileSystem)) {
          continue;
        }

        try {
          final stat = await FileStat.stat(mountPoint);
          if (stat.type == FileSystemEntityType.notFound) {
            continue;
          }

          // Get device name
          final deviceName = _getDeviceName(devicePath, mountPoint);

          // Get device icon and type
          final (icon, isRemovable) = _getDeviceIcon(devicePath, mountPoint);

          // Get total and free space using df command
          final spaceInfo = await _getStorageSpace(mountPoint);

          devices.add(
            DeviceInfo(
              name: deviceName,
              mountPoint: mountPoint,
              devicePath: devicePath,
              fileSystem: fileSystem,
              totalSpace: spaceInfo['total'] ?? 0,
              freeSpace: spaceInfo['free'] ?? 0,
              isRemovable: isRemovable,
              icon: icon,
            ),
          );
        } catch (e) {
          // Skip devices that can't be accessed
          continue;
        }
      }

      // Sort devices: internal drives first, then removable media
      devices.sort((a, b) {
        if (a.isRemovable == b.isRemovable) {
          return a.name.compareTo(b.name);
        }
        return a.isRemovable ? 1 : -1;
      });

      return devices;
    } catch (e) {
      print('Error detecting devices: $e');
      return devices;
    }
  }

  /// Clear the cache (useful when you know devices have changed)
  static void clearCache() {
    _cachedDevices = null;
  }

  static bool _shouldSkipMountPoint(String mountPoint, String fileSystem) {
    // Skip system mount points
    final skipPaths = [
      '/sys',
      '/proc',
      '/dev',
      '/run',
      '/boot',
      '/efi',
      '/snap',
      '/var/snap',
      '/mnt/wsl',
    ];

    // Skip pseudo filesystems
    final skipFileSystems = [
      'tmpfs',
      'devtmpfs',
      'sysfs',
      'proc',
      'cgroup',
      'pstore',
      'debugfs',
      'securityfs',
      'efivarfs',
      'squashfs',
    ];

    for (final skip in skipPaths) {
      if (mountPoint.startsWith(skip)) {
        return true;
      }
    }

    for (final skip in skipFileSystems) {
      if (fileSystem == skip) {
        return true;
      }
    }

    return false;
  }

  static String _getDeviceName(String devicePath, String mountPoint) {
    // Extract meaningful device name
    if (devicePath.startsWith('/dev/')) {
      final deviceName = devicePath.replaceFirst('/dev/', '');

      // Check if it's a removable device
      if (deviceName.startsWith('sd')) {
        // USB or external drive
        if (deviceName.contains('sd')) {
          final letter = deviceName.replaceAll(RegExp(r'[^a-z]'), '');
          return 'USB Drive ($letter)';
        }
      } else if (deviceName.startsWith('nvme')) {
        return 'NVMe Drive';
      } else if (deviceName.startsWith('mmc')) {
        return 'SD Card';
      } else if (deviceName.startsWith('loop')) {
        return 'Virtual Drive';
      }
    }

    // Fall back to mount point name
    final pathParts = mountPoint.split('/');
    final lastPart = pathParts.last;

    if (lastPart.isEmpty || lastPart == 'mnt' || lastPart == 'media') {
      return mountPoint;
    }

    return lastPart;
  }

  static (IconData, bool) _getDeviceIcon(String devicePath, String mountPoint) {
    bool isRemovable = false;
    IconData icon = Icons.storage;

    // Determine if device is removable
    if (devicePath.startsWith('/dev/sd')) {
      isRemovable = true;
      // Check for USB
      if (mountPoint.contains('usb') || devicePath.contains('sdb') || devicePath.contains('sdc')) {
        icon = Icons.usb;
      } else {
        icon = Icons.sd_card;
      }
    } else if (devicePath.startsWith('/dev/mmc')) {
      isRemovable = true;
      icon = Icons.sd_card;
    } else if (devicePath.startsWith('/dev/nvme')) {
      isRemovable = false;
      icon = Icons.storage;
    } else if (mountPoint.contains('phone') || mountPoint.contains('android')) {
      isRemovable = true;
      icon = Icons.phone_android;
    }

    return (icon, isRemovable);
  }

  static Future<Map<String, int>> _getStorageSpace(String mountPoint) async {
    try {
      final result = await Process.run('df', ['-B1', mountPoint], runInShell: true);

      if (result.exitCode != 0) {
        return {'total': 0, 'free': 0};
      }

      final lines = result.stdout.toString().split('\n');
      if (lines.length < 2) {
        return {'total': 0, 'free': 0};
      }

      final dataLine = lines[1].split(RegExp(r'\s+'));
      if (dataLine.length < 4) {
        return {'total': 0, 'free': 0};
      }

      final totalSpace = int.tryParse(dataLine[1]) ?? 0;
      final freeSpace = int.tryParse(dataLine[3]) ?? 0;

      return {'total': totalSpace, 'free': freeSpace};
    } catch (e) {
      print('Error getting storage space for $mountPoint: $e');
      return {'total': 0, 'free': 0};
    }
  }
}
