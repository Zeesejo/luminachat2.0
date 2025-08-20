import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/constants.dart';
import '../../../../shared/widgets/custom_text_field.dart';

class ProfileSetupPage extends ConsumerStatefulWidget {
  const ProfileSetupPage({super.key});

  @override
  ConsumerState<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends ConsumerState<ProfileSetupPage> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  final int _totalSteps = 4;

  // Form controllers
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _ageController = TextEditingController();
  
  // Selected data
  // Intentionally mutable as user adds/removes interests across steps
  // ignore: prefer_final_fields
  List<String> _selectedInterests = [];
  String? _selectedGender;
  String? _selectedPersonalityType;

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _ageController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      setState(() => _currentStep++);
      _pageController.nextPage(
        duration: AppConstants.mediumAnimation,
        curve: Curves.easeInOut,
      );
    } else {
      _completeProfileSetup();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.previousPage(
        duration: AppConstants.mediumAnimation,
        curve: Curves.easeInOut,
      );
    }
  }

  void _completeProfileSetup() {
    // TODO: Save profile data to Firestore
    context.go(AppRoutes.mainNavigation);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Setup Profile'),
        backgroundColor: Colors.transparent,
        leading: _currentStep > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _previousStep,
              )
            : null,
      ),
      body: Column(
        children: [
          // Progress Indicator
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                LinearProgressIndicator(
                  value: (_currentStep + 1) / _totalSteps,
                  backgroundColor: Colors.grey.shade300,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                ),
                const SizedBox(height: 8),
                Text(
                  'Step ${_currentStep + 1} of $_totalSteps',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          
          // Content
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildBasicInfoStep(),
                _buildInterestsStep(),
                _buildPersonalityStep(),
                _buildPreferencesStep(),
              ],
            ),
          ),
          
          // Navigation Buttons
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                if (_currentStep > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _previousStep,
                      child: const Text('Previous'),
                    ),
                  ),
                
                if (_currentStep > 0) const SizedBox(width: 16),
                
                Expanded(
                  child: ElevatedButton(
                    onPressed: _nextStep,
                    child: Text(
                      _currentStep == _totalSteps - 1 ? 'Complete' : 'Next',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tell us about yourself',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ).animate().slideX(duration: 600.ms),
          
          const SizedBox(height: 8),
          
          Text(
            'This information will be used to create your profile',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.grey.shade600,
            ),
          ).animate(delay: 200.ms).slideX(duration: 600.ms),
          
          const SizedBox(height: 32),
          
          // Profile Photo Section
          Center(
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.grey.shade300,
                  child: Icon(
                    Icons.person,
                    size: 60,
                    color: Colors.grey.shade600,
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.camera_alt, color: Colors.white),
                      onPressed: () {
                        // TODO: Implement photo picker
                      },
                    ),
                  ),
                ),
              ],
            ),
          ).animate(delay: 400.ms).scale(duration: 600.ms),
          
          const SizedBox(height: 32),
          
          // Name Field
          CustomTextField(
            controller: _nameController,
            label: 'Full Name',
            hintText: 'Enter your full name',
            prefixIcon: Icons.person_outline,
          ).animate(delay: 600.ms).slideX(duration: 600.ms),
          
          const SizedBox(height: 20),
          
          // Age Field
          CustomTextField(
            controller: _ageController,
            label: 'Age',
            hintText: 'Enter your age',
            keyboardType: TextInputType.number,
            prefixIcon: Icons.cake_outlined,
          ).animate(delay: 800.ms).slideX(duration: 600.ms),
          
          const SizedBox(height: 20),
          
          // Gender Selection
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Gender',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                children: ['Male', 'Female', 'Other'].map((gender) {
                  return ChoiceChip(
                    label: Text(gender),
                    selected: _selectedGender == gender,
                    onSelected: (selected) {
                      setState(() {
                        _selectedGender = selected ? gender : null;
                      });
                    },
                    selectedColor: AppTheme.primaryColor,
                    labelStyle: TextStyle(
                      color: _selectedGender == gender ? Colors.white : null,
                    ),
                  );
                }).toList(),
              ),
            ],
          ).animate(delay: 1000.ms).slideX(duration: 600.ms),
          
          const SizedBox(height: 20),
          
          // Bio Field
          CustomTextField(
            controller: _bioController,
            label: 'Bio',
            hintText: 'Tell us about yourself...',
            maxLines: 4,
            maxLength: 500,
          ).animate(delay: 1200.ms).slideX(duration: 600.ms),
        ],
      ),
    );
  }

  Widget _buildInterestsStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What are your interests?',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ).animate().slideX(duration: 600.ms),
          
          const SizedBox(height: 8),
          
          Text(
            'Select at least 5 interests to help us find better matches',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.grey.shade600,
            ),
          ).animate(delay: 200.ms).slideX(duration: 600.ms),
          
          const SizedBox(height: 32),
          
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: AppConstants.interestCategories.map((interest) {
              final isSelected = _selectedInterests.contains(interest);
              return FilterChip(
                label: Text(interest),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedInterests.add(interest);
                    } else {
                      _selectedInterests.remove(interest);
                    }
                  });
                },
                selectedColor: AppTheme.primaryColor,
                checkmarkColor: Colors.white,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : null,
                ),
              );
            }).toList(),
          ).animate(delay: 400.ms).fadeIn(duration: 800.ms),
          
          const SizedBox(height: 20),
          
          if (_selectedInterests.isNotEmpty)
      Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_selectedInterests.length} interests selected',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ).animate().scale(duration: 400.ms),
        ],
      ),
    );
  }

  Widget _buildPersonalityStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Personality Type',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ).animate().slideX(duration: 600.ms),
          
          const SizedBox(height: 8),
          
          Text(
            'We\'ll use this to find compatible matches',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.grey.shade600,
            ),
          ).animate(delay: 200.ms).slideX(duration: 600.ms),
          
          const SizedBox(height: 32),
          
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1,
            ),
            itemCount: AppConstants.mbtiTypes.length,
            itemBuilder: (context, index) {
              final type = AppConstants.mbtiTypes[index];
              final isSelected = _selectedPersonalityType == type;
              
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedPersonalityType = type;
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.primaryColor : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
                      width: 2,
                    ),
                    boxShadow: [
                      if (isSelected)
                        BoxShadow(
                          color: AppTheme.primaryColor.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      type,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ).animate(delay: (index * 50).ms).scale(duration: 400.ms);
            },
          ),
          
          if (_selectedPersonalityType != null) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(
                    _selectedPersonalityType!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getPersonalityDescription(_selectedPersonalityType!),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ).animate().scale(duration: 400.ms),
          ],
        ],
      ),
    );
  }

  Widget _buildPreferencesStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Almost done!',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ).animate().slideX(duration: 600.ms),
          
          const SizedBox(height: 8),
          
          Text(
            'Set your matching preferences',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.grey.shade600,
            ),
          ).animate(delay: 200.ms).slideX(duration: 600.ms),
          
          const SizedBox(height: 32),
          
          // Age Range Preference
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Age Range',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  RangeSlider(
                    values: const RangeValues(18, 35),
                    min: 18,
                    max: 99,
                    divisions: 81,
                    activeColor: AppTheme.primaryColor,
                    labels: const RangeLabels('18', '35'),
                    onChanged: (values) {
                      // TODO: Update age range preference
                    },
                  ),
                ],
              ),
            ),
          ).animate(delay: 400.ms).slideY(duration: 600.ms),
          
          const SizedBox(height: 16),
          
          // Distance Range Preference
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Maximum Distance',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Slider(
                    value: 25,
                    min: 1,
                    max: 100,
                    divisions: 99,
                    activeColor: AppTheme.primaryColor,
                    label: '25 km',
                    onChanged: (value) {
                      // TODO: Update distance preference
                    },
                  ),
                ],
              ),
            ),
          ).animate(delay: 600.ms).slideY(duration: 600.ms),
          
          const SizedBox(height: 32),
          
          // Success Message
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.celebration,
                  color: Colors.white,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  'Your profile is ready!',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'You can start discovering amazing people and building meaningful connections.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ).animate(delay: 800.ms).scale(duration: 600.ms),
        ],
      ),
    );
  }

  String _getPersonalityDescription(String type) {
    final descriptions = {
      'INTJ': 'The Architect - Independent and strategic thinkers',
      'INTP': 'The Logician - Innovative inventors with thirst for knowledge',
      'ENTJ': 'The Commander - Bold, imaginative and strong-willed leaders',
      'ENTP': 'The Debater - Smart and curious thinkers who love challenges',
      'INFJ': 'The Advocate - Creative and insightful, inspired idealists',
      'INFP': 'The Mediator - Poetic, kind and altruistic people',
      'ENFJ': 'The Protagonist - Charismatic and inspiring leaders',
      'ENFP': 'The Campaigner - Enthusiastic, creative and sociable',
      'ISTJ': 'The Logistician - Practical and fact-minded, reliable',
      'ISFJ': 'The Protector - Warm-hearted and dedicated, always ready to protect',
      'ESTJ': 'The Executive - Excellent administrators, unsurpassed at managing',
      'ESFJ': 'The Consul - Extraordinarily caring, social and popular people',
      'ISTP': 'The Virtuoso - Bold and practical experimenters',
      'ISFP': 'The Adventurer - Flexible and charming artists',
      'ESTP': 'The Entrepreneur - Smart, energetic and perceptive people',
      'ESFP': 'The Entertainer - Spontaneous, energetic and enthusiastic people',
    };
    return descriptions[type] ?? 'A unique personality type';
  }
}
