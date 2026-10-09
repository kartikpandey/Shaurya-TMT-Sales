import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/permissions/permission_service.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/dialogs.dart';
import '../../../../core/widgets/form_widgets.dart';
import '../../../auth/providers/auth_providers.dart';
import '../../../users/domain/entities/app_user.dart';
import '../../../users/providers/users_providers.dart';
import '../../../users/presentation/widgets/entity_picker.dart';
import '../../domain/entities/order.dart';
import '../../domain/entities/product.dart';
import '../../providers/orders_providers.dart';

/// Create or edit an order. Editing an existing order requires permission:
/// owners edit their own, heads edit orders booked by their downline.
class OrderFormScreen extends ConsumerStatefulWidget {
  const OrderFormScreen({super.key, this.editing});

  final Order? editing;

  @override
  ConsumerState<OrderFormScreen> createState() => _OrderFormScreenState();
}

class _OrderFormScreenState extends ConsumerState<OrderFormScreen> {
  final _remarksController = TextEditingController();

  AppUser? _entity;
  final Map<String, int> _quantities = {};
  bool _saving = false;

  bool get _isEditing => widget.editing != null;

  @override
  void initState() {
    super.initState();
    final editing = widget.editing;
    if (editing != null) {
      _remarksController.text = editing.remarks ?? '';
      for (final item in editing.items) {
        _quantities[item.productId] = item.quantity;
      }
      _entity = ref.read(usersByIdProvider)[editing.entityId];
    }
  }

