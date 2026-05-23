import 'package:flutter/material.dart';

import '../../../../core/business/app_business_rules.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/network/api_exception.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../shared/presentation/widgets/app_feedback.dart';
import '../../../shared/presentation/widgets/error_state_card.dart';
import '../../../shared/presentation/widgets/loading_state.dart';
import '../../../shared/presentation/widgets/section_scaffold.dart';
import '../controllers/profile_controller.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  ProfileController get _controller => AppServices.profileController;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return SectionScaffold(
          title: 'Mi cuenta',
          child: _buildContent(context),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_controller.loading) {
      return const LoadingState(message: 'Cargando perfil...');
    }

    if (_controller.errorMessage != null) {
      return ErrorStateCard(
        message: _controller.errorMessage!,
        onRetry: _loadProfile,
      );
    }

    final User? profile = _controller.profile;
    if (profile == null) {
      return ErrorStateCard(
        title: 'Perfil no disponible',
        message: 'No fue posible recuperar la informacion de tu cuenta.',
        onRetry: _loadProfile,
      );
    }

    final bool busy = _controller.busy;
    final String displayName = _displayName(profile);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: <Widget>[
                CircleAvatar(
                  radius: 34,
                  child: Text(
                    displayName.characters.first.toUpperCase(),
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  displayName,
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(profile.email, textAlign: TextAlign.center),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _controller.editing
                        ? Theme.of(context).colorScheme.primaryContainer
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    _controller.editing ? 'Modo edicion' : 'Modo lectura',
                    style: TextStyle(
                      color: _controller.editing
                          ? Theme.of(context).colorScheme.onPrimaryContainer
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: AutofillGroup(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Text(
                      'Datos del perfil',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      enabled: _controller.editing && !busy,
                      textInputAction: TextInputAction.next,
                      autofillHints: const <String>[AutofillHints.name],
                      onTapOutside: (_) => FocusScope.of(context).unfocus(),
                      decoration: const InputDecoration(
                        labelText: 'Nombre',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: _requiredField,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      initialValue: profile.email,
                      enabled: false,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.alternate_email),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phoneController,
                      enabled: _controller.editing && !busy,
                      textInputAction: TextInputAction.next,
                      keyboardType: TextInputType.phone,
                      autofillHints: const <String>[
                        AutofillHints.telephoneNumber,
                      ],
                      onTapOutside: (_) => FocusScope.of(context).unfocus(),
                      decoration: const InputDecoration(
                        labelText: 'Telefono',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                      validator: _requiredField,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _addressController,
                      enabled: _controller.editing && !busy,
                      textInputAction: TextInputAction.done,
                      keyboardType: TextInputType.streetAddress,
                      minLines: 2,
                      maxLines: 3,
                      autofillHints: const <String>[
                        AutofillHints.fullStreetAddress,
                      ],
                      onTapOutside: (_) => FocusScope.of(context).unfocus(),
                      decoration: const InputDecoration(
                        labelText: 'Direccion',
                        prefixIcon: Icon(Icons.location_on_outlined),
                      ),
                      validator: _requiredField,
                    ),
                    const SizedBox(height: 20),
                    if (_controller.editing) ...<Widget>[
                      ElevatedButton(
                        onPressed: busy ? null : _saveProfile,
                        child: _controller.saving
                            ? const InlineLoader()
                            : const Text('Guardar cambios'),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: busy ? null : _cancelEditing,
                        child: const Text('Cancelar edicion'),
                      ),
                    ] else
                      ElevatedButton.icon(
                        onPressed: busy ? null : _enableEditing,
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Editar perfil'),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  'Sesion y seguridad',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: busy ? null : _signOut,
                  child: const Text('Cerrar sesion'),
                ),
                const SizedBox(height: 12),
                FilledButton.tonal(
                  onPressed: busy ? null : _confirmDeleteAccount,
                  style: FilledButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                  ),
                  child: _controller.deleting
                      ? const InlineLoader()
                      : const Text('Eliminar cuenta'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _loadProfile() async {
    await _controller.loadProfile();
    final User? profile = _controller.profile;
    if (profile != null) {
      _fillForm(profile);
    }
  }

  void _enableEditing() {
    _controller.enableEditing();
  }

  void _cancelEditing() {
    final User? profile = _controller.profile;
    if (profile != null) {
      _fillForm(profile);
    }
    _controller.cancelEditing();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      await _controller.saveProfile(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
      );

      if (!mounted) {
        return;
      }

      AppFeedback.showSuccess(context, 'Perfil actualizado correctamente.');
    } on StateError catch (error) {
      if (!mounted) {
        return;
      }
      AppFeedback.showError(context, error.message);
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      AppFeedback.showError(context, error.message);
    } catch (_) {
      if (!mounted) {
        return;
      }
      AppFeedback.showError(context, 'No fue posible guardar los cambios.');
    }
  }

  Future<void> _signOut() async {
    await AppServices.sessionController.signOut();
  }

  Future<void> _confirmDeleteAccount() async {
    final bool confirmed = await AppFeedback.confirmDestructiveAction(
      context,
      title: 'Eliminar cuenta',
      message:
          'Esta accion eliminara tu cuenta y cerrara tu sesion. ¿Deseas continuar?',
      confirmLabel: 'Eliminar cuenta',
    );

    if (!confirmed) {
      return;
    }

    try {
      await _controller.deleteAccount();

      if (!mounted) {
        return;
      }

      AppFeedback.showSuccess(context, 'Cuenta eliminada correctamente.');
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      AppFeedback.showError(context, error.message);
    } catch (_) {
      if (!mounted) {
        return;
      }
      AppFeedback.showError(context, 'No fue posible eliminar la cuenta.');
    }
  }

  void _fillForm(User profile) {
    _nameController.text = profile.name?.trim().isNotEmpty == true
        ? profile.name!.trim()
        : '';
    _phoneController.text = profile.phone?.trim().isNotEmpty == true
        ? profile.phone!.trim()
        : '';
    _addressController.text = profile.address?.trim().isNotEmpty == true
        ? profile.address!.trim()
        : '';
  }

  String _displayName(User profile) {
    final String? name = profile.name?.trim();
    if (name != null && name.isNotEmpty) {
      return name;
    }
    return 'Cliente FoodPlease';
  }

  String? _requiredField(String? value) {
    if (!_controller.editing) {
      return null;
    }

    if (value == null || !AppBusinessRules.hasRequiredText(value)) {
      return 'Este campo es requerido';
    }

    return null;
  }
}
