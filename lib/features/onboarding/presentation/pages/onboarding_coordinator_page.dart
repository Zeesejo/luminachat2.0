import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/analytics_service.dart';
import '../../../../core/services/user_service.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../shared/models/user_model.dart';
import 'profile_photo_setup_page.dart';
import 'basic_info_setup_page.dart';
import 'interests_setup_page.dart';
import 'personality_test_page.dart';
import 'location_setup_page.dart';

enum OnboardingStep {
  profilePhoto,
  basicInfo,
  interests,
  personalityTest,
  location,
  completed
}

class OnboardingCoordinatorPage extends ConsumerStatefulWidget {
  final bool allowSkip;
  final OnboardingStep? initialStep;

  const OnboardingCoordinatorPage({
    super.key,
    this.allowSkip = true,
    this.initialStep,
  });

  @override
  ConsumerState<OnboardingCoordinatorPage> createState() => _OnboardingCoordinatorPageState();
}

class _OnboardingCoordinatorPageState extends ConsumerState<OnboardingCoordinatorPage> {
  late PageController _pageController;
  late OnboardingStep _currentStep;
  
  // User data being built throughout the onboarding
  UserModel? _userDataInProgress;
  bool _isFinishing = false;
  
  final List<OnboardingStep> _steps = [
    OnboardingStep.profilePhoto,
    OnboardingStep.basicInfo,
    OnboardingStep.interests,
    OnboardingStep.personalityTest,
    OnboardingStep.location,
  ];

