import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_config.dart';
import '../../core/constants/api_constants.dart';
import '../../core/constants/route_constants.dart';
import '../../data/models/mosque_model.dart';
import '../../data/providers/auth_provider.dart';
import '../../data/repositories/mosque_repository.dart';
import '../../data/repositories/audit_log_repository.dart';
import '../../theme/app_colors.dart';
import '../shared/widgets/loading_widget.dart';
import '../shared/widgets/error_widget.dart';
import '../shared/widgets/confirm_dialog.dart';

class PendingMosquesScreen extends StatefulWidget {
  const PendingMosquesScreen({super.key});

  @override
  State<PendingMosquesScreen> createState() => _PendingMosquesScreenState();
}

class _PendingMosquesScreenState extends State<PendingMosquesScreen> {
  final _mosqueRepository = MosqueRepository();
  final _auditLogRepository = AuditLogRepository();

  List<MosqueModel> _mosques = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPending();
  }

  Future<void> _loadPending() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final mosques = await _mosqueRepository.getMosques(
        isVerified: false,
        pageSize: 50,
      );

      if (mounted) {
        setState(() {
          _mosques = mosques;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _verifyMosque(MosqueModel mosque) async {
    final confirm = await ConfirmDialog.show(
      context: context,
      title: 'Verify Mosque',
      message: 'Verify "${mosque.name}" and make it visible to users?',
      confirmText: 'Verify',
    );

    if (!confirm) return;

    try {
      await _mosqueRepository.setVerified(mosque.id, true);

      // Try to log action (table may not exist yet)
      try {
        await _auditLogRepository.logAction(
          action: AuditAction.mosqueVerify,
          targetType: AuditTargetType.mosque,
          targetId: mosque.id,
        );
      } catch (_) {}

      _loadPending();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('"${mosque.name}" verified successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to verify: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    authProvider.updateLastActivity();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.go(RouteConstants.mosques),
              ),
              const SizedBox(width: 8),
              Text(
                'Unverified Mosques',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 48),
            child: Text(
              '${_mosques.length} mosques waiting for verification',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ),
          const SizedBox(height: 24),

          // Content
          Expanded(
            child: _isLoading
                ? const LoadingWidget(message: 'Loading unverified mosques...')
                : _error != null
                    ? ErrorDisplayWidget(
                        message: 'Failed to load',
                        details: _error,
                        onRetry: _loadPending,
                      )
                    : _mosques.isEmpty
                        ? const EmptyStateWidget(
                            message: 'No unverified mosques',
                            subtitle: 'All mosques have been verified',
                            icon: Icons.check_circle_outline,
                          )
                        : ListView.separated(
                            itemCount: _mosques.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final mosque = _mosques[index];
                              return Card(
                                margin: EdgeInsets.zero,
                                child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                InkWell(
                                                  onTap: () => context.go(
                                                    RouteConstants
                                                        .getMosqueDetailPath(
                                                            mosque.id),
                                                  ),
                                                  child: Text(
                                                    mosque.name,
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .titleMedium
                                                        ?.copyWith(
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color:
                                                              AppColors.primary,
                                                        ),
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  mosque.fullAddress,
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    color:
                                                        AppColors.textSecondary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (mosque.createdAt != null)
                                            Text(
                                              DateFormat(AppConfig.dateFormat)
                                                  .format(mosque.createdAt!),
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: AppColors.textDisabled,
                                              ),
                                            ),
                                        ],
                                      ),
                                      if (mosque.description != null &&
                                          mosque.description!.isNotEmpty) ...[
                                        const SizedBox(height: 8),
                                        Text(
                                          mosque.description!,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                      const SizedBox(height: 16),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          OutlinedButton.icon(
                                            onPressed: () => context.go(
                                              RouteConstants
                                                  .getMosqueDetailPath(
                                                      mosque.id),
                                            ),
                                            icon: const Icon(
                                                Icons.visibility, size: 18),
                                            label: const Text('View Details'),
                                          ),
                                          const SizedBox(width: 8),
                                          ElevatedButton.icon(
                                            onPressed: () =>
                                                _verifyMosque(mosque),
                                            icon: const Icon(Icons.verified,
                                                size: 18),
                                            label: const Text('Verify'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  AppColors.success,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
