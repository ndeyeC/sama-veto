import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../models/register_options.dart';
import '../services/api_service.dart';
import '../utils/phone_utils.dart';
import '../widgets/auth_layout.dart';

/// Inscription en 3 écrans : infos personnelles, profil (définitif), mot de passe.
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  static const _titles = [
    'Créer votre compte',
    'Votre profil',
    'Choisissez un mot de passe',
  ];
  static const _subtitles = [
    'Étape 1 sur 3 — Vos informations',
    'Étape 2 sur 3 — Votre rôle sur Sama Veto',
    'Étape 3 sur 3 — Sécurisez votre compte',
  ];

  final _infoKey = GlobalKey<FormState>();
  final _passKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _api = ApiService();

  RegisterOptions? _options;
  String? _loadError;

  int _step = 0;
  String? _region;
  String? _role;
  String? _roleError;

  bool _loading = false;
  bool _obscurePassword = true;
  String? _error;
  Map<String, String> _serverErrors = {};

  @override
  void initState() {
    super.initState();
    _loadOptions();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _loadOptions() async {
    setState(() => _loadError = null);
    try {
      final options = await _api.getRegisterOptions();
      if (!mounted) return;
      setState(() => _options = options);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _loadError = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadError = 'Impossible de charger le formulaire.');
    }
  }

  // --- Validations -----------------------------------------------------------

  String? _validateName(String? value) {
    final name = value?.trim() ?? '';
    if (name.isEmpty) return 'Veuillez saisir votre prénom et nom.';
    if (name.length < 2) return 'Le nom doit contenir au moins 2 caractères.';
    return _serverErrors['name'];
  }

  String? _validatePhone(String? value) {
    final phone = value?.trim() ?? '';
    if (phone.isEmpty) return 'Veuillez saisir votre numéro de téléphone.';
    if (!isValidPhone(phone)) {
      return 'Numéro invalide. Format attendu : +221 77 123 45 67.';
    }
    return _serverErrors['phone'];
  }

  String? _validateRegion(String? value) {
    if (value == null) return 'Veuillez choisir votre région.';
    return _serverErrors['region'];
  }

  String? _validatePassword(String? value) {
    final password = value ?? '';
    if (password.isEmpty) return 'Veuillez choisir un mot de passe.';
    if (password.length < 6) {
      return 'Le mot de passe doit contenir au moins 6 caractères.';
    }
    return _serverErrors['password'];
  }

  String? _validateConfirm(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez confirmer votre mot de passe.';
    }
    if (value != _passwordController.text) {
      return 'Les mots de passe ne correspondent pas.';
    }
    return null;
  }

  void _clearErrors() {
    if (_error != null || _serverErrors.isNotEmpty) {
      setState(() {
        _error = null;
        _serverErrors = {};
      });
    }
  }

  // --- Navigation entre les étapes -------------------------------------------

  void _nextFromInfo() {
    FocusScope.of(context).unfocus();
    if (_infoKey.currentState!.validate()) setState(() => _step = 1);
  }

  void _confirmRole() {
    if (_role == null) {
      setState(() => _roleError = 'Veuillez choisir un profil pour continuer.');
      return;
    }
    setState(() {
      _roleError = null;
      _step = 2;
    });
  }

  void _back() => setState(() => _step = _step - 1);

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _error = null;
      _serverErrors = {};
    });

    if (!_passKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final user = await _api.register(
        name: _nameController.text.trim(),
        phone: normalizePhone(_phoneController.text),
        region: _region!,
        role: _role!,
        password: _passwordController.text,
        passwordConfirmation: _confirmController.text,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Compte créé. Bienvenue ${user['name']} !')),
      );
      Navigator.of(context).pushNamedAndRemoveUntil('/espace', (route) => false);
    } on ApiException catch (e) {
      if (!mounted) return;
      final errors = e.fieldErrors;

      // On ramène l'utilisateur sur l'étape qui contient l'erreur
      // (ex. numéro déjà utilisé -> étape 1).
      var target = _step;
      if (errors.keys.any((k) => k == 'name' || k == 'phone' || k == 'region')) {
        target = 0;
      } else if (errors.containsKey('role')) {
        target = 1;
      }

      setState(() {
        _loading = false;
        _serverErrors = errors;
        _error = errors.isEmpty ? e.message : null;
        _roleError = errors['role'];
        _step = target;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _infoKey.currentState?.validate();
        _passKey.currentState?.validate();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Une erreur inattendue est survenue. Veuillez réessayer.';
      });
    }
  }

  // --- Affichage -------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final options = _options;

    if (options == null) {
      return AuthLayout(
        title: _titles[0],
        subtitle: 'Rejoignez Sama Veto en quelques instants.',
        child: _loadError == null
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AuthErrorBanner(message: _loadError!),
                  OutlinedButton(
                    onPressed: _loadOptions,
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
      );
    }

    return AuthLayout(
      title: _titles[_step],
      subtitle: _subtitles[_step],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: (_step + 1) / 3,
              minHeight: 6,
              color: AppColors.green,
              backgroundColor: AppColors.lightGreen,
            ),
          ),
          const SizedBox(height: 20),
          if (_step == 0) _buildInfoStep(options),
          if (_step == 1) _buildRoleStep(options),
          if (_step == 2) _buildPasswordStep(),
        ],
      ),
    );
  }

  Widget _buildInfoStep(RegisterOptions options) {
    return Form(
      key: _infoKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.name],
            decoration: authInputDecoration(
              label: 'Prénom & Nom',
              icon: Icons.person_outline,
            ),
            validator: _validateName,
            onChanged: (_) => _clearErrors(),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.telephoneNumber],
            decoration: authInputDecoration(
              label: 'Numéro de téléphone',
              hint: '+221 77 123 45 67',
              icon: Icons.phone_outlined,
            ),
            validator: _validatePhone,
            onChanged: (_) => _clearErrors(),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            // ignore: deprecated_member_use
            value: _region,
            isExpanded: true,
            decoration: authInputDecoration(
              label: 'Région',
              icon: Icons.location_on_outlined,
            ),
            items: options.regions
                .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                .toList(),
            validator: _validateRegion,
            onChanged: (value) {
              setState(() => _region = value);
              _clearErrors();
            },
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _nextFromInfo,
            child: const Text('Continuer →'),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Déjà un compte ?',
                style: TextStyle(color: AppColors.mutedText),
              ),
              TextButton(
                onPressed: () =>
                    Navigator.of(context).pushReplacementNamed('/login'),
                child: const Text('Se connecter'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRoleStep(RegisterOptions options) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange.shade300),
          ),
          child: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange.shade800),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Ce choix est DÉFINITIF',
                  style: TextStyle(
                    color: Colors.orange.shade900,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        for (final option in options.roles) ...[
          _RoleCard(
            option: option,
            selected: _role == option.key,
            onTap: () => setState(() {
              _role = option.key;
              _roleError = null;
            }),
          ),
          const SizedBox(height: 10),
        ],
        if (_roleError != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              _roleError!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        const SizedBox(height: 8),
        FilledButton(onPressed: _confirmRole, child: const Text('Confirmer →')),
        const SizedBox(height: 8),
        TextButton(onPressed: _back, child: const Text('← Retour')),
      ],
    );
  }

  Widget _buildPasswordStep() {
    return Form(
      key: _passKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_error != null) AuthErrorBanner(message: _error!),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.newPassword],
              decoration: authInputDecoration(
                label: 'Mot de passe',
                hint: '6 caractères minimum',
                icon: Icons.lock_outline,
                suffix: IconButton(
                  tooltip: _obscurePassword
                      ? 'Afficher les mots de passe'
                      : 'Masquer les mots de passe',
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              validator: _validatePassword,
              onChanged: (_) => _clearErrors(),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _confirmController,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.newPassword],
              decoration: authInputDecoration(
                label: 'Confirmer le mot de passe',
                icon: Icons.lock_outline,
              ),
              validator: _validateConfirm,
              onChanged: (_) => _clearErrors(),
              onFieldSubmitted: (_) => _loading ? null : _submit(),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.white,
                      ),
                    )
                  : const Text('Créer mon compte →'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _loading ? null : _back,
              child: const Text('← Retour'),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final RoleOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? AppColors.lightGreen : AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.green : AppColors.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(option.emoji, style: const TextStyle(fontSize: 30)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.label,
                    style: const TextStyle(
                      color: AppColors.darkGreen,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    option.description,
                    style: const TextStyle(
                      color: AppColors.mutedText,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle, color: AppColors.green),
          ],
        ),
      ),
    );
  }
}
