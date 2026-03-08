import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/extensions.dart';
import '../providers/product_provider.dart';

class ProductFormPage extends ConsumerStatefulWidget {
  final String? productId;

  const ProductFormPage({super.key, this.productId});

  @override
  ConsumerState<ProductFormPage> createState() => _ProductFormPageState();
}

class _ProductFormPageState extends ConsumerState<ProductFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _slugController = TextEditingController();
  final _priceController = TextEditingController();
  final _comparePriceController = TextEditingController();
  final _unitController = TextEditingController();
  final _skuController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _stockController = TextEditingController();
  final _lowStockController = TextEditingController();
  final _tagsController = TextEditingController();

  String? _selectedCategoryId;
  final List<String> _imagePaths = [];
  final List<String> _existingImageUrls = [];
  bool _isEdit = false;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _isEdit = widget.productId != null;
    _nameController.addListener(_generateSlug);
  }

  void _generateSlug() {
    if (!_isEdit || _slugController.text.isEmpty) {
      _slugController.text = _nameController.text.toSlug;
    }
  }

  @override
  void dispose() {
    _nameController.removeListener(_generateSlug);
    _nameController.dispose();
    _slugController.dispose();
    _priceController.dispose();
    _comparePriceController.dispose();
    _unitController.dispose();
    _skuController.dispose();
    _descriptionController.dispose();
    _stockController.dispose();
    _lowStockController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  void _loadExistingProduct() {
    if (_loaded || !_isEdit) return;
    final products = ref.read(productProvider).products;
    final product = products
        .where((p) => p.id == widget.productId)
        .firstOrNull;
    if (product != null) {
      _nameController.text = product.name;
      _slugController.text = product.slug ?? '';
      _priceController.text = product.price.toString();
      if (product.comparePrice != null) {
        _comparePriceController.text = product.comparePrice.toString();
      }
      _unitController.text = product.unit ?? '';
      _skuController.text = product.sku ?? '';
      _descriptionController.text = product.description;
      _stockController.text = product.stock.toString();
      if (product.lowStockThreshold != null) {
        _lowStockController.text = product.lowStockThreshold.toString();
      }
      _tagsController.text = product.tags.join(', ');
      _selectedCategoryId = product.categoryId;
      _existingImageUrls.addAll(product.images);
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

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    final notifier = ref.read(productProvider.notifier);

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
      'slug': _slugController.text.trim(),
      'price': double.parse(_priceController.text),
      if (_comparePriceController.text.isNotEmpty)
        'comparePrice': double.parse(_comparePriceController.text),
      if (_unitController.text.isNotEmpty) 'unit': _unitController.text.trim(),
      if (_skuController.text.isNotEmpty) 'sku': _skuController.text.trim(),
      if (_selectedCategoryId != null) 'category': _selectedCategoryId,
      'description': _descriptionController.text.trim(),
      'stock': int.tryParse(_stockController.text) ?? 0,
      if (_lowStockController.text.isNotEmpty)
        'lowStockThreshold': int.parse(_lowStockController.text),
      if (tags.isNotEmpty) 'tags': tags,
      'images': imageUrls,
    };

    final result = _isEdit
        ? await notifier.updateProduct(widget.productId!, data)
        : await notifier.createProduct(data);

    if (result != null && mounted) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final productState = ref.watch(productProvider);
    _loadExistingProduct();

    final categories = ref.watch(categoriesProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Product' : 'Add Product',
            style: theme.textTheme.titleLarge),
        backgroundColor: AppTheme.surface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingBase),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Basic Info Section
              _buildSectionCard(
                context,
                title: 'Basic Information',
                icon: Icons.info_outline_rounded,
                iconColor: AppTheme.primary,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Product Name *',
                      prefixIcon: Icon(Icons.inventory_2_outlined),
                    ),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Name is required' : null,
                  ),
                  const SizedBox(height: AppTheme.spacingBase),
                  TextFormField(
                    controller: _slugController,
                    decoration: const InputDecoration(
                      labelText: 'Slug (auto-generated)',
                      prefixIcon: Icon(Icons.link_rounded),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingBase),
                  categories.when(
                    data: (cats) => DropdownButtonFormField<String>(
                      value: _selectedCategoryId,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        prefixIcon: Icon(Icons.category_outlined),
                      ),
                      items: cats
                          .map((c) => DropdownMenuItem(
                              value: c.id, child: Text(c.name)))
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _selectedCategoryId = v),
                    ),
                    loading: () => const LinearProgressIndicator(),
                    error: (_, __) =>
                        const Text('Failed to load categories'),
                  ),
                  const SizedBox(height: AppTheme.spacingBase),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description *',
                      alignLabelWithHint: true,
                    ),
                    maxLines: 4,
                    validator: (v) => (v == null || v.isEmpty)
                        ? 'Description is required'
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingBase),

              // Pricing Section
              _buildSectionCard(
                context,
                title: 'Pricing',
                icon: Icons.currency_rupee_rounded,
                iconColor: AppTheme.successColor,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _priceController,
                          decoration: const InputDecoration(
                            labelText: 'Price *',
                            prefixText: '\u20B9 ',
                          ),
                          keyboardType:
                              const TextInputType.numberWithOptions(
                                  decimal: true),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Required';
                            if (double.tryParse(v) == null) {
                              return 'Invalid';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacingMd),
                      Expanded(
                        child: TextFormField(
                          controller: _comparePriceController,
                          decoration: const InputDecoration(
                            labelText: 'Compare Price',
                            prefixText: '\u20B9 ',
                          ),
                          keyboardType:
                              const TextInputType.numberWithOptions(
                                  decimal: true),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingBase),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _unitController,
                          decoration: const InputDecoration(
                            labelText: 'Unit (e.g., kg, pcs)',
                          ),
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacingMd),
                      Expanded(
                        child: TextFormField(
                          controller: _skuController,
                          decoration: const InputDecoration(
                            labelText: 'SKU',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingBase),

              // Images Section
              _buildSectionCard(
                context,
                title: 'Product Images',
                icon: Icons.photo_library_outlined,
                iconColor: AppTheme.secondary,
                children: [
                  Wrap(
                    spacing: AppTheme.spacingSm,
                    runSpacing: AppTheme.spacingSm,
                    children: [
                      ..._existingImageUrls.map((url) => _buildImageTile(
                          url: url,
                          onRemove: () => setState(
                              () => _existingImageUrls.remove(url)))),
                      ..._imagePaths.map((path) => _buildImageTile(
                          path: path,
                          onRemove: () => setState(
                              () => _imagePaths.remove(path)))),
                      GestureDetector(
                        onTap: _pickImages,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            border:
                                Border.all(color: AppTheme.border, width: 1.5),
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusMd),
                            color: AppTheme.surface,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate_outlined,
                                  color: AppTheme.textTertiary, size: 28),
                              const SizedBox(height: 2),
                              Text(
                                'Add',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(color: AppTheme.textTertiary),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingBase),

              // Inventory Section
              _buildSectionCard(
                context,
                title: 'Inventory',
                icon: Icons.warehouse_outlined,
                iconColor: AppTheme.warningColor,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _stockController,
                          decoration: const InputDecoration(
                            labelText: 'Stock Quantity *',
                          ),
                          keyboardType: TextInputType.number,
                          validator: (v) =>
                              (v == null || v.isEmpty) ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacingMd),
                      Expanded(
                        child: TextFormField(
                          controller: _lowStockController,
                          decoration: const InputDecoration(
                            labelText: 'Low Stock Threshold',
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingBase),
                  TextFormField(
                    controller: _tagsController,
                    decoration: const InputDecoration(
                      labelText: 'Tags (comma separated)',
                      prefixIcon: Icon(Icons.label_outline_rounded),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingXl),

              // Error message
              if (productState.error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppTheme.spacingBase),
                  child: Container(
                    padding: const EdgeInsets.all(AppTheme.spacingMd),
                    decoration: BoxDecoration(
                      color: AppTheme.error.withValues(alpha: 0.1),
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusSm),
                      border: Border.all(
                          color: AppTheme.error.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded,
                            color: AppTheme.error, size: 20),
                        const SizedBox(width: AppTheme.spacingSm),
                        Expanded(
                          child: Text(
                            productState.error!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppTheme.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Gradient Save Button
              Container(
                height: 52,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: productState.isSubmitting ? null : _saveProduct,
                    borderRadius:
                        BorderRadius.circular(AppTheme.radiusLg),
                    child: Center(
                      child: productState.isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              _isEdit ? 'Update Product' : 'Save Product',
                              style:
                                  theme.textTheme.labelLarge?.copyWith(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spacing2xl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacingBase),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: Icon(icon, size: 20, color: iconColor),
              ),
              const SizedBox(width: AppTheme.spacingMd),
              Text(title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  )),
            ],
          ),
          const SizedBox(height: AppTheme.spacingBase),
          ...children,
        ],
      ),
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
                        const Icon(Icons.broken_image_outlined,
                            color: AppTheme.textTertiary))
                : Image.asset('assets/placeholder.png',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.image_outlined,
                            color: AppTheme.textTertiary)),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: AppTheme.error,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: const Icon(Icons.close_rounded,
                  size: 12, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}