  @override
  void dispose() {
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _pickEntity() async {
    final picked = await showEntityPicker(context, title: 'Customer for this order');
    if (picked != null) setState(() => _entity = picked);
  }

  Future<void> _save() async {
    final entity = _entity;
    final user = ref.read(currentUserProvider);
    if (entity == null || user == null) return;

    final products = ref.read(productsProvider);
    final items = <OrderItem>[
      for (final product in products)
        if ((_quantities[product.id] ?? 0) > 0)
          OrderItem(
            productId: product.id,
            name: product.name,
            size: product.size,
            grade: product.grade,
            quantity: _quantities[product.id]!,
            unitPrice: product.unitPrice,
          ),
    ];
    if (items.isEmpty) {
      showAppSnack(context, 'Add at least one product', isError: true);
      return;
    }

    setState(() => _saving = true);

    final remarks = _remarksController.text.trim();
    if (_isEditing) {
      final updated = widget.editing!.copyWith(
        items: items,
        entityId: entity.id,
        remarks: remarks,
        clearRemarks: remarks.isEmpty,
        updatedAt: DateTime.now(),
      );
      await ref.read(ordersRepositoryProvider).update(updated);
    } else {
      final order = newDraftOrder(
        owner: user,
        entityId: entity.id,
        items: items,
        remarks: remarks.isEmpty ? null : remarks,
      );
      await ref.read(ordersRepositoryProvider).create(order);
    }

    ref.read(dataVersionProvider.notifier).increment();
    if (!mounted) return;
    setState(() => _saving = false);
    showAppSnack(context, _isEditing ? 'Order updated' : 'Order booked');
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final products = ref.watch(productsProvider);
    final byId = ref.watch(usersByIdProvider);

    final downlineIds = ref.watch(downlineUsersProvider).map((u) => u.id).toSet();
    final canEdit = !_isEditing ||
        (user?.role != null &&
            PermissionService.canEditOrder(
              actor: user!.role!,
              targetIsSelf: widget.editing!.ownerId == user.id,
              targetInDownline: downlineIds.contains(widget.editing!.ownerId),
            ));

    double total = 0;
    for (final product in products) {
      total += (_quantities[product.id] ?? 0) * product.unitPrice;
    }

    return Scaffold(
      appBar: CustomAppBar(title: _isEditing ? 'Edit order' : 'New order'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (!canEdit)
              _Banner(
                icon: Icons.lock_outline,
                color: AppColors.warningRed,
                message: 'You do not have permission to edit this order.',
              ),

            if (_isEditing && widget.editing != null) ...[
              _Banner(
                icon: Icons.info_outline,
                color: AppColors.infoBlue,
                message:
                    'Booked by ${byId[widget.editing!.ownerId]?.name ?? 'Unknown'} '
                    'on ${AppFormatters.formatDate(widget.editing!.createdAt)} â€¢ '
                    'Status: ${widget.editing!.status.name.toUpperCase()}',
              ),
              const SizedBox(height: 12),
            ],

            Text('Customer', style: AppTextStyles.labelMedium(context)),
            const SizedBox(height: 6),
            InkWell(
              onTap: canEdit ? _pickEntity : null,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _entity == null
                        ? AppColors.borderLight
                        : AppColors.primaryOrange.withValues(alpha:0.5),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.storefront_outlined,
                      color: AppColors.primaryOrange,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _entity?.name ?? 'Tap to select a customer',
                        style: AppTextStyles.bodyMedium(context).copyWith(
                          color: _entity == null
                              ? AppColors.textHint
                              : AppColors.textDark,
                        ),
                      ),
                    ),
                    if (canEdit)
                      const Icon(
                        Icons.swap_horiz,
                        size: 18,
                        color: AppColors.textHint,
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Products',
                    style: AppTextStyles.titleMedium(context),
                  ),
                ),
                Text(
                  '${products.length} in catalog',
                  style: AppTextStyles.labelSmall(
                    context,
                  ).copyWith(color: AppColors.textHint),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...products.map(
              (product) => _ProductRow(
                product: product,
                quantity: _quantities[product.id] ?? 0,
                enabled: canEdit && !_saving,
                onChanged: (value) =>
                    setState(() => _quantities[product.id] = value),
              ),
            ),

            const SizedBox(height: 16),
            AppTextField(
              controller: _remarksController,
              label: 'Order reference (optional)',
              hint: 'PO number or short reference',
              enabled: canEdit,
            ),

            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryOrange.withValues(alpha:0.07),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.primaryOrange.withValues(alpha:0.25),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order total',
                          style: AppTextStyles.labelSmall(
                            context,
                          ).copyWith(color: AppColors.textHint),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          AppFormatters.formatCurrency(total),
                          style: AppTextStyles.numericMedium(context),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${_quantities.values.fold<int>(0, (sum, q) => sum + q)} units',
                    style: AppTextStyles.labelMedium(
                      context,
                    ).copyWith(color: AppColors.textHint),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            CustomButton(
              label: _isEditing ? 'Save changes' : 'Book order',
              isLoading: _saving,
              isEnabled: canEdit && !_saving,
              icon: _isEditing ? Icons.save_outlined : Icons.check_rounded,
              onPressed: _save,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.icon, required this.color, required this.message});

  final IconData icon;
  final Color color;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha:0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha:0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.bodySmall(context).copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductRow extends StatelessWidget {
  const _ProductRow({
    required this.product,
    required this.quantity,
    required this.enabled,
    required this.onChanged,
  });

  final Product product;
  final int quantity;
  final bool enabled;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final selected = quantity > 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: selected
            ? AppColors.primaryOrange.withValues(alpha:0.06)
            : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected
              ? AppColors.primaryOrange.withValues(alpha:0.4)
              : AppColors.borderLight,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name, style: AppTextStyles.bodyMedium(context)),
                const SizedBox(height: 2),
                Text(
                  '${product.size} â€¢ ${product.grade} â€¢ '
                  '${AppFormatters.formatCurrency(product.unitPrice)}/${product.unit}'
                  '${product.inStock ? '' : ' â€¢ Out of stock'}',
                  style: AppTextStyles.labelSmall(
                    context,
                  ).copyWith(color: AppColors.textHint),
                ),
              ],
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: enabled && quantity > 0
                ? () => onChanged(quantity - 1)
                : null,
            icon: const Icon(Icons.remove_circle_outline, size: 20),
          ),
          SizedBox(
            width: 24,
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: AppTextStyles.titleMedium(
                context,
              ).copyWith(color: selected ? AppColors.primaryOrange : AppColors.textHint),
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: enabled && product.inStock
                ? () => onChanged(quantity + 1)
                : null,
            icon: const Icon(Icons.add_circle_outline, size: 20),
          ),
        ],
      ),
    );
  }
}
