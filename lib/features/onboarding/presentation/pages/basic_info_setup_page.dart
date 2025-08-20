import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/models/user_model.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/custom_text_field.dart';

class BasicInfoSetupPage extends ConsumerStatefulWidget {
  final UserModel? initialData;
  final Function(Map<String, dynamic>) onCompleted;
  final VoidCallback? onSkipped;
  final VoidCallback? onBack;
  final bool allowSkip;

  const BasicInfoSetupPage({
    super.key,
    this.initialData,
    required this.onCompleted,
    this.onSkipped,
    this.onBack,
    this.allowSkip = true,
  });

  @override
  ConsumerState<BasicInfoSetupPage> createState() => _BasicInfoSetupPageState();
}

class _BasicInfoSetupPageState extends ConsumerState<BasicInfoSetupPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _bioController = TextEditingController();
  
  Gender? _selectedGender;
  bool _isLoading = false;

  final List<Gender> _genderOptions = [
    Gender.female,
    Gender.male,
    Gender.nonBinary,
    Gender.preferNotToSay,
  ];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _loadInitialData() {
    if (widget.initialData != null) {
      _nameController.text = widget.initialData!.name;
      // Calculate age from birthDate
      final age = DateTime.now().difference(widget.initialData!.birthDate).inDays ~/ 365;
      _ageController.text = age.toString();
      _bioController.text = widget.initialData!.bio ?? '';
      _selectedGender = widget.initialData!.gender;
    }
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    await Future.delayed(const Duration(milliseconds: 500)); // Simulate processing

    // Calculate birthDate from age
    final age = int.parse(_ageController.text.trim());
    final birthDate = DateTime.now().subtract(Duration(days: age * 365));

    final data = {
      'name': _nameController.text.trim(),
      'birthDate': birthDate,
      'bio': _bioController.text.trim(),
      'gender': _selectedGender,
    };

    widget.onCompleted(data);
  }

  Widget _buildNameField() {
    return CustomTextField(
      controller: _nameController,
      label: 'Full Name',
      hintText: 'Enter your full name',
      prefixIcon: Icons.person_outline,
      textCapitalization: TextCapitalization.words,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter your name';
        }
        if (value.trim().length < 2) {
          return 'Name must be at least 2 characters';
        }
        return null;
      },
    );
  }

  Widget _buildAgeField() {
    return CustomTextField(
      controller: _ageController,
      label: 'Age',
      hintText: 'Enter your age',
      prefixIcon: Icons.cake_outlined,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(2),
      ],
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter your age';
        }
        final age = int.tryParse(value.trim());
        if (age == null) {
          return 'Please enter a valid age';
        }
        if (age < 18) {
          return 'You must be at least 18 years old';
        }
        if (age > 100) {
          return 'Please enter a valid age';
        }
        return null;
      },
    );
  }

  Widget _buildGenderField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gender',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _genderOptions.map((gender) {
            final isSelected = _selectedGender == gender;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedGender = gender;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.primaryColor
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.primaryColor
                        : Colors.grey.shade300,
                  ),
                ),
                child: Text(
                  gender.displayName,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildBioField() {
    return CustomTextField(
      controller: _bioController,
      label: 'Bio (Optional)',
      hintText: 'Tell us about yourself...',
      prefixIcon: Icons.edit_outlined,
      maxLines: 4,
      maxLength: 500,
      textCapitalization: TextCapitalization.sentences,
      validator: (value) {
        if (value != null && value.length > 500) {
          return 'Bio must be less than 500 characters';
        }
        return null;
      },
    );
  }

  bool get _canProceed {
    return _nameController.text.trim().isNotEmpty &&
           _ageController.text.trim().isNotEmpty &&
           _selectedGender != null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.onBack != null)
                IconButton(
                  onPressed: widget.onBack,
                  icon: const Icon(Icons.arrow_back),
                  padding: EdgeInsets.zero,
                  alignment: Alignment.centerLeft,
                ).animate().fadeIn(),
              
              const SizedBox(height: 20),
              
              Text(
                'Tell us about yourself',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ).animate().fadeIn(delay: 100.ms),
              
              const SizedBox(height: 8),
              
              Text(
                'This information will be displayed on your profile.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ).animate().fadeIn(delay: 200.ms),
              
              const SizedBox(height: 32),
              
              Expanded(
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildNameField()
                            .animate(delay: 300.ms)
                            .fadeIn()
                            .slideX(begin: -0.2),
                        
                        const SizedBox(height: 20),
                        
                        _buildAgeField()
                            .animate(delay: 400.ms)
                            .fadeIn()
                            .slideX(begin: -0.2),
                        
                        const SizedBox(height: 24),
                        
                        _buildGenderField()
                            .animate(delay: 500.ms)
                            .fadeIn()
                            .slideX(begin: -0.2),
                        
                        const SizedBox(height: 24),
                        
                        _buildBioField()
                            .animate(delay: 600.ms)
                            .fadeIn()
                            .slideX(begin: -0.2),
                        
                        const SizedBox(height: 20),
                        
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Colors.blue.shade700,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Your information is secure and only visible to your matches.',
                                  style: TextStyle(
                                    color: Colors.blue.shade700,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ).animate(delay: 700.ms).fadeIn(),
                      ],
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              Row(
                children: [
                  if (widget.allowSkip && widget.onSkipped != null)
                    Expanded(
                      child: CustomButton(
                        text: 'Skip for now',
                        onPressed: widget.onSkipped,
                        variant: ButtonVariant.outlined,
                      ).animate().fadeIn(delay: 800.ms),
                    ),
                  if (widget.allowSkip && widget.onSkipped != null)
                    const SizedBox(width: 16),
                  Expanded(
                    flex: _canProceed ? 2 : 1,
                    child: CustomButton(
                      text: 'Continue',
                      onPressed: _canProceed ? _submit : null,
                      isLoading: _isLoading,
                      isEnabled: _canProceed,
                    ).animate().fadeIn(delay: 900.ms),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
