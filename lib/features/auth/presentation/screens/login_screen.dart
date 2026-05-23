import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/di/service_locator.dart';
import '../../../shared/presentation/widgets/loading_state.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const String _demoEmail = 'demo@foodplease.app';
  static const String _demoPassword = 'demo123';

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _submitting = false;
  String? _errorText;
  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final MediaQueryData media = MediaQuery.of(context);
    final double horizontalPadding = media.size.width < 360 ? 16 : 24;
    final double innerPadding = media.size.width < 360 ? 16 : 24;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: 24,
              ),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(innerPadding),
                    child: AutofillGroup(
                      child: Form(
                        key: _formKey,
                        autovalidateMode: _autovalidateMode,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            Container(
                              width: 72,
                              height: 72,
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: const BoxDecoration(
                                color: Color(0xFF04838C),
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.restaurant,
                                color: Colors.white,
                                size: 36,
                              ),
                            ),
                            Semantics(
                              header: true,
                              child: Text(
                                'FoodPlease',
                                style: Theme.of(
                                  context,
                                ).textTheme.headlineMedium,
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Inicia sesion para ordenar comida',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 24),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1FBFB),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(0xFFB7E3E6),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    'Cuenta demo disponible',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleSmall,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Email: $_demoEmail\nContrasena: $_demoPassword',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                  const SizedBox(height: 8),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: TextButton.icon(
                                      onPressed: _submitting
                                          ? null
                                          : _fillDemoCredentials,
                                      icon: const Icon(Icons.flash_on_outlined),
                                      label: const Text('Usar cuenta demo'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              autocorrect: false,
                              autofillHints: const <String>[
                                AutofillHints.username,
                              ],
                              onTapOutside: (_) =>
                                  FocusScope.of(context).unfocus(),
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                prefixIcon: Icon(Icons.mail_outline),
                              ),
                              validator: (value) {
                                final String normalized = value?.trim() ?? '';
                                if (normalized.isEmpty) {
                                  return 'Ingresa tu email';
                                }
                                if (!_isValidEmail(normalized)) {
                                  return 'Email invalido';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: true,
                              textInputAction: TextInputAction.done,
                              autofillHints: const <String>[
                                AutofillHints.password,
                              ],
                              onTapOutside: (_) =>
                                  FocusScope.of(context).unfocus(),
                              onFieldSubmitted: (_) => _handleSubmit(context),
                              decoration: const InputDecoration(
                                labelText: 'Contrasena',
                                prefixIcon: Icon(Icons.lock_outline),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Ingresa tu contrasena';
                                }
                                return null;
                              },
                            ),
                            if (_errorText != null) ...<Widget>[
                              const SizedBox(height: 16),
                              Text(
                                _errorText!,
                                style: const TextStyle(color: Colors.red),
                              ),
                            ],
                            const SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: _submitting
                                  ? null
                                  : () => _handleSubmit(context),
                              child: _submitting
                                  ? const InlineLoader()
                                  : const Text('Iniciar sesion'),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Esta pantalla ya consume el backend Flask y mantiene la sesion localmente.',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleSubmit(BuildContext context) async {
    if (!_formKey.currentState!.validate()) {
      setState(() {
        _autovalidateMode = AutovalidateMode.onUserInteraction;
      });
      return;
    }

    setState(() {
      _submitting = true;
      _errorText = null;
    });

    final bool success = await AppServices.sessionController.signIn(
      email: _emailController.text,
      password: _passwordController.text,
    );

    if (!context.mounted) {
      return;
    }

    setState(() {
      _submitting = false;
      _errorText = success
          ? null
          : AppServices.sessionController.lastErrorMessage ??
                'No fue posible iniciar sesion';
    });

    if (success) {
      context.go(AppRoutes.menu);
    }
  }

  void _fillDemoCredentials() {
    setState(() {
      _emailController.text = _demoEmail;
      _passwordController.text = _demoPassword;
      _errorText = null;
      _autovalidateMode = AutovalidateMode.disabled;
    });
  }

  bool _isValidEmail(String value) {
    final RegExp emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    return emailPattern.hasMatch(value);
  }
}