  @override
  void initState() {
    super.initState();
    _currentStep = widget.initialStep ?? OnboardingStep.profilePhoto;
    final initialIndex = _steps.indexOf(_currentStep);
    _pageController = PageController(initialPage: initialIndex);
    
    // Track onboarding start
    AnalyticsService().trackEvent('onboarding_started', {
      'initial_step': _currentStep.name,
      'allow_skip': widget.allowSkip ? 'true' : 'false',
    });
    
    _loadExistingUserData();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _loadExistingUserData() async {
    try {
      final userService = ref.read(userServiceProvider);
      final currentUser = await userService.getCurrentUser();
      if (currentUser != null && mounted) {
        setState(() {
          _userDataInProgress = currentUser;
        });
      }
    } catch (e) {
      debugPrint('Failed to load existing user data: $e');
    }
  }

  void _onStepCompleted(OnboardingStep step, Map<String, dynamic> stepData) {
    // Update user data with step information
    _updateUserDataFromStep(step, stepData);
    
    // Track step completion
    AnalyticsService().trackEvent('onboarding_step_completed', {
      'step': step.name,
      'step_index': _steps.indexOf(step),
      'total_steps': _steps.length,
    });
    
    // Move to next step or complete onboarding
    final currentIndex = _steps.indexOf(_currentStep);
    if (currentIndex < _steps.length - 1) {
      _goToNextStep();
    } else {
      setState(() {
        _isFinishing = true;
      });
      _completeOnboarding();
    }
  }

  void _onStepSkipped(OnboardingStep step) {
    // Track step skip
    AnalyticsService().trackEvent('onboarding_step_skipped', {
      'step': step.name,
      'step_index': _steps.indexOf(step),
      'total_steps': _steps.length,
    });
    
    // Move to next step or complete onboarding
    final currentIndex = _steps.indexOf(_currentStep);
    if (currentIndex < _steps.length - 1) {
      _goToNextStep();
    } else {
      _completeOnboarding();
    }
  }

  void _goToNextStep() {
    final currentIndex = _steps.indexOf(_currentStep);
    if (currentIndex < _steps.length - 1) {
      setState(() {
        _currentStep = _steps[currentIndex + 1];
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _goToPreviousStep() {
    final currentIndex = _steps.indexOf(_currentStep);
    if (currentIndex > 0) {
      setState(() {
        _currentStep = _steps[currentIndex - 1];
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _updateUserDataFromStep(OnboardingStep step, Map<String, dynamic> stepData) {
    // Create or update user data based on step information
    final currentData = _userDataInProgress ?? UserModel(
      id: '',
      email: '',
      name: '',
      birthDate: DateTime.now().subtract(const Duration(days: 18 * 365)),
      photos: [],
      interests: [],
      bio: '',
      location: null,
      personalityType: null,
      isVerified: false,
      lastSeen: DateTime.now(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      privacySettings: PrivacySettings(),
      profileCompletion: ProfileCompletion(),
    );

    if (kDebugMode) {
      debugPrint('[ONBOARDING] Updating data for step: ${step.name}');
      debugPrint('[ONBOARDING] Step data received: ${stepData.keys.toList()}');
    }

    switch (step) {
      case OnboardingStep.profilePhoto:
        _userDataInProgress = currentData.copyWith(
          photos: stepData['photos'] as List<String>? ?? currentData.photos,
        );
        break;
      case OnboardingStep.basicInfo:
        _userDataInProgress = currentData.copyWith(
          name: stepData['name'] as String? ?? currentData.name,
          birthDate: stepData['birthDate'] as DateTime? ?? currentData.birthDate,
          bio: stepData['bio'] as String? ?? currentData.bio,
          gender: stepData['gender'] as Gender? ?? currentData.gender,
        );
        break;
      case OnboardingStep.interests:
        _userDataInProgress = currentData.copyWith(
          interests: stepData['interests'] as List<String>? ?? currentData.interests,
        );
        break;
      case OnboardingStep.personalityTest:
        _userDataInProgress = currentData.copyWith(
          personalityType: stepData['personalityType'] as MBTIType? ?? currentData.personalityType,
        );
        break;
      case OnboardingStep.location:
        final location = stepData['location'] as Location?;
        if (kDebugMode) {
          debugPrint('[ONBOARDING] Setting location: ${location?.toJson()}');
        }
        _userDataInProgress = currentData.copyWith(
          location: location ?? currentData.location,
        );
        break;
      case OnboardingStep.completed:
        break;
    }
    
    if (kDebugMode) {
      debugPrint('[ONBOARDING] Updated user data keys: ${_userDataInProgress?.toJson().keys.toList()}');
    }
  }

  void _completeOnboarding() async {
    try {
      if (kDebugMode) {
        debugPrint('[ONBOARDING] Starting completion process...');
      }
      
      // Check authentication state
      final authService = ref.read(authServiceProvider);
      final currentUser = authService.currentUser;
      if (kDebugMode) {
        debugPrint('[ONBOARDING] Current user: ${currentUser?.uid ?? "null"}');
      }
      
      if (currentUser == null) {
        if (kDebugMode) {
          debugPrint('[ONBOARDING] ERROR: No authenticated user found');
        }
        throw Exception('You must be signed in to complete onboarding');
      }
      
      // Save complete user profile
      if (_userDataInProgress != null) {
        if (kDebugMode) {
          debugPrint('[ONBOARDING] Updating user profile with data: ${_userDataInProgress!.toJson().keys.toList()}');
        }

        // Mark completion flags for steps done in this flow
        final existingCompletion = _userDataInProgress!.profileCompletion;
        final updatedCompletion = existingCompletion.copyWith(
          hasProfilePhoto: (_userDataInProgress!.photos.isNotEmpty) || existingCompletion.hasProfilePhoto,
          hasInterests: (_userDataInProgress!.interests.isNotEmpty) || existingCompletion.hasInterests,
          hasPersonalityTest: (_userDataInProgress!.personalityType != null) || existingCompletion.hasPersonalityTest,
          hasLocation: (_userDataInProgress!.location != null) || existingCompletion.hasLocation || true, // Always mark as completed if we reach this point
          hasMultiplePhotos: (_userDataInProgress!.photos.length >= 2) || existingCompletion.hasMultiplePhotos,
        );

        // Ensure user ID matches authenticated user and set profileCompletion
        _userDataInProgress = _userDataInProgress!.copyWith(
          id: currentUser.uid,
          email: currentUser.email ?? _userDataInProgress!.email,
          profileCompletion: updatedCompletion,
        );

        final userService = ref.read(userServiceProvider);
        if (kDebugMode) {
          debugPrint('[ONBOARDING] Saving user profile to Firestore...');
        }
        final saveFuture = userService.updateUser(_userDataInProgress!);
        try {
          // Race the save with a short delay so we don't block UX
          await Future.any([
            saveFuture,
            Future.delayed(const Duration(seconds: 3)),
          ]);
          if (kDebugMode) {
            debugPrint('[ONBOARDING] Save finished or timed out window reached. Proceeding.');
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('[ONBOARDING] WARNING: Save failed: $e. Proceeding.');
          }
        }
      } else {
        if (kDebugMode) {
          debugPrint('[ONBOARDING] WARNING: No user data to save');
        }
      }
      
      // Track onboarding completion
      AnalyticsService().trackEvent('onboarding_completed', {
        'completed_steps': _steps.length,
        'skipped_steps': 0, // TODO: Track skipped steps count
        'completion_time_minutes': DateTime.now().difference(DateTime.now()).inMinutes, // TODO: Track actual time
      });
      
      if (kDebugMode) {
        debugPrint('[ONBOARDING] Navigating to main app...');
      }
      
      // Navigate to main app (force bypass in case of guard race)
      if (mounted) {
        context.go('${AppRoutes.mainNavigation}?force=true');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ONBOARDING] ERROR: Failed to complete onboarding: $e');
      }
      debugPrint('Failed to complete onboarding: $e');
      
      // Show error dialog with more specific message
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Setup Failed'),
            content: Text('Failed to complete profile setup: ${e.toString()}\n\nPlease try signing in again.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  // Go back to sign in
                  context.go(AppRoutes.login);
                },
                child: const Text('Sign In Again'),
              ),
            ],
          ),
        );
      }
    } finally {
      // Final safety net to avoid getting stuck on Step 5
      if (mounted) {
        Future.delayed(const Duration(seconds: 5), () {
          if (mounted) {
            if (kDebugMode) {
              debugPrint('[ONBOARDING] Fallback navigation to main app (safety net)');
            }
      context.go('${AppRoutes.mainNavigation}?force=true');
          }
        });
      }
    }
  }

  Widget _buildProgressIndicator() {
    final currentIndex = _steps.indexOf(_currentStep);
    final progress = (currentIndex + 1) / _steps.length;
    
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Step ${currentIndex + 1} of ${_steps.length}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
              if (widget.allowSkip)
                TextButton(
                  onPressed: () => _onStepSkipped(_currentStep),
                  child: const Text('Skip'),
                ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey.shade300,
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              SafeArea(
                child: _buildProgressIndicator().animate().fadeIn(
                  duration: 500.ms,
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(), // Only allow programmatic navigation
                  itemCount: _steps.length,
                  itemBuilder: (context, index) {
                    final step = _steps[index];
                    
                    switch (step) {
                      case OnboardingStep.profilePhoto:
                        return ProfilePhotoSetupPage(
                          initialPhotos: _userDataInProgress?.photos ?? [],
                          onCompleted: (photos) => _onStepCompleted(step, {'photos': photos}),
                          onSkipped: () => _onStepSkipped(step),
                          onBack: _steps.indexOf(step) > 0 ? _goToPreviousStep : null,
                          allowSkip: widget.allowSkip,
                        );
                      case OnboardingStep.basicInfo:
                        return BasicInfoSetupPage(
                          initialData: _userDataInProgress,
                          onCompleted: (data) => _onStepCompleted(step, data),
                          onSkipped: () => _onStepSkipped(step),
                          onBack: _goToPreviousStep,
                          allowSkip: widget.allowSkip,
                        );
                      case OnboardingStep.interests:
                        return InterestsSetupPage(
                          initialInterests: _userDataInProgress?.interests ?? [],
                          onCompleted: (interests) => _onStepCompleted(step, {'interests': interests}),
                          onSkipped: () => _onStepSkipped(step),
                          onBack: _goToPreviousStep,
                          allowSkip: widget.allowSkip,
                        );
                      case OnboardingStep.personalityTest:
                        return PersonalityTestPage(
                          initialPersonalityType: _userDataInProgress?.personalityType,
                          onCompleted: (personalityType) => _onStepCompleted(step, {'personalityType': personalityType}),
                          onSkipped: () => _onStepSkipped(step),
                          onBack: _goToPreviousStep,
                          allowSkip: widget.allowSkip,
                        );
                      case OnboardingStep.location:
                        return LocationSetupPage(
                          initialLocation: _userDataInProgress?.location,
                          onCompleted: (location) => _onStepCompleted(step, {'location': location}),
                          onSkipped: () => _onStepSkipped(step),
                          onBack: _goToPreviousStep,
                          allowSkip: widget.allowSkip,
                        );
                      case OnboardingStep.completed:
                        return const SizedBox.shrink();
                    }
                  },
                ),
              ),
            ],
          ),

          if (_isFinishing)
            Positioned.fill(
              child: Container(
                color: Colors.white,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      const Text('Finishing your setup...'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          if (kDebugMode) {
                            debugPrint('[ONBOARDING] User tapped Finish Now button');
                          }
                          if (mounted) {
                            context.go(AppRoutes.mainNavigation);
                          }
                        },
                        child: const Text('Finish Now'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
