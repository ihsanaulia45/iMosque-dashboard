import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_config.dart';
import '../../core/constants/route_constants.dart';
import '../../data/models/mosque_model.dart';
import '../../data/providers/auth_provider.dart';
import '../../data/repositories/mosque_repository.dart';
import '../../theme/app_colors.dart';
import '../shared/widgets/loading_widget.dart';
import '../shared/widgets/error_widget.dart';

class MosqueListScreen extends StatefulWidget {
  const MosqueListScreen({super.key});

  @override
  State<MosqueListScreen> createState() => _MosqueListScreenState();
}

class _MosqueListScreenState extends State<MosqueListScreen> {
  final _mosqueRepository = MosqueRepository();
  final _searchController = TextEditingController();
  Timer? _debounce;

  List<MosqueModel> _mosques = [];
  int _totalCount = 0;
  int _currentPage = 1;
  final int _pageSize = 10;
  bool? _isVerifiedFilter; // null = all, true = verified, false = unverified
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMosques();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(
      Duration(milliseconds: AppConfig.searchDebounceMs),
      () {
        _currentPage = 1;
        _loadMosques();
      },
    );
  }

  Future<void> _loadMosques() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final search = _searchController.text.trim();
      final results = await Future.wait([
        _mosqueRepository.getMosques(
          search: search.isEmpty ? null : search,
          isVerified: _isVerifiedFilter,
          page: _currentPage,
          pageSize: _pageSize,
        ),
        _mosqueRepository.getMosquesCount(
          search: search.isEmpty ? null : search,
          isVerified: _isVerifiedFilter,
        ),
      ]);

      if (mounted) {
        setState(() {
          _mosques = results[0] as List<MosqueModel>;
          _totalCount = results[1] as int;
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

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    authProvider.updateLastActivity();
    final totalPages = (_totalCount / _pageSize).ceil();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mosques',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$_totalCount mosques total',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () => context.go('/mosques/pending'),
                    icon: const Icon(Icons.pending_actions, size: 18),
                    label: const Text('Unverified'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => context.go('/mosques/new'),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add Mosque'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Filters
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: 300,
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  decoration: const InputDecoration(
                    hintText: 'Search by name, address, or city...',
                    prefixIcon: Icon(Icons.search),
                    isDense: true,
                  ),
                ),
              ),
              SizedBox(
                width: 160,
                child: DropdownButtonFormField<bool?>(
                  value: _isVerifiedFilter,
                  decoration: const InputDecoration(
                    labelText: 'Verification',
                    isDense: true,
                  ),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('All')),
                    DropdownMenuItem(value: true, child: Text('Verified')),
                    DropdownMenuItem(value: false, child: Text('Unverified')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _isVerifiedFilter = value;
                      _currentPage = 1;
                    });
                    _loadMosques();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Data table
          Expanded(
            child: _isLoading
                ? const LoadingWidget(message: 'Loading mosques...')
                : _error != null
                    ? ErrorDisplayWidget(
                        message: 'Failed to load mosques',
                        details: _error,
                        onRetry: _loadMosques,
                      )
                    : _mosques.isEmpty
                        ? const EmptyStateWidget(
                            message: 'No mosques found',
                            icon: Icons.mosque_outlined,
                          )
                        : Card(
                            margin: EdgeInsets.zero,
                            child: Column(
                              children: [
                                Expanded(
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: SingleChildScrollView(
                                      child: DataTable(
                                        columns: const [
                                          DataColumn(label: Text('Mosque')),
                                          DataColumn(label: Text('Location')),
                                          DataColumn(label: Text('Status')),
                                          DataColumn(label: Text('Rating')),
                                          DataColumn(label: Text('Reviews')),
                                          DataColumn(label: Text('Created')),
                                        ],
                                        rows: _mosques.map((mosque) {
                                          return DataRow(
                                            cells: [
                                              DataCell(
                                                InkWell(
                                                  onTap: () => context.go(
                                                    RouteConstants.getMosqueDetailPath(mosque.id),
                                                  ),
                                                  child: SizedBox(
                                                    width: 250,
                                                    child: Text(
                                                      mosque.name,
                                                      style: const TextStyle(
                                                        fontWeight: FontWeight.w500,
                                                        color: AppColors.primary,
                                                      ),
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              DataCell(
                                                SizedBox(
                                                  width: 200,
                                                  child: Text(
                                                    mosque.shortLocation,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ),
                                              DataCell(_VerificationBadge(isVerified: mosque.isVerified)),
                                              DataCell(
                                                Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    const Icon(Icons.star,
                                                        color: AppColors.accentGold, size: 16),
                                                    const SizedBox(width: 4),
                                                    Text(mosque.rating.toStringAsFixed(1)),
                                                  ],
                                                ),
                                              ),
                                              DataCell(Text(mosque.reviewCount.toString())),
                                              DataCell(Text(
                                                mosque.createdAt != null
                                                    ? DateFormat(AppConfig.dateFormat)
                                                        .format(mosque.createdAt!)
                                                    : '-',
                                              )),
                                            ],
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                  ),
                                ),

                                // Pagination
                                if (totalPages > 1)
                                  Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Text(
                                          'Page $_currentPage of $totalPages',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        IconButton(
                                          icon: const Icon(Icons.chevron_left),
                                          onPressed: _currentPage > 1
                                              ? () {
                                                  setState(() => _currentPage--);
                                                  _loadMosques();
                                                }
                                              : null,
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.chevron_right),
                                          onPressed: _currentPage < totalPages
                                              ? () {
                                                  setState(() => _currentPage++);
                                                  _loadMosques();
                                                }
                                              : null,
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
    );
  }
}

class _VerificationBadge extends StatelessWidget {
  final bool isVerified;
  const _VerificationBadge({required this.isVerified});

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
