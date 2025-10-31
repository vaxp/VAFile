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
              _buildSection(
                'Favourites',
                [
                  _buildSidebarItem(
                    icon: Icons.access_time,
                    title: 'Recents',
                    onTap: () {
                      // Navigate to recents
                    },
                  ),
                  _buildSidebarItem(
                    icon: Icons.cloud,
                    title: 'Dropbox',
                    onTap: () {
                      // Navigate to Dropbox
                    },
                  ),
                  _buildSidebarItem(
                    icon: Icons.apps,
                    title: 'Setapp',
                    onTap: () {
                      // Navigate to Setapp
                    },
                  ),
                  _buildSidebarItem(
                    icon: Icons.desktop_windows,
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
                    icon: Icons.share,
                    title: 'AirDrop',
                    onTap: () {
                      // Navigate to AirDrop
                    },
                  ),
                  _buildSidebarItem(
                    icon: Icons.apps,
                    title: 'Applications',
                    onTap: () => context.read<fm.FileManagerBloc>().add(
                      fm.LoadDirectory('/usr/share/applications'),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              _buildSection(
                'iCloud',
                [
                  _buildSidebarItem(
                    icon: Icons.share,
                    title: 'Shared',
                    onTap: () {
                      // Navigate to shared
                    },
                  ),
                  _buildSidebarItem(
                    icon: Icons.cloud,
                    title: 'iCloud Drive',
                    onTap: () {
                      // Navigate to iCloud Drive
                    },
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              _buildSection(
                'Locations',
                [
                  _buildSidebarItem(
                    icon: Icons.storage,
                    title: 'Macintosh HD',
                    onTap: () {
                      context.read<fm.FileManagerBloc>().add(fm.LoadDirectory('/'));
                    },
                  ),
                  _buildSidebarItem(
                    icon: Icons.folder,
                    title: 'Users',
                    onTap: () {
                      context.read<fm.FileManagerBloc>().add(fm.LoadDirectory('/home'));
                    },
                  ),
                  _buildSidebarItem(
                    icon: Icons.folder,
                    title: 'Applications',
                    onTap: () {
                      context.read<fm.FileManagerBloc>().add(fm.LoadDirectory('/usr/share/applications'));
                    },
                  ),
                  _buildSidebarItem(
                    icon: Icons.folder,
                    title: 'Library',
                    onTap: () {
                      context.read<fm.FileManagerBloc>().add(fm.LoadDirectory('/usr/lib'));
                    },
                  ),
                  _buildSidebarItem(
                    icon: Icons.folder,
                    title: 'System',
                    onTap: () {
                      context.read<fm.FileManagerBloc>().add(fm.LoadDirectory('/usr'));
                    },
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Connected Devices Section
              BlocBuilder<fm.FileManagerBloc, fm.FileManagerState>(
                builder: (context, state) {
                  if (state is fm.FileManagerLoaded && state.connectedDevices.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  
                  if (state is fm.FileManagerLoaded) {
                    return _buildSection(
                      'Devices',
                      state.connectedDevices.map((device) => _buildSidebarItem(
                        icon: device.icon,
                        title: device.name,
                        subtitle: '${_formatBytes(device.freeSpace)} free of ${_formatBytes(device.totalSpace)}',
                        onTap: () {
                          context.read<fm.FileManagerBloc>().add(fm.LoadDirectory(device.mountPoint));
                        },
                      )).toList(),
                    );
                  }
                  
                  return const SizedBox.shrink();
                },
              ),
              
              const SizedBox(height: 16),
              
              _buildSection(
                'Network',
                [
                  _buildSidebarItem(
                    icon: Icons.language,
                    title: 'Network',
                    onTap: () {
                      // Navigate to network
                    },
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              _buildSection(
                'Tags',
                [
                  _buildSidebarItem(
                    icon: Icons.circle,
                    iconColor: Colors.grey,
                    title: 'Grey',
                    onTap: () {
                      // Filter by grey tag
                    },
                  ),
                  _buildSidebarItem(
                    icon: Icons.circle,
                    iconColor: Colors.yellow,
                    title: 'Yellow',
                    onTap: () {
                      // Filter by yellow tag
                    },
                  ),
                  _buildSidebarItem(
                    icon: Icons.circle,
                    iconColor: Colors.red,
                    title: 'Red',
                    onTap: () {
                      // Filter by red tag
                    },
                  ),
                  _buildSidebarItem(
                    icon: Icons.circle,
                    iconColor: Colors.orange,
                    title: 'Orange',
                    onTap: () {
                      // Filter by orange tag
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white54,
              letterSpacing: 0.5,
            ),
          ),
        ),
        ...children,
      ],
    );
  }

  Widget _buildSidebarItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
    String? subtitle,
  }) {
    return BlocBuilder<fm.FileManagerBloc, fm.FileManagerState>(
      builder: (context, state) {
        bool isSelected = false;
        if (state is fm.FileManagerLoaded) {
          isSelected = state.currentPath.contains(title.toLowerCase()) ||
              (title == 'Desktop' && state.currentPath.contains('Desktop')) ||
              (title == 'Documents' && state.currentPath.contains('Documents')) ||
              (title == 'Downloads' && state.currentPath.contains('Downloads'));
        }
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(6),
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

  String _formatBytes(int bytes) {
    if (bytes == 0) return '0 B';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
