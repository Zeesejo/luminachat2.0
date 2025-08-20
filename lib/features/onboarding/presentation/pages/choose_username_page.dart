import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/services/user_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/analytics_service.dart';

class ChooseUsernamePage extends ConsumerStatefulWidget {
  const ChooseUsernamePage({super.key});

  @override
  ConsumerState<ChooseUsernamePage> createState() => _ChooseUsernamePageState();
}

class _ChooseUsernamePageState extends ConsumerState<ChooseUsernamePage> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();
  bool _checking = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String? _validate(String? v) {
    final value = (v ?? '').trim();
    if (value.isEmpty) return 'Enter a username';
    if (value.length < 3 || value.length > 20) return '3-20 characters';
    final ok = RegExp(r'^[a-z0-9_]+$').hasMatch(value);
    if (!ok) return 'Only lowercase letters, numbers and _';
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final username = _controller.text.trim();
    setState(() {
      _checking = true;
      _error = null;
    });
    try {
      final svc = ref.read(userServiceProvider);
      final taken = await svc.isUsernameTaken(username);
      if (taken) {
        setState(() => _error = 'Username is taken');
        return;
      }
      await svc.setMyUsername(username);
  await analyticsService.logSetUsername(username);
      if (!mounted) return;
      context.go(AppRoutes.personalityTest);
    } catch (e) {
      setState(() => _error = 'Failed: $e');
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Choose a username')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Pick a unique handle so friends can find you'),
              const SizedBox(height: 16),
              TextFormField(
                controller: _controller,
                decoration: InputDecoration(
                  labelText: 'Username',
                  prefixText: '@',
                  errorText: _error,
                ),
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: _validate,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _checking ? null : _submit,
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
                child: _checking ? const CircularProgressIndicator() : const Text('Continue'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
