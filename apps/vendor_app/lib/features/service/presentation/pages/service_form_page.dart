import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_theme.dart';
import '../providers/service_provider.dart';

class ServiceFormPage extends ConsumerStatefulWidget {
  final String? serviceId;

  const ServiceFormPage({super.key, this.serviceId});

  @override
  ConsumerState<ServiceFormPage> createState() => _ServiceFormPageState();
}

class _ServiceFormPageState extends ConsumerState<ServiceFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _tagsController = TextEditingController();

  String? _selectedCategoryId;
  int _selectedDuration = 60;
  final List<String> _imagePaths = [];
  final List<String> _existingImageUrls = [];
  bool _isEdit = false;
  bool _loaded = false;

  static const List<int> _durationOptions = [30, 60, 90, 120];

  @override
  void initState() {
    super.initState();
    _isEdit = widget.serviceId != null;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  void _loadExistingService() {
    if (_loaded || !_isEdit) return;
    final services = ref.read(serviceProvider).services;
    final service = services
        .where((s) => s.id == widget.serviceId)
        .firstOrNull;
    if (service != null) {
      _nameController.text = service.name;
      _descriptionController.text = service.description;
      _priceController.text = service.price.toString();
      _selectedDuration = service.durationMinutes;
      _selectedCategoryId = service.categoryId;
      _tagsController.text = service.tags.join(', ');
      _existingImageUrls.addAll(service.images);
      _loaded = true;
    }
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final images = await picker.pickMultiImage(
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 80,
    );
    if (images.isNotEmpty) {
      setState(() {
        _imagePaths.addAll(images.map((e) => e.path));
      });
    }
  }

  Future<void> _saveService() async {
    if (!_formKey.currentState!.validate()) return;

    final notifier = ref.read(serviceProvider.notifier);

    // Upload new images first
    List<String> imageUrls = List.from(_existingImageUrls);
    if (_imagePaths.isNotEmpty) {
      final uploadedUrls = await notifier.uploadImages(_imagePaths);
      imageUrls.addAll(uploadedUrls);
    }

    final tags = _tagsController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final data = {
      'name': _nameController.text.trim(),
      'description': _descriptionController.text.trim(),
      'price': double.parse(_priceController.text),
      'durationMinutes': _selectedDuration,
      if (_selectedCategoryId != null) 'category': _selectedCategoryId,
      if (tags.isNotEmpty) 'tags': tags,
      'images': imageUrls,
    };

    final result = _isEdit
        ? await notifier.updateService(widget.serviceId!, data)
        : await notifier.createService(data);

    if (result != null && mounted) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final serviceState = ref.watch(serviceProvider);
    _loadExistingService();

    final categories = ref.watch(serviceCategoriesProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Service' : 'Add Service'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingBase),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- Basic Info Section ---
              _buildSectionHeader(context, 'Basic Information',
                  icon: Icons.info_outline_rounded),
              const SizedBox(height: AppTheme.spacingMd),
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.card,
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  border: Border.all(color: AppTheme.border),
                  boxShadow: AppTheme.shadowSm,
                ),
                padding: const EdgeInsets.all(AppTheme.spacingBase),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Service Name *',
                        prefixIcon:
                            Icon(Icons.design_services_rounded, size: 20),
                      ),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Name is required' : null,
                    ),
                    const SizedBox(height: AppTheme.spacingBase),
                    categories.when(
                      data: (cats) => DropdownButtonFormField<String>(
                        value: _selectedCategoryId,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          prefixIcon:
                              Icon(Icons.category_rounded, size: 20),
                        ),
                        items: cats
                            .map((c) => DropdownMenuItem(
                                value: c.id, child: Text(c.name)))
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _selectedCategoryId = v),
                      ),
                      loading: () => const LinearProgressIndicator(),
                      error: (_, __) => Text(
                        'Failed to load categories',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.spacingXl),

              // --- Pricing Section ---
              _buildSectionHeader(context, 'Pricing & Duration',
                  icon: Icons.payments_outlined),
              const SizedBox(height: AppTheme.spacingMd),
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.card,
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  border: Border.all(color: AppTheme.border),
                  boxShadow: AppTheme.shadowSm,
                ),
                padding: const EdgeInsets.all(AppTheme.spacingBase),
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _priceController,
                        decoration: const InputDecoration(
                          labelText: 'Price *',
                          prefixText: '\u20B9 ',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Required';
                          if (double.tryParse(v) == null) return 'Invalid';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingMd),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: _selectedDuration,
                        decoration: const InputDecoration(
                          labelText: 'Duration *',
                          prefixIcon: Icon(Icons.timer_rounded, size: 20),
                        ),
                        items: _durationOptions
                            .map((d) => DropdownMenuItem(
                                  value: d,
                                  child: Text('$d min'),
                                ))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) {
                            setState(() => _selectedDuration = v);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.spacingXl),

              // --- Description Section ---
              _buildSectionHeader(context, 'Description',
                  icon: Icons.description_outlined),
              const SizedBox(height: AppTheme.spacingMd),
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.card,
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  border: Border.all(color: AppTheme.border),
                  boxShadow: AppTheme.shadowSm,
                ),
                padding: const EdgeInsets.all(AppTheme.spacingBase),
                child: TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description *',
                    alignLabelWithHint: true,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                  ),
                  maxLines: 4,
                  validator: (v) => (v == null || v.isEmpty)
                      ? 'Description is required'
                      : null,
                ),
              ),
              const SizedBox(height: AppTheme.spacingXl),

              // --- Images Section ---
              _buildSectionHeader(context, 'Service Images',
                  icon: Icons.photo_library_outlined),
              const SizedBox(height: AppTheme.spacingMd),
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.card,
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  border: Border.all(color: AppTheme.border),
                  boxShadow: AppTheme.shadowSm,
                ),
                padding: const EdgeInsets.all(AppTheme.spacingBase),
                child: Wrap(
                  spacing: AppTheme.spacingSm,
                  runSpacing: AppTheme.spacingSm,
                  children: [
                    ..._existingImageUrls.map((url) => _buildImageTile(
                        url: url,
                        onRemove: () => setState(
                            () => _existingImageUrls.remove(url)))),
                    ..._imagePaths.map((path) => _buildImageTile(
                        path: path,
                        onRemove: () =>
                            setState(() => _imagePaths.remove(path)))),
                    GestureDetector(
                      onTap: _pickImages,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          border: Border.all(
                            color: AppTheme.border,
                            style: BorderStyle.solid,
                          ),
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusMd),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate_outlined,
                                color: AppTheme.textTertiary, size: 28),
                            const SizedBox(height: 2),
                            Text(
                              'Add',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: AppTheme.textTertiary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.spacingXl),

              // --- Tags Section ---
              _buildSectionHeader(context, 'Tags',
                  icon: Icons.label_outline_rounded),
              const SizedBox(height: AppTheme.spacingMd),
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.card,
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  border: Border.all(color: AppTheme.border),
                  boxShadow: AppTheme.shadowSm,
                ),
                padding: const EdgeInsets.all(AppTheme.spacingBase),
                child: TextFormField(
                  controller: _tagsController,
                  decoration: InputDecoration(
                    labelText: 'Tags (comma separated)',
                    prefixIcon:
                        const Icon(Icons.label_rounded, size: 20),
                    hintText: 'e.g. cleaning, deep clean, home',
                    hintStyle: theme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.textTertiary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spacing2xl),

              // Error Message
              if (serviceState.error != null)
                Container(
                  margin: const EdgeInsets.only(bottom: AppTheme.spacingBase),
                  padding: const EdgeInsets.all(AppTheme.spacingMd),
                  decoration: BoxDecoration(
                    color: AppTheme.error.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    border: Border.all(
                      color: AppTheme.error.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          color: AppTheme.error, size: 20),
                      const SizedBox(width: AppTheme.spacingSm),
                      Expanded(
                        child: Text(
                          serviceState.error!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Submit Button
              ElevatedButton(
                onPressed:
                    serviceState.isSubmitting ? null : _saveService,
                child: serviceState.isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(_isEdit
                        ? 'Update Service'
                        : 'Save Service'),
              ),
              const SizedBox(height: AppTheme.spacing2xl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title,
      {required IconData icon}) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.primary),
        const SizedBox(width: AppTheme.spacingSm),
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildImageTile({
    String? url,
    String? path,
    required VoidCallback onRemove,
  }) {
    return Stack(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            color: AppTheme.surface,
            border: Border.all(color: AppTheme.border),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            child: url != null
                ? Image.network(url, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.broken_image,
                            color: AppTheme.textTertiary))
                : Image.asset('assets/placeholder.png',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.image,
                            color: AppTheme.textTertiary)),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: AppTheme.error,
                shape: BoxShape.circle,
                boxShadow: AppTheme.shadowSm,
              ),
              child: const Icon(Icons.close_rounded,
                  size: 14, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}
