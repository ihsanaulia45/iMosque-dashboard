import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/route_constants.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../theme/app_colors.dart';
import '../widgets/confirm_dialog.dart';

/// Main layout wrapper for admin dashboard
class AdminLayout extends StatefulWidget {
  final Widget child;

  const AdminLayout({
    super.key,
    required this.child,
  });

  @override
  State<AdminLayout> createState() => _AdminLayoutState();
}

class _AdminLayoutState extends State<AdminLayout> {
  bool _isSidebarExpanded = true;

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    final isTablet = screenWidth >= 768 && screenWidth < 1024;

    // Auto-collapse sidebar on smaller screens
    if (isMobile) {
      _isSidebarExpanded = false;
    }

    // Show session warning dialog
    if (authProvider.showSessionWarning) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showSessionWarningDialog(context, authProvider);
      });
    }

    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          if (!isMobile || _isSidebarExpanded)
            _Sidebar(
              isExpanded: _isSidebarExpanded || isMobile,
              onToggle: () {
                setState(() {
                  _isSidebarExpanded = !_isSidebarExpanded;
                });
              },
              isMobile: isMobile,
              onClose: isMobile
                  ? () {
                      setState(() {
                        _isSidebarExpanded = false;
                      });
                    }
                  : null,
            ),

          // Main content
          Expanded(
            child: Column(
              children: [
                // Header
                _Header(
                  onMenuPressed: isMobile
                      ? () {
                          setState(() {
                            _isSidebarExpanded = true;
                          });
                        }
                      : null,
                  isMobile: isMobile,
                ),

                // Content
                Expanded(
                  child: Container(
                    color: AppColors.background,
                    child: widget.child,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSessionWarningDialog(
      BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(Icons.access_time, color: AppColors.warning),
            SizedBox(width: 12),
            Text('Session Expiring'),
          ],
        ),
        content: const Text(
          'Your session will expire in 5 minutes due to inactivity.\n\n'
          'Click "Continue Session" to stay logged in.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              authProvider.signOut();
            },
            child: const Text('Logout Now'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              authProvider.dismissSessionWarning();
            },
            child: const Text('Continue Session'),
          ),
        ],
      ),
    );
  }
}

/// Sidebar navigation
class _Sidebar extends StatelessWidget {
  final bool isExpanded;
  final VoidCallback onToggle;
  final bool isMobile;
  final VoidCallback? onClose;

  const _Sidebar({
    required this.isExpanded,
    required this.onToggle,
    required this.isMobile,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final currentLocation = GoRouterState.of(context).matchedLocation;
    final authProvider = context.watch<AuthProvider>();

    final sidebarWidth = isExpanded ? 260.0 : 70.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: isMobile ? 260.0 : sidebarWidth,
      child: Material(
        color: AppColors.sidebarBackground,
        child: Column(
          children: [
            // Logo & Brand
            Container(
              height: 64,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Icon(
                    Icons.mosque,
                    color: AppColors.sidebarIcon,
                    size: 32,
                  ),
                  if (isExpanded || isMobile) ...[
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'iMosque Admin',
                        style: TextStyle(
                          color: AppColors.sidebarText,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                  if (isMobile && onClose != null)
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.sidebarIcon),
                      onPressed: onClose,
                    ),
                ],
              ),
            ),

            const Divider(color: AppColors.sidebarHover, height: 1),

            // Navigation items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _NavItem(
                    icon: Icons.dashboard,
                    label: 'Dashboard',
                    isSelected: currentLocation == RouteConstants.dashboard,
                    isExpanded: isExpanded || isMobile,
                    onTap: () {
                      context.go(RouteConstants.dashboard);
                      onClose?.call();
                    },
                  ),
                  _NavItem(
                    icon: Icons.people,
                    label: 'Users',
                    isSelected: currentLocation.startsWith('/users'),
                    isExpanded: isExpanded || isMobile,
                    onTap: () {
                      context.go(RouteConstants.users);
                      onClose?.call();
                    },
                  ),
                  _NavItem(
                    icon: Icons.mosque,
                    label: 'Mosques',
                    isSelected: currentLocation.startsWith('/mosques'),
                    isExpanded: isExpanded || isMobile,
                    onTap: () {
                      context.go(RouteConstants.mosques);
                      onClose?.call();
                    },
                  ),
                  _NavItem(
                    icon: Icons.history,
                    label: 'Audit Logs',
                    isSelected: currentLocation.startsWith('/logs'),
                    isExpanded: isExpanded || isMobile,
                    onTap: () {
                      context.go(RouteConstants.auditLogs);
                      onClose?.call();
                    },
                  ),
                  _NavItem(
                    icon: Icons.settings,
                    label: 'Settings',
                    isSelected: currentLocation.startsWith('/settings'),
                    isExpanded: isExpanded || isMobile,
                    onTap: () {
                      context.go(RouteConstants.settings);
                      onClose?.call();
                    },
                  ),
                ],
              ),
            ),

            const Divider(color: AppColors.sidebarHover, height: 1),

            // Collapse toggle (desktop only)
            if (!isMobile)
              InkWell(
                onTap: onToggle,
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: isExpanded
                        ? MainAxisAlignment.end
                        : MainAxisAlignment.center,
                    children: [
                      Icon(
                        isExpanded
                            ? Icons.chevron_left
                            : Icons.chevron_right,
                        color: AppColors.sidebarTextSecondary,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Navigation item in sidebar
class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final bool isExpanded;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.isExpanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: isSelected ? AppColors.sidebarActive : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          hoverColor: AppColors.sidebarHover,
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isSelected
                      ? AppColors.sidebarText
                      : AppColors.sidebarTextSecondary,
                  size: 24,
                ),
                if (isExpanded) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        color: isSelected
                            ? AppColors.sidebarText
                            : AppColors.sidebarTextSecondary,
                        fontSize: 14,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Header bar
class _Header extends StatelessWidget {
  final VoidCallback? onMenuPressed;
  final bool isMobile;

  const _Header({
    this.onMenuPressed,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final profile = authProvider.currentProfile;

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.divider),
        ),
      ),
      child: Row(
        children: [
          // Mobile menu button
          if (isMobile && onMenuPressed != null)
            IconButton(
              icon: const Icon(Icons.menu),
              onPressed: onMenuPressed,
            ),

          const Spacer(),

          // User info & menu
          PopupMenuButton<String>(
            offset: const Offset(0, 50),
            child: Row(
              children: [
                // Avatar
                CircleAvatar(
                  backgroundColor: AppColors.primary,
                  radius: 18,
                  child: Text(
                    profile?.initials ?? '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Name & role
                if (!isMobile)
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile?.displayName ?? 'Admin',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        profile?.role.displayName ?? 'Unknown',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                const SizedBox(width: 8),
                const Icon(Icons.keyboard_arrow_down),
              ],
            ),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person, size: 20),
                    SizedBox(width: 12),
                    Text('My Profile'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 20, color: AppColors.error),
                    SizedBox(width: 12),
                    Text('Logout', style: TextStyle(color: AppColors.error)),
                  ],
                ),
              ),
            ],
            onSelected: (value) async {
              if (value == 'profile') {
                context.go(RouteConstants.profile);
              } else if (value == 'logout') {
                final confirm = await ConfirmDialog.show(
                  context: context,
                  title: 'Logout',
                  message: 'Are you sure you want to logout?',
                  confirmText: 'Logout',
                  isDangerous: true,
                );
                if (confirm) {
                  authProvider.signOut();
                }
              }
            },
          ),
        ],
      ),
    );
  }
}
