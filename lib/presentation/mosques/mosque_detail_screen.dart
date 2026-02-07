import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_config.dart';
import '../../core/constants/api_constants.dart';
import '../../core/constants/route_constants.dart';
import '../../data/models/mosque_model.dart';
import '../../data/models/audit_log_model.dart';
import '../../data/providers/auth_provider.dart';
import '../../data/repositories/mosque_repository.dart';
import '../../data/repositories/audit_log_repository.dart';
import '../../theme/app_colors.dart';
import '../shared/widgets/loading_widget.dart';
import '../shared/widgets/error_widget.dart';
import '../shared/widgets/confirm_dialog.dart';

class MosqueDetailScreen extends StatefulWidget {
  final String mosqueId;

  const MosqueDetailScreen({super.key, required this.mosqueId});

  @override
  State<MosqueDetailScreen> createState() => _MosqueDetailScreenState();
}

class _MosqueDetailScreenState extends State<MosqueDetailScreen> {
  final _mosqueRepository = MosqueRepository();
  final _auditLogRepository = AuditLogRepository();

  MosqueModel? _mosque;
  List<AuditLogModel> _mosqueLogs = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMosque();
  }

  Future<void> _loadMosque() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final mosque = await _mosqueRepository.getMosqueById(widget.mosqueId);

      // Try to load audit logs (table may not exist yet)
      List<AuditLogModel> logs = [];
      try {
        logs = await _auditLogRepository.getLogsByTarget(
          targetType: AuditTargetType.mosque,
          targetId: widget.mosqueId,
          limit: 10,
        );
      } catch (_) {
        // audit_logs table may not exist yet
      }

      if (mounted) {
        setState(() {
          _mosque = mosque;
          _mosqueLogs = logs;
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

  Future<void> _toggleVerification() async {
    if (_mosque == null) return;

    final newVerified = !_mosque!.isVerified;
    final actionLabel = newVerified ? 'verify' : 'unverify';

    final confirm = await ConfirmDialog.show(
      context: context,
      title: '${actionLabel[0].toUpperCase()}${actionLabel.substring(1)} Mosque',
      message:
          'Are you sure you want to $actionLabel "${_mosque!.name}"?',
      confirmText: actionLabel[0].toUpperCase() + actionLabel.substring(1),
      isDangerous: !newVerified,
    );

    if (!confirm) return;

    try {
      await _mosqueRepository.setVerified(widget.mosqueId, newVerified);

      // Try to log action (table may not exist yet)
      try {
        await _auditLogRepository.logAction(
          action: newVerified ? AuditAction.mosqueVerify : AuditAction.mosqueReject,
          targetType: AuditTargetType.mosque,
          targetId: widget.mosqueId,
        );
      } catch (_) {}

      _loadMosque();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Mosque ${actionLabel}d successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to $actionLabel mosque: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    authProvider.updateLastActivity();

    if (_isLoading) {
      return const LoadingWidget(message: 'Loading mosque...');
    }

    if (_error != null) {
      return ErrorDisplayWidget(
        message: 'Failed to load mosque',
        details: _error,
        onRetry: _loadMosque,
      );
    }

    if (_mosque == null) {
      return const ErrorDisplayWidget(message: 'Mosque not found');
    }

    final mosque = _mosque!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back button and title
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.go(RouteConstants.mosques),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  mosque.name,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => context.go(
                  RouteConstants.getMosqueEditPath(mosque.id),
                ),
                icon: const Icon(Icons.edit, size: 18),
                label: const Text('Edit'),
              ),
            ],
          ),
          const SizedBox(height: 24),

          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 700;

              return Wrap(
                spacing: 24,
                runSpacing: 24,
                children: [
                  // Details card
                  SizedBox(
                    width: isWide ? 400 : constraints.maxWidth,
                    child: Card(
                      margin: EdgeInsets.zero,
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Details',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            const SizedBox(height: 16),
                            // Verification badge
                            _VerificationChip(isVerified: mosque.isVerified),
                            const SizedBox(height: 16),
                            _DetailRow('Address', mosque.fullAddress),
                            _DetailRow(
                              'Coordinates',
                              '${mosque.latitude.toStringAsFixed(6)}, ${mosque.longitude.toStringAsFixed(6)}',
                            ),
                            if (mosque.description != null)
                              _DetailRow('Description', mosque.description!),
                            _DetailRow(
                              'Rating',
                              '${mosque.rating.toStringAsFixed(1)} (${mosque.reviewCount} reviews)',
                            ),
                            if (mosque.facilities.isNotEmpty)
                              _DetailRow(
                                'Facilities',
                                mosque.facilities.join(', '),
                              ),
                            _DetailRow('Mosque ID', mosque.id),
                            if (mosque.createdAt != null)
                              _DetailRow(
                                'Created',
                                DateFormat(AppConfig.dateTimeFormat)
                                    .format(mosque.createdAt!),
                              ),
                            if (mosque.updatedAt != null)
                              _DetailRow(
                                'Last Updated',
                                DateFormat(AppConfig.dateTimeFormat)
                                    .format(mosque.updatedAt!),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Actions & Activity
                  SizedBox(
                    width: isWide
                        ? constraints.maxWidth - 400 - 24
                        : constraints.maxWidth,
                    child: Column(
                      children: [
                        // Actions card
                        Card(
                          margin: EdgeInsets.zero,
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Actions',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                                const SizedBox(height: 16),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    if (!mosque.isVerified)
                                      ElevatedButton.icon(
                                        onPressed: _toggleVerification,
                                        icon: const Icon(Icons.verified, size: 18),
                                        label: const Text('Verify'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.success,
                                        ),
                                      ),
                                    if (mosque.isVerified)
                                      OutlinedButton.icon(
                                        onPressed: _toggleVerification,
                                        icon: const Icon(Icons.cancel, size: 18),
                                        label: const Text('Unverify'),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: AppColors.error,
                                          side: BorderSide(
                                              color: AppColors.error.withOpacity(0.5)),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Activity log
                        Card(
                          margin: EdgeInsets.zero,
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Activity History',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                                const SizedBox(height: 16),
                                if (_mosqueLogs.isEmpty)
                                  const Text(
                                    'No activity recorded',
                                    style: TextStyle(color: AppColors.textSecondary),
                                  )
                                else
                                  ..._mosqueLogs.map(
                                    (log) => Padding(
                                      padding: const EdgeInsets.only(bottom: 12),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            width: 8,
                                            height: 8,
                                            margin: const EdgeInsets.only(top: 6),
                                            decoration: const BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  '${log.actorDisplay} - ${log.actionDescription}',
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                Text(
                                                  DateFormat(AppConfig.dateTimeFormat)
                                                      .format(log.createdAt),
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: AppColors.textSecondary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

class _VerificationChip extends StatelessWidget {
  final bool isVerified;
  const _VerificationChip({required this.isVerified});

  @override
  Widget build(BuildContext context) {
    final color = isVerified ? AppColors.success : AppColors.warning;
    final label = isVerified ? 'Verified' : 'Unverified';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
