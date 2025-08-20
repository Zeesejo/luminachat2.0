import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/custom_button.dart';

class InterestsSetupPage extends ConsumerStatefulWidget {
  final List<String> initialInterests;
  final Function(List<String>) onCompleted;
  final VoidCallback? onSkipped;
  final VoidCallback? onBack;
  final bool allowSkip;

  const InterestsSetupPage({
    super.key,
    required this.initialInterests,
    required this.onCompleted,
    this.onSkipped,
    this.onBack,
    this.allowSkip = true,
  });

  @override
  ConsumerState<InterestsSetupPage> createState() => _InterestsSetupPageState();
}

class _InterestsSetupPageState extends ConsumerState<InterestsSetupPage> {
  late Set<String> _selectedInterests;
  bool _isLoading = false;
  final int _minInterests = 3;
  final int _maxInterests = 10;

  final Map<String, List<String>> _interestCategories = {
    'Sports & Fitness': [
      'Running', 'Gym', 'Yoga', 'Swimming', 'Basketball', 'Football',
      'Tennis', 'Golf', 'Hiking', 'Rock Climbing', 'Cycling', 'Boxing',
      'Dance', 'Pilates', 'CrossFit', 'Martial Arts'
    ],
    'Arts & Culture': [
      'Photography', 'Painting', 'Music', 'Theater', 'Museums', 'Concerts',
      'Drawing', 'Writing', 'Poetry', 'Sculpture', 'Film', 'Literature',
      'Opera', 'Art Galleries', 'Design', 'Architecture'
    ],
    'Food & Drink': [
      'Cooking', 'Wine Tasting', 'Coffee', 'Craft Beer', 'Fine Dining',
      'Vegan Food', 'Baking', 'BBQ', 'Street Food', 'Cocktails',
      'Food Trucks', 'Farmers Markets', 'Cheese', 'Chocolate'
    ],
    'Travel & Adventure': [
      'Travel', 'Backpacking', 'Camping', 'Road Trips', 'Beach',
      'Mountains', 'City Breaks', 'Adventure Sports', 'Skiing',
      'Surfing', 'Scuba Diving', 'Safari', 'Cruises', 'Solo Travel'
    ],
    'Technology': [
      'Programming', 'Gaming', 'AI', 'Cryptocurrency', 'Gadgets',
      'Robotics', 'Virtual Reality', 'Web Development', 'Mobile Apps',
      'Tech News', 'Startups', 'Innovation', 'Blockchain', 'IoT'
    ],
    'Entertainment': [
      'Movies', 'TV Shows', 'Netflix', 'Video Games', 'Board Games',
      'Comedy', 'Stand-up', 'Podcasts', 'YouTube', 'Social Media',
      'Anime', 'Comics', 'Books', 'Streaming', 'Karaoke'
    ],
    'Lifestyle': [
      'Fashion', 'Beauty', 'Meditation', 'Mindfulness', 'Self-care',
      'Wellness', 'Spirituality', 'Psychology', 'Personal Growth',
      'Minimalism', 'Sustainability', 'Eco-friendly', 'Volunteering'
    ],
    'Learning': [
      'Languages', 'History', 'Science', 'Philosophy', 'Politics',
      'Economics', 'Investing', 'Real Estate', 'Business', 'Marketing',
      'Online Courses', 'Podcasts', 'Documentaries', 'Research'
    ],
  };

  @override
  void initState() {
    super.initState();
    _selectedInterests = Set.from(widget.initialInterests);
  }

  void _toggleInterest(String interest) {
    setState(() {
      if (_selectedInterests.contains(interest)) {
        _selectedInterests.remove(interest);
      } else if (_selectedInterests.length < _maxInterests) {
        _selectedInterests.add(interest);
      }
    });
  }

  void _submit() async {
    if (_selectedInterests.length < _minInterests) {
      _showMinInterestsDialog();
      return;
    }

    setState(() {
      _isLoading = true;
    });

    await Future.delayed(const Duration(milliseconds: 500)); // Simulate processing

    widget.onCompleted(_selectedInterests.toList());
  }

  void _showMinInterestsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select More Interests'),
        content: Text(
          'Please select at least $_minInterests interests to help us find better matches for you.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySection(String category, List<String> interests) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(
            category,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: interests.map((interest) {
            final isSelected = _selectedInterests.contains(interest);
            final canSelect = !isSelected && _selectedInterests.length < _maxInterests;
            
            return GestureDetector(
              onTap: isSelected || canSelect ? () => _toggleInterest(interest) : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? AppTheme.primaryGradient
                      : null,
                  color: isSelected
                      ? null
                      : canSelect
                          ? Colors.grey.shade100
                          : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: isSelected
                        ? Colors.transparent
                        : canSelect
                            ? Colors.grey.shade300
                            : Colors.grey.shade400,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      interest,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : canSelect
                                ? Colors.black87
                                : Colors.grey.shade500,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                    if (isSelected) ...[
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.check_circle,
                        color: Colors.white,
                        size: 16,
                      ),
                    ],
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildProgressIndicator() {
    final isComplete = _selectedInterests.length >= _minInterests;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isComplete
            ? AppTheme.successColor.withValues(alpha: 0.1)
            : AppTheme.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            isComplete ? Icons.check_circle : Icons.info_outline,
            color: isComplete ? AppTheme.successColor : AppTheme.primaryColor,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isComplete
                      ? 'Great! You\'ve selected ${_selectedInterests.length} interests'
                      : '${_selectedInterests.length}/$_minInterests interests selected',
                  style: TextStyle(
                    color: isComplete ? AppTheme.successColor : AppTheme.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (!isComplete)
                  Text(
                    'Select at least $_minInterests to continue',
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            '${_selectedInterests.length}/$_maxInterests',
            style: TextStyle(
              color: isComplete ? AppTheme.successColor : AppTheme.primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  bool get _canProceed => _selectedInterests.length >= _minInterests;

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
                'What are you into?',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ).animate().fadeIn(delay: 100.ms),
              
              const SizedBox(height: 8),
              
              Text(
                'Select your interests to help us find people you\'ll connect with.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ).animate().fadeIn(delay: 200.ms),
              
              const SizedBox(height: 24),
              
              _buildProgressIndicator()
                  .animate(delay: 300.ms)
                  .fadeIn()
                  .slideY(begin: -0.2),
              
              const SizedBox(height: 24),
              
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _interestCategories.entries.map((entry) {
                      final categoryIndex = _interestCategories.keys.toList().indexOf(entry.key);
                      return _buildCategorySection(entry.key, entry.value)
                          .animate(delay: (400 + categoryIndex * 100).ms)
                          .fadeIn()
                          .slideX(begin: -0.1);
                    }).toList(),
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
                      text: _canProceed
                          ? 'Continue'
                          : 'Select ${_minInterests - _selectedInterests.length} more',
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
