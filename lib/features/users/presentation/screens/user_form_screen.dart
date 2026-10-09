import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/domain/user_role.dart';
import '../../../../core/permissions/permission_service.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/dialogs.dart';
import '../../../../core/widgets/form_widgets.dart';
import '../../../auth/providers/auth_providers.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/entities/password_hasher.dart';
import '../../providers/users_providers.dart';

enum UserFormMode { internal, external }

/// Create or edit an internal team member or an external customer record.
/// Every role/parent combination is validated against [PermissionService].
class UserFormScreen extends ConsumerStatefulWidget {
  const UserFormScreen({
    super.key,
    this.editing,
    this.initialType = UserFormMode.internal,
    this.presetEntityType,
  });

  final AppUser? editing;
  final UserFormMode initialType;
  final ExternalEntityType? presetEntityType;

  @override
  ConsumerState<UserFormScreen> createState() => _UserFormScreenState();
}

class _UserFormScreenState extends ConsumerState<UserFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _companyController = TextEditingController();
  final _addressController = TextEditingController();

  late UserFormMode _mode;
  InternalRole? _role;
  String? _reportsToId;
  ExternalEntityType? _entityType;
  String? _parentId;
  bool _isActive = true;
  bool _saving = false;

  bool get _isEditing => widget.editing != null;

  @override
  void initState() {
    super.initState();
    final editing = widget.editing;
    if (editing != null) {
      _mode =
          editing.isInternal ? UserFormMode.internal : UserFormMode.external;
      _nameController.text = editing.name;
      _emailController.text = editing.email;
      _phoneController.text = editing.phone;
      _companyController.text = editing.companyName ?? '';
      _addressController.text = editing.address ?? '';
      _role = editing.role;
      _reportsToId = editing.reportsToId;
      _entityType = editing.entityType;
      _parentId = editing.parentEntityId;
      _isActive = editing.isActive;
    } else {
      _mode = widget.initialType;
      _entityType = widget.presetEntityType;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _companyController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final actor = ref.read(currentUserProvider);
    final actorRole = actor?.role;
    if (actor == null || actorRole == null) return;

    final isInternal = _mode == UserFormMode.internal;

    if (_isEditing) {
      final target = widget.editing!;
      final allowed =
          target.isInternal
              ? PermissionService.canEditInternalUser(actorRole, target.role!)
              : PermissionService.canEditExternalEntity(
                actorRole,
                target.entityType!,
              );
      if (!allowed) {
        showAppSnack(
          context,
          'You do not have permission to edit this user',
          isError: true,
        );
        return;
      }
    } else {
      final allowed =
          isInternal
              ? PermissionService.canCreateInternalRole(actorRole, _role!)
              : PermissionService.canCreateExternalEntity(
                actorRole,
                _entityType!,
              );
      if (!allowed) {
        showAppSnack(
          context,
          'Your role cannot create this user',
          isError: true,
        );
        return;
      }
    }

    setState(() => _saving = true);

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;
    final company = _companyController.text.trim();
    final address = _addressController.text.trim();

    late final AppUser saved;
    if (_isEditing) {
      final target = widget.editing!;
      final bool passwordChanged = password.isNotEmpty;
      saved = target.copyWith(
        name: name,
        email: email,
        phone: phone,
        role: isInternal ? _role : null,
        entityType: isInternal ? null : _entityType,
        reportsToId: isInternal ? _reportsToId : null,
        parentEntityId: isInternal ? null : _parentId,
        companyName: isInternal ? null : (company.isEmpty ? null : company),
        address: isInternal ? null : (address.isEmpty ? null : address),
        isActive: _isActive,
        passwordHash:
            passwordChanged
                ? PasswordHasher.hash(password)
                : target.passwordHash,
        clearReportsTo: isInternal && _reportsToId == null,
        clearParentEntity: isInternal || _parentId == null,
      );
      await ref.read(usersRepositoryProvider).update(saved);
    } else {
      saved = AppUser(
        id: '',
        kind: isInternal ? UserKind.internal : UserKind.external,
        name: name,
        email: email,
        phone: phone,
        passwordHash: PasswordHasher.hash(
          password.isEmpty ? AppConstants.demoPassword : password,
        ),
        role: isInternal ? _role : null,
        entityType: isInternal ? null : _entityType,
        reportsToId: isInternal ? _reportsToId : null,
        parentEntityId: isInternal ? null : _parentId,
        companyName: isInternal || company.isEmpty ? null : company,
        address: isInternal || address.isEmpty ? null : address,
        createdBy: actor.id,
        createdAt: DateTime.now(),
        isActive: _isActive,
      );
      await ref.read(usersRepositoryProvider).create(saved);
    }

    ref.read(dataVersionProvider.notifier).increment();
    if (!mounted) return;
    setState(() => _saving = false);
    showAppSnack(context, _isEditing ? 'User updated' : 'User created');
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final actor = ref.watch(currentUserProvider);
    final actorRole = actor?.role;
    final all = ref.watch(allUsersProvider);
    final scope = ref.watch(userScopeProvider).toSet();

    final selfId = widget.editing?.id ?? actor?.id;

    final roleChoices =
        InternalRole.values
            .where(
              (r) =>
                  actorRole != null &&
                  PermissionService.canCreateInternalRole(actorRole, r) &&
                  (_role == r ||
                      PermissionService.canEditInternalUser(actorRole, r)),
            )
            .toList();

    final entityChoices =
        ExternalEntityType.values
            .where(
              (type) =>
                  actorRole != null &&
                  PermissionService.canCreateExternalEntity(actorRole, type),
            )
            .toList();

    final managerChoices =
        all
            .where(
              (u) =>
                  u.isInternal &&
                  u.id != selfId &&
                  (scope.contains(u.id) || u.id == actor?.id) &&
                  u.isActive &&
                  (_role == null || (u.role?.rank ?? 99) < _role!.rank),
            )
            .toList()
          ..sort((a, b) => (a.role!.rank).compareTo(b.role!.rank));

    final parentChoices =
        _entityType == null || _entityType!.parentType == null
            ? const <AppUser>[]
            : all
                .where(
                  (u) =>
                      u.isExternal &&
                      u.id != selfId &&
                      u.entityType == _entityType!.parentType &&
                      u.isActive,
                )
                .toList();

    if (!_isEditing && managerChoices.isEmpty) {
      _reportsToId = null;
    }

    return Scaffold(
      appBar: CustomAppBar(
        title:
            _isEditing
                ? 'Edit user'
                : _mode == UserFormMode.internal
                ? 'New team member'
                : 'New customer',
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              /*    if (!_isEditing) ...[
                Row(
                  children: [
                    Expanded(
                      child: _ModeButton(
                        label: 'Team member',
                        icon: Icons.badge_outlined,
                        selected: _mode == UserFormMode.internal,
                        onTap: () => setState(() {
                          _mode = UserFormMode.internal;
                          _parentId = null;
                        }),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ModeButton(
                        label: 'Customer',
                        icon: Icons.storefront_outlined,
                        selected: _mode == UserFormMode.external,
                        onTap: () => setState(() {
                          _mode = UserFormMode.external;
                          _reportsToId = null;
                          _role = null;
                        }),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ], */
              AppTextField(
                controller: _nameController,
                label:
                    _mode == UserFormMode.external
                        ? 'Contact person name *'
                        : 'Full name *',
                hint:
                    'e.g. ${_mode == UserFormMode.internal ? 'Rahul Mehta' : 'Suresh Patil'}',
                validator:
                    (value) =>
                        (value == null || value.trim().isEmpty)
                            ? 'Name is required'
                            : null,
              ),
              const SizedBox(height: 14),

              if (_mode == UserFormMode.internal) ...[
                DropdownButtonFormField<InternalRole>(
                  value: _role,
                  decoration: const InputDecoration(labelText: 'Role *'),
                  items: [
                    for (final role in roleChoices)
                      DropdownMenuItem(value: role, child: Text(role.label)),
                  ],
                  onChanged:
                      _saving
                          ? null
                          : (value) => setState(() {
                            _role = value;
                            if (_reportsToId != null &&
                                value == InternalRole.salesManager) {
                              _reportsToId = null;
                            }
                          }),
                  validator: (_) => _role == null ? 'Select a role' : null,
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  value: _reportsToId,
                  decoration: InputDecoration(
                    labelText:
                        _role == InternalRole.salesManager
                            ? 'Reports to'
                            : 'Reports to *',
                  ),
                  items: [
                    if (_role == InternalRole.salesManager)
                      const DropdownMenuItem<String>(
                        value: '',
                        child: Text('Top of hierarchy'),
                      ),
                    for (final manager in managerChoices)
                      DropdownMenuItem(
                        value: manager.id,
                        child: Text(
                          '${manager.name} (${manager.role!.shortLabel})',
                        ),
                      ),
                  ],
                  onChanged:
                      _saving
                          ? null
                          : (value) => setState(
                            () =>
                                _reportsToId =
                                    (value == null || value.isEmpty)
                                        ? null
                                        : value,
                          ),
                  validator: (_) {
                    if (_role == InternalRole.salesManager) return null;
                    return _reportsToId == null
                        ? 'Select who this person reports to'
                        : null;
                  },
                ),
              ] else ...[
                DropdownButtonFormField<ExternalEntityType>(
                  value: _entityType,
                  decoration: const InputDecoration(
                    labelText: 'Customer type *',
                  ),
                  items: [
                    for (final type in entityChoices)
                      DropdownMenuItem(value: type, child: Text(type.label)),
                  ],
                  onChanged:
                      _saving
                          ? null
                          : (value) => setState(() {
                            _entityType = value;
                            _parentId = null;
                          }),
                  validator:
                      (_) =>
                          _entityType == null ? 'Select a customer type' : null,
                ),
                const SizedBox(height: 14),
                if (_entityType != null && _entityType!.parentType != null) ...[
                  DropdownButtonFormField<String>(
                    value: _parentId,
                    decoration: InputDecoration(
                      labelText: 'Parent ${_entityType!.parentType!.label} *',
                    ),
                    items: [
                      for (final parent in parentChoices)
                        DropdownMenuItem(
                          value: parent.id,
                          child: Text(
                            '${parent.name} (${parent.companyName ?? 'no company'})',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged:
                        _saving
                            ? null
                            : (value) => setState(() => _parentId = value),
                    validator:
                        (_) =>
                            _parentId == null
                                ? 'Select the parent ${_entityType!.parentType!.label.toLowerCase()}'
                                : null,
                  ),
                ] else if (_entityType == ExternalEntityType.distributor) ...[
                  Text(
                    'Distributors sit at the top of the customer hierarchy, '
                    'so no parent is required.',
                    style: AppTextStyles.labelSmall(
                      context,
                    ).copyWith(color: AppColors.textHint),
                  ),
                ],
                const SizedBox(height: 14),
                AppTextField(
                  controller: _companyController,
                  label: 'Company / firm name',
                  hint: 'e.g. Shree Traders',
                ),
                const SizedBox(height: 14),
                AppTextField(
                  controller: _addressController,
                  label: 'Address',
                  maxLines: 2,
                  hint: 'Shop / godown address',
                ),
              ],

              const SizedBox(height: 14),
              AppTextField(
                controller: _emailController,
                label: 'Email',
                keyboardType: TextInputType.emailAddress,
                hint: 'name@example.com',
                validator: (value) {
                  final text = value?.trim() ?? '';
                  if (text.isEmpty) return null;
                  final ok = RegExp(
                    r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                  ).hasMatch(text);
                  return ok ? null : 'Enter a valid email address';
                },
              ),
              const SizedBox(height: 14),
              AppTextField(
                controller: _phoneController,
                label: 'Phone',
                keyboardType: TextInputType.phone,
                hint: '10-digit mobile number',
                validator: (value) {
                  final text = (value ?? '').trim();
                  if (text.isEmpty) return 'Phone is required';
                  if (!RegExp(r'^\d{10}$').hasMatch(text)) {
                    return 'Enter a 10-digit mobile number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              AppTextField(
                controller: _passwordController,
                label: _isEditing ? 'Reset password (optional)' : 'Password',
                obscureText: true,
                hint:
                    _isEditing
                        ? 'Leave blank to keep the current password'
                        : 'Leave blank to use ${AppConstants.demoPassword}',
              ),

              if (_isEditing) ...[
                const SizedBox(height: 16),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Active account',
                    style: AppTextStyles.bodyMedium(context),
                  ),
                  subtitle: Text(
                    'Inactive users cannot sign in',
                    style: AppTextStyles.labelSmall(
                      context,
                    ).copyWith(color: AppColors.textHint),
                    maxLines: 1,
                  ),
                  value: _isActive,
                  activeColor: AppColors.primaryOrange,
                  onChanged:
                      _saving
                          ? null
                          : (value) => setState(() => _isActive = value),
                ),
              ],

              const SizedBox(height: 24),
              CustomButton(
                label: _isEditing ? 'Save changes' : 'Create Customer',
                isLoading: _saving,
                icon: _isEditing ? Icons.save_outlined : Icons.person_add_alt,
                onPressed: _save,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color:
              selected
                  ? AppColors.primaryOrange.withValues(alpha: 0.12)
                  : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                selected
                    ? AppColors.primaryOrange.withValues(alpha: 0.6)
                    : AppColors.borderLight,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: selected ? AppColors.primaryOrange : AppColors.textHint,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: AppTextStyles.labelMedium(context).copyWith(
                color: selected ? AppColors.primaryOrange : AppColors.textHint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
