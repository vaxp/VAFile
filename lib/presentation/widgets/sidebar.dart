import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../application/file_manager/file_manager_bloc.dart' as fm;
class Sidebar extends StatelessWidget {
  const Sidebar({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              _buildSidebarItem(
                icon: Icons.access_time,
                title: 'Recent',
                onTap: () {
                  // Navigate to recents
                },
              ),
              _buildSidebarItem(
                icon: Icons.star,
                title: 'Starred',
                onTap: () {
                  // Navigate to starred
                },
              ),
              _buildSidebarItem(
                icon: Icons.home,
                title: 'Home',
                onTap: () {
                  context.read<fm.FileManagerBloc>().add(
                    fm.LoadDirectory(_getUserHomePath()),
                  );
                },
              ),
                _buildSidebarItem(
                icon: Icons.desktop_mac,
                title: 'Desktop',
                onTap: () => context.read<fm.FileManagerBloc>().add(
                  fm.LoadDirectory('${Platform.environment['HOME']}/Desktop'),
                ),
              ),
              _buildSidebarItem(
                icon: Icons.description,
                title: 'Documents',
                onTap: () => context.read<fm.FileManagerBloc>().add(
                  fm.LoadDirectory('${Platform.environment['HOME']}/Documents'),
                ),
              ),
              _buildSidebarItem(
                icon: Icons.download,
                title: 'Downloads',
                onTap: () => context.read<fm.FileManagerBloc>().add(
                  fm.LoadDirectory('${Platform.environment['HOME']}/Downloads'),
                ),
              ),
              _buildSidebarItem(
                icon: Icons.music_note,
                title: 'Music',
                onTap: () => context.read<fm.FileManagerBloc>().add(
                  fm.LoadDirectory('${Platform.environment['HOME']}/Music'),
                ),
              ),
              _buildSidebarItem(
                icon: Icons.image,
                title: 'Pictures',
                onTap: () => context.read<fm.FileManagerBloc>().add(
                  fm.LoadDirectory('${Platform.environment['HOME']}/Pictures'),
                ),
              ),
              _buildSidebarItem(
                icon: Icons.videocam,
                title: 'Videos',
                onTap: () => context.read<fm.FileManagerBloc>().add(
                  fm.LoadDirectory('${Platform.environment['HOME']}/Videos'),
                ),
              ),
              _buildSidebarItem(
                icon: Icons.delete,
                title: 'Trash',
                onTap: () => context.read<fm.FileManagerBloc>().add(
                  fm.LoadDirectory('${Platform.environment['HOME']}/.local/share/Trash/files'),
                ),
              ),
              const SizedBox(height: 8),
              // Connected Devices Section
              BlocSelector<fm.FileManagerBloc, fm.FileManagerState, dynamic>(
                selector: (state) {
                  if (state is fm.FileManagerLoaded) {
                    return state.connectedDevices;
                  }
                  return [];
                },
                builder: (context, connectedDevices) {
                  if ((connectedDevices as List).isNotEmpty) {
                    return Column(
                      children: [
                        ...connectedDevices.map((device) {
                          return _buildSidebarItem(
                            icon: device.icon as IconData,
                            title: device.name as String,
                            subtitle: '${_formatBytes(device.freeSpace as int)} free',
                            deviceMountPoint: device.mountPoint as String,
                            onTap: () {
                              context.read<fm.FileManagerBloc>().add(
                                fm.LoadDirectory(device.mountPoint as String),
                              );
                            },
                          );
                        }),
                        const SizedBox(height: 8),
                      ],
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              _buildSidebarItemWithChevron(
                icon: Icons.add,
                title: 'Other Locations',
                onTap: () {
                  // Navigate to other locations
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSidebarItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
    String? subtitle,
    String? deviceMountPoint,
  }) {
    return BlocSelector<fm.FileManagerBloc, fm.FileManagerState, bool>(
      selector: (state) {
        if (state is fm.FileManagerLoaded) {
          String homePath = _getUserHomePath();
          String currentPath = state.currentPath;
          
          // إذا كان جهاز متصل، قارن مع mount point
          if (deviceMountPoint != null) {
            return currentPath == deviceMountPoint;
          }
          
          // تحديد المؤشر بناءً على المسار الحالي
          if (title == 'Home') {
            return currentPath == homePath;
          } else if (title == 'Desktop') {
            return currentPath == '$homePath/Desktop';
          } else if (title == 'Documents') {
            return currentPath == '$homePath/Documents';
          } else if (title == 'Downloads') {
            return currentPath == '$homePath/Downloads';
          } else if (title == 'Music') {
            return currentPath == '$homePath/Music';
          } else if (title == 'Pictures') {
            return currentPath == '$homePath/Pictures';
          } else if (title == 'Videos') {
            return currentPath == '$homePath/Videos';
          } else if (title == 'Trash') {
            return currentPath == '$homePath/.local/share/Trash/files';
          }
        }
        return false;
      },
      builder: (context, isSelected) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(6),
              splashColor: Colors.transparent,
              hoverColor: Colors.transparent,
              highlightColor: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  // ignore: deprecated_member_use
                  color: isSelected ? const Color(0xFF007AFF).withOpacity(0.2) : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Icon(
                      icon,
                      size: 16,
                      color: iconColor ?? (isSelected ? const Color(0xFF007AFF) : Colors.white70),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 13,
                              color: isSelected ? const Color(0xFF007AFF) : Colors.white70,
                              fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (subtitle != null)
                            Text(
                              subtitle,
                              style: TextStyle(
                                fontSize: 11,
                                // ignore: deprecated_member_use
                                color: isSelected ? const Color(0xFF007AFF).withOpacity(0.7) : Colors.white54,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSidebarItemWithChevron({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          splashColor: Colors.transparent,
          hoverColor: Colors.transparent,
          highlightColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: iconColor ?? Colors.white70,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.white70,
                      fontWeight: FontWeight.normal,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  size: 16,
                  color: Colors.white54,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes == 0) return '0 B';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  String _getUserHomePath() {
    // محاولة الحصول على مسار المستخدم من متغيرات البيئة
    String? homePath = Platform.environment['HOME'];
    if (homePath != null && homePath.isNotEmpty) {
      return homePath;
    }
    
    // محاولة بديلة: الحصول على اسم المستخدم وبناء المسار
    String? username = Platform.environment['USER'];
    if (username != null && username.isNotEmpty) {
      return '/home/$username';
    }
    
    // الخيار الأخير: استخدام القيمة الافتراضية
    return '/home';
  }
}
