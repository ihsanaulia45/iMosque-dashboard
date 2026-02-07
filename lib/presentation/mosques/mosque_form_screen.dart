import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/api_constants.dart';
import '../../core/constants/route_constants.dart';
import '../../data/models/mosque_model.dart';
import '../../data/providers/auth_provider.dart';
import '../../data/repositories/mosque_repository.dart';
import '../../data/repositories/audit_log_repository.dart';
import '../shared/widgets/loading_widget.dart';
import '../shared/widgets/error_widget.dart';

class MosqueFormScreen extends StatefulWidget {
  final String? mosqueId;

  const MosqueFormScreen({super.key, this.mosqueId});

  @override
  State<MosqueFormScreen> createState() => _MosqueFormScreenState();
}

class _MosqueFormScreenState extends State<MosqueFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _mosqueRepository = MosqueRepository();
  final _auditLogRepository = AuditLogRepository();

  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _provinceController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  final _imageUrlController = TextEditingController();

  bool _isLoading = false;
  bool _isLoadingData = false;
  String? _error;
  MosqueModel? _existingMosque;

  bool get _isEditing => widget.mosqueId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _loadMosque();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _provinceController.dispose();
    _postalCodeController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _loadMosque() async {
    setState(() {
      _isLoadingData = true;
      _error = null;
    });

    try {
      final mosque = await _mosqueRepository.getMosqueById(widget.mosqueId!);
      if (mosque != null && mounted) {
        setState(() {
          _existingMosque = mosque;
          _nameController.text = mosque.name;
          _descriptionController.text = mosque.description ?? '';
          _addressController.text = mosque.address ?? '';
          _cityController.text = mosque.city ?? '';
          _provinceController.text = mosque.province ?? '';
          _postalCodeController.text = mosque.postalCode ?? '';
          _latitudeController.text = mosque.latitude.toString();
          _longitudeController.text = mosque.longitude.toString();
          _imageUrlController.text = mosque.imageUrl ?? '';
          _isLoadingData = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoadingData = false;
        });
      }
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      if (_isEditing) {
        await _mosqueRepository.updateMosque(widget.mosqueId!, {
          'name': _nameController.text.trim(),
          'description': _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          'address': _addressController.text.trim(),
          'city': _cityController.text.trim(),
          'province': _provinceController.text.trim(),
          'postal_code': _postalCodeController.text.trim(),
          'latitude': double.parse(_latitudeController.text.trim()),
          'longitude': double.parse(_longitudeController.text.trim()),
          'image_url': _imageUrlController.text.trim().isEmpty
              ? null
              : _imageUrlController.text.trim(),
        });

        // Try to log action (table may not exist yet)
        try {
          await _auditLogRepository.logAction(
            action: AuditAction.mosqueUpdate,
            targetType: AuditTargetType.mosque,
            targetId: widget.mosqueId!,
          );
        } catch (_) {}
      } else {
        final mosque = MosqueModel(
          id: '',
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          address: _addressController.text.trim(),
          city: _cityController.text.trim(),
          province: _provinceController.text.trim(),
          postalCode: _postalCodeController.text.trim(),
          latitude: double.parse(_latitudeController.text.trim()),
          longitude: double.parse(_longitudeController.text.trim()),
          imageUrl: _imageUrlController.text.trim().isEmpty
              ? null
              : _imageUrlController.text.trim(),
          isVerified: false,
        );

        await _mosqueRepository.createMosque(mosque);

        // Try to log action (table may not exist yet)
        try {
          await _auditLogRepository.logAction(
            action: AuditAction.mosqueCreate,
            targetType: AuditTargetType.mosque,
          );
        } catch (_) {}
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Mosque ${_isEditing ? 'updated' : 'created'} successfully'),
          ),
        );
        context.go(RouteConstants.mosques);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save mosque: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    authProvider.updateLastActivity();

    if (_isLoadingData) {
      return const LoadingWidget(message: 'Loading mosque data...');
    }

    if (_error != null && _isEditing) {
      return ErrorDisplayWidget(
        message: 'Failed to load mosque',
        details: _error,
        onRetry: _loadMosque,
      );
    }

    return SingleChildScrollView(
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
                _isEditing ? 'Edit Mosque' : 'Add New Mosque',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Form
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 700),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Basic Information',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Mosque Name *',
                          hintText: 'Enter mosque name',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Mosque name is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          hintText: 'Enter mosque description',
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _imageUrlController,
                        decoration: const InputDecoration(
                          labelText: 'Image URL',
                          hintText: 'https://example.com/image.jpg',
                        ),
                      ),

                      const SizedBox(height: 32),
                      Text(
                        'Location',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _addressController,
                        decoration: const InputDecoration(
                          labelText: 'Address *',
                          hintText: 'Enter street address',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Address is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _cityController,
                              decoration: const InputDecoration(
                                labelText: 'City *',
                                hintText: 'City',
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'City is required';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _provinceController,
                              decoration: const InputDecoration(
                                labelText: 'Province',
                                hintText: 'Province',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          SizedBox(
                            width: 150,
                            child: TextFormField(
                              controller: _postalCodeController,
                              decoration: const InputDecoration(
                                labelText: 'Postal Code',
                                hintText: 'Postal code',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _latitudeController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(decimal: true, signed: true),
                              decoration: const InputDecoration(
                                labelText: 'Latitude *',
                                hintText: '-6.200000',
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Latitude is required';
                                }
                                final lat = double.tryParse(value.trim());
                                if (lat == null || lat < -90 || lat > 90) {
                                  return 'Invalid latitude (-90 to 90)';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _longitudeController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(decimal: true, signed: true),
                              decoration: const InputDecoration(
                                labelText: 'Longitude *',
                                hintText: '106.816666',
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Longitude is required';
                                }
                                final lng = double.tryParse(value.trim());
                                if (lng == null || lng < -180 || lng > 180) {
                                  return 'Invalid longitude (-180 to 180)';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed:
                                _isLoading ? null : () => context.go(RouteConstants.mosques),
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: _isLoading ? null : _handleSubmit,
                            child: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(_isEditing ? 'Update Mosque' : 'Create Mosque'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
