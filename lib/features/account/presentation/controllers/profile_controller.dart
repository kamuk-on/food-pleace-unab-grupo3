import 'package:flutter/material.dart';

import '../../../../core/business/app_business_rules.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../auth/presentation/controllers/session_controller.dart';
import '../../domain/usecases/account_use_cases.dart';

class ProfileController extends ChangeNotifier {
  ProfileController({
    required this._getProfileUseCase,
    required this._updateProfileUseCase,
    required this._deleteAccountUseCase,
    required this._sessionController,
  });

  final GetProfileUseCase _getProfileUseCase;
  final UpdateProfileUseCase _updateProfileUseCase;
  final DeleteAccountUseCase _deleteAccountUseCase;
  final SessionController _sessionController;

  bool _loading = false;
  bool _saving = false;
  bool _deleting = false;
  bool _editing = false;
  String? _errorMessage;
  User? _profile;

  bool get loading => _loading;
  bool get saving => _saving;
  bool get deleting => _deleting;
  bool get editing => _editing;
  bool get busy => _saving || _deleting;
  String? get errorMessage => _errorMessage;
  User? get profile => _profile;

  Future<void> loadProfile() async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _profile = await _getProfileUseCase();
    } catch (_) {
      _errorMessage = 'No fue posible cargar la cuenta.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void enableEditing() {
    _editing = true;
    notifyListeners();
  }

  void cancelEditing() {
    _editing = false;
    notifyListeners();
  }

  Future<User> saveProfile({
    required String name,
    required String phone,
    required String address,
  }) async {
    if (!AppBusinessRules.hasRequiredText(name) ||
        !AppBusinessRules.hasRequiredText(phone) ||
        !AppBusinessRules.hasRequiredText(address)) {
      throw StateError('Todos los campos son requeridos.');
    }

    _saving = true;
    notifyListeners();

    try {
      final User updated = await _updateProfileUseCase(
        name: name.trim(),
        phone: phone.trim(),
        address: address.trim(),
      );
      _profile = updated;
      _editing = false;
      _sessionController.updateCurrentUser(updated);
      return updated;
    } finally {
      _saving = false;
      notifyListeners();
    }
  }

  Future<void> deleteAccount() async {
    _deleting = true;
    notifyListeners();

    try {
      await _deleteAccountUseCase();
      _profile = null;
      _editing = false;
      await _sessionController.signOut();
    } finally {
      _deleting = false;
      notifyListeners();
    }
  }

  void syncFromSession(User? user) {
    _profile = user;
    notifyListeners();
  }

  void reset() {
    _loading = false;
    _saving = false;
    _deleting = false;
    _editing = false;
    _errorMessage = null;
    _profile = null;
    notifyListeners();
  }
}
