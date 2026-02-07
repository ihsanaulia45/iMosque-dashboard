import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_config.dart';
import '../../core/config/supabase_config.dart';
import '../../core/constants/api_constants.dart';
import '../../data/models/system_setting_model.dart';
import '../../data/providers/auth_provider.dart';
import '../../data/repositories/audit_log_repository.dart';
import '../../theme/app_colors.dart';
import '../shared/widgets/loading_widget.dart';
import '../shared/widgets/error_widget.dart';
import '../shared/widgets/confirm_dialog.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _auditLogRepository = AuditLogRepository();

  List<SystemSettingModel> _settings = [];
  bool _isLoading = true;
  String? _error;
  bool _tableNotFound = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _tableNotFound = false;
    });

    try {
      final response = await SupabaseConfig.client
          .from(ApiConstants.systemSettingsTable)
          .select('''
            *,
            updated_by_profile:profiles!system_settings_updated_by_fkey(full_name)
          ''')
          .order('category')
          .order('key');

      if (mounted) {
        setState(() {
          _settings = (response as List)
              .map((json) => SystemSettingModel.fromJson(json))
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        final errorStr = e.toString();
        if (errorStr.contains('system_settings') &&
            (errorStr.contains('does not exist') ||
             errorStr.contains('Could not find') ||
             errorStr.contains('schema cache') ||
             errorStr.contains('PGRST205') ||
             errorStr.contains('relation') ||
             errorStr.contains('42P01'))) {
          setState(() {
            _tableNotFound = true;
            _isLoading = false;
          });
        } else {
          setState(() {
            _error = errorStr;
            _isLoading = false;
          });
        }
      }
    }
  }

  Future<void> _editSetting(SystemSettingModel setting) async {
    final authProvider = context.read<AuthProvider>();

    if (!setting.canBeEditedBy(authProvider.currentRole.value)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('You do not have permission to edit this setting')),
      );
      return;
    }

    String? newValue;

    if (setting.valueType == 'boolean') {
      final currentBool = setting.boolValue;
      final confirm = await ConfirmDialog.show(
        context: context,
        title: 'Toggle ${setting.displayName}',
        message:
            'Change "${setting.displayName}" from ${currentBool ? "enabled" : "disabled"} to ${!currentBool ? "enabled" : "disabled"}?',
        confirmText: !currentBool ? 'Enable' : 'Disable',
      );
      if (!confirm) return;
      newValue = (!currentBool).toString();
    } else {
      newValue = await InputDialog.show(
        context: context,
        title: 'Edit ${setting.displayName}',
        message: setting.description,
        initialValue: setting.value,
        hintText: 'Enter new value',
        maxLines: setting.valueType == 'json' ? 5 : 1,
        isRequired: true,
      );
      if (newValue == null) return;
    }

    try {
      await SupabaseConfig.client
          .from(ApiConstants.systemSettingsTable)
          .update({
        'value': newValue,
        'updated_by': authProvider.currentUser!.id,
      }).eq('id', setting.id);

      // Try to log action (table may not exist yet)
      try {
        await _auditLogRepository.logAction(
          action: AuditAction.settingUpdate,
          targetType: AuditTargetType.setting,
          targetId: setting.id,
          details: {
            'key': setting.key,
            'old_value': setting.value,
            'new_value': newValue,
          },
        );
      } catch (_) {}

      _loadSettings();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('"${setting.displayName}" updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update setting: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    authProvider.updateLastActivity();

    if (_isLoading) {
      return const LoadingWidget(message: 'Loading settings...');
    }

    // Show friendly message when table doesn't exist
    if (_tableNotFound) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Settings',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 24),
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.settings_outlined,
                      size: 64,
                      color: AppColors.textDisabled,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Settings Table Not Available',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'The system_settings table has not been created yet in the database.\n'
                      'Please run the SQL migration to create the required tables.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: _loadSettings,
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return ErrorDisplayWidget(
        message: 'Failed to load settings',
        details: _error,
        onRetry: _loadSettings,
      );
    }

    // Group settings by category
    final grouped = <String, List<SystemSettingModel>>{};
    for (final setting in _settings) {
      grouped.putIfAbsent(setting.category, () => []).add(setting);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Settings',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh',
                onPressed: _loadSettings,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'System configuration and feature flags',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 24),

          if (_settings.isEmpty)
            const EmptyStateWidget(
              message: 'No settings configured',
              subtitle: 'Settings will appear here when added to the database',
              icon: Icons.settings_outlined,
            )
          else
            ...grouped.entries.map((entry) {
              final category = entry.key;
              final settings = entry.value;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _formatCategory(category),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    margin: const EdgeInsets.only(bottom: 24),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: settings.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1, indent: 16, endIndent: 16),
                      itemBuilder: (context, index) {
                        final setting = settings[index];
                        final canEdit = setting.canBeEditedBy(
                            authProvider.currentRole.value);

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 8),
                          title: Text(
                            setting.displayName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (setting.description != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  setting.description!,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 4),
                              if (setting.updatedByName != null &&
                                  setting.updatedAt != null)
                                Text(
                                  'Last updated by ${setting.updatedByName} on ${DateFormat(AppConfig.dateTimeFormat).format(setting.updatedAt!)}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textDisabled,
                                  ),
                                ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (setting.valueType == 'boolean')
                                Switch(
                                  value: setting.boolValue,
                                  onChanged: canEdit
                                      ? (_) => _editSetting(setting)
                                      : null,
                                )
                              else
                                Container(
                                  constraints:
                                      const BoxConstraints(maxWidth: 200),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.background,
                                    borderRadius: BorderRadius.circular(4),
                                    border:
                                        Border.all(color: AppColors.border),
                                  ),
                                  child: Text(
                                    setting.value,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontFamily: 'monospace',
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              if (canEdit &&
                                  setting.valueType != 'boolean') ...[
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.edit, size: 18),
                                  tooltip: 'Edit',
                                  onPressed: () => _editSetting(setting),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            }),
        ],
      ),
    );
  }

  String _formatCategory(String category) {
    return category
        .split('_')
        .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }
}
