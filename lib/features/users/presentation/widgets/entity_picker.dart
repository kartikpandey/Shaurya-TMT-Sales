import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/domain/user_role.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/form_widgets.dart';
import '../../domain/entities/app_user.dart';
import '../../providers/users_providers.dart';

/// Modal picker for distributor / dealer / sub-dealer records.
/// Returns the chosen entity, or `null` when dismissed.
Future<AppUser?> showEntityPicker(
  BuildContext context, {
  ExternalEntityType? onlyType,
  String? title,
}) {
  return showModalBottomSheet<AppUser>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _EntityPickerSheet(title: title, onlyType: onlyType),
  );
}

class _EntityPickerSheet extends ConsumerStatefulWidget {
  const _EntityPickerSheet({this.title, this.onlyType});

  final String? title;
  final ExternalEntityType? onlyType;

  @override
  ConsumerState<_EntityPickerSheet> createState() =>
      _EntityPickerSheetState();
}

class _EntityPickerSheetState extends ConsumerState<_EntityPickerSheet> {
  final _searchController = TextEditingController();
  ExternalEntityType? _type;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _type = widget.onlyType;
    _searchController.addListener(() {
      setState(() => _query = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final users = ref.watch(externalEntitiesProvider);
    final byId = ref.watch(usersByIdProvider);

    final filtered = users.where((user) {
      if (_type != null && user.entityType != _type) return false;
      if (_query.isEmpty) return true;
      return user.name.toLowerCase().contains(_query) ||
          (user.companyName ?? '').toLowerCase().contains(_query);
    }).toList();

    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.78,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title ?? 'Select customer',
              style: AppTextStyles.titleLarge(context),
            ),
            const SizedBox(height: 12),
            SearchField(
              controller: _searchController,
              hint: 'Search name or company...',
            ),
            const SizedBox(height: 10),
            if (widget.onlyType == null)
              SizedBox(
                height: 34,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _FilterChip(
                      label: 'All',
                      selected: _type == null,
                      onTap: () => setState(() => _type = null),
                    ),
                    ...ExternalEntityType.values.map(
                      (type) => _FilterChip(
                        label: type.label,
                        selected: _type == type,
                        onTap: () => setState(() => _type = type),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 4),
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Text(
                        'No customers match your search',
                        style: AppTextStyles.bodyMedium(
                          context,
                        ).copyWith(color: AppColors.textHint),
                      ),
                    )
                  : ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) =>
                          const Divider(height: 1, color: AppColors.borderLight),
                      itemBuilder: (context, index) {
                        final entity = filtered[index];
                        final parent = entity.parentEntityId == null
                            ? null
                            : byId[entity.parentEntityId!];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: UserAvatar(
                            initials: entity.initials,
                            size: 40,
                            accent: _colorFor(entity.entityType),
                          ),
                          title: Text(
                            entity.name,
                            style: AppTextStyles.bodyMedium(context),
                          ),
                          subtitle: Text(
                            [
                              entity.entityType?.label ?? '',
                              if (parent != null) 'under ${parent.name}',
                            ].join(' â€¢ '),
                            style: AppTextStyles.labelSmall(
                              context,
                            ).copyWith(color: AppColors.textHint),
                          ),
                          trailing: const Icon(
                            Icons.chevron_right,
                            color: AppColors.textHint,
                          ),
                          onTap: () => Navigator.pop(context, entity),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Color _colorFor(ExternalEntityType? type) => switch (type) {
    ExternalEntityType.distributor => AppColors.primaryOrange,
    ExternalEntityType.dealer => AppColors.infoBlue,
    ExternalEntityType.subDealer => AppColors.successGreen,
    null => AppColors.textHint,
  };
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primaryOrange.withValues(alpha:0.14)
                : AppColors.lightSurface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? AppColors.primaryOrange
                  : AppColors.borderLight,
            ),
          ),
          child: Text(
            label,
            style: AppTextStyles.labelSmall(context).copyWith(
              color: selected ? AppColors.primaryOrange : AppColors.textHint,
            ),
          ),
        ),
      ),
    );
  }
}
