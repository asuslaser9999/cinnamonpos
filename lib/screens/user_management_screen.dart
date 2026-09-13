import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/auth_config.dart';
import '../core/guards/owner_gate.dart';
import '../models/app_user.dart';
import '../models/user_role.dart';
import '../notifiers/user_management_notifier.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserManagementNotifier>().loadUsers();
    });
  }

  Future<void> _openUserForm({AppUser? user}) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _UserFormSheet(user: user),
    );

    if (result == true && mounted) {
      final notifier = context.read<UserManagementNotifier>();
      if (notifier.successMessage != null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(notifier.successMessage!)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<UserManagementNotifier>();

    return OwnerGate(
      child: Scaffold(
        appBar: AppBar(title: const Text('Kelola User')),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: notifier.isSaving ? null : () => _openUserForm(),
          icon: const Icon(Icons.person_add_outlined),
          label: const Text('Tambah User'),
        ),
        body: RefreshIndicator(
          onRefresh: notifier.loadUsers,
          child: notifier.isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (notifier.errorMessage != null)
                      Card(
                        color: Theme.of(context).colorScheme.errorContainer,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(notifier.errorMessage!),
                        ),
                      ),
                    if (notifier.users.isEmpty && notifier.errorMessage == null)
                      const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(child: Text('Belum ada user.')),
                      )
                    else
                      ...notifier.users.map(
                        (user) => _UserCard(
                          user: user,
                          onTap: () => _openUserForm(user: user),
                        ),
                      ),
                    const SizedBox(height: 80),
                  ],
                ),
        ),
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard({required this.user, required this.onTap});

  final AppUser user;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: user.isActive
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surfaceContainerHighest,
          child: Icon(
            user.role.isOwner
                ? Icons.admin_panel_settings_outlined
                : Icons.person_outline,
            color: user.isActive
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant,
          ),
        ),
        title: Text(
          user.displayName.isNotEmpty
              ? user.displayName
              : (user.username ?? '-'),
          style: TextStyle(
            fontWeight: FontWeight.w600,
            decoration: user.isActive ? null : TextDecoration.lineThrough,
          ),
        ),
        subtitle: Text(
          '@${user.username ?? '-'} · ${user.roleLabel} · ${user.statusLabel}',
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

class _UserFormSheet extends StatefulWidget {
  const _UserFormSheet({this.user});

  final AppUser? user;

  @override
  State<_UserFormSheet> createState() => _UserFormSheetState();
}

class _UserFormSheetState extends State<_UserFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _usernameController;
  late final TextEditingController _passwordController;
  late UserRole _role;
  late bool _isActive;
  bool _obscurePassword = true;

  bool get _isEditing => widget.user != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.user?.displayName ?? '',
    );
    _usernameController = TextEditingController(
      text: widget.user?.username ?? '',
    );
    _passwordController = TextEditingController();
    _role = widget.user?.role ?? UserRole.cashier;
    _isActive = widget.user?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final notifier = context.read<UserManagementNotifier>();
    notifier.clearMessages();

    final success = _isEditing
        ? await notifier.updateUser(
            userId: widget.user!.id,
            displayName: _nameController.text.trim(),
            role: _role,
            isActive: _isActive,
            password: _passwordController.text,
          )
        : await notifier.createUser(
            displayName: _nameController.text.trim(),
            username: _usernameController.text.trim(),
            password: _passwordController.text,
            role: _role,
          );

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop(true);
    } else if (notifier.errorMessage != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(notifier.errorMessage!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<UserManagementNotifier>();
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomInset),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _isEditing ? 'Edit User' : 'Tambah User Baru',
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nama Tampilan',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Nama wajib diisi';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _usernameController,
              enabled: !_isEditing,
              decoration: InputDecoration(
                labelText: 'Username',
                border: const OutlineInputBorder(),
                prefixText: '@',
                helperText: _isEditing ? 'Username tidak bisa diubah' : null,
              ),
              validator: (value) {
                if (_isEditing) return null;
                if (value == null || value.trim().isEmpty) {
                  return 'Username wajib diisi';
                }
                if (!isValidUsername(value)) {
                  return '3–32 karakter: huruf kecil, angka, underscore';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<UserRole>(
              initialValue: _role,
              decoration: const InputDecoration(
                labelText: 'Hak Akses',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: UserRole.cashier, child: Text('Kasir')),
                DropdownMenuItem(value: UserRole.owner, child: Text('Owner')),
              ],
              onChanged: notifier.isSaving
                  ? null
                  : (value) {
                      if (value != null) setState(() => _role = value);
                    },
            ),
            if (_isEditing) ...[
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Status Aktif'),
                subtitle: const Text('Nonaktif = tidak bisa login'),
                value: _isActive,
                onChanged: notifier.isSaving
                    ? null
                    : (value) => setState(() => _isActive = value),
              ),
            ],
            const SizedBox(height: 12),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: _isEditing ? 'Password Baru (opsional)' : 'Password',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  onPressed: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                ),
              ),
              validator: (value) {
                if (!_isEditing && (value == null || value.isEmpty)) {
                  return 'Password wajib diisi';
                }
                if (value != null && value.isNotEmpty && value.length < 6) {
                  return 'Password minimal 6 karakter';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: notifier.isSaving ? null : _submit,
              child: notifier.isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_isEditing ? 'Simpan Perubahan' : 'Tambah User'),
            ),
          ],
        ),
      ),
    );
  }
}
