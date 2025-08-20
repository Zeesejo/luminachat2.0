import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/models/user_model.dart';
import '../../../../shared/models/match_model.dart';
import '../../../../core/services/chat_service.dart';
import '../../../../core/router/app_router.dart';

class MatchDetailsPage extends ConsumerStatefulWidget {
  final String userId;

  const MatchDetailsPage({
    super.key,
    required this.userId,
  });

  @override
  ConsumerState<MatchDetailsPage> createState() => _MatchDetailsPageState();
}

class _MatchDetailsPageState extends ConsumerState<MatchDetailsPage> {
  late PageController _pageController;
  int _currentPhotoIndex = 0;

  // Mock data - replace with actual data
  final UserModel _user = UserModel(
    id: 'user_123',
    email: 'emma@example.com',
    name: 'Emma Johnson',
    bio: 'Adventure seeker and coffee enthusiast ☕️ Love exploring new places, hiking on weekends, and discovering hidden gems in the city. Looking for someone to share spontaneous adventures and deep conversations with. Life\'s too short for boring moments!',
    birthDate: DateTime(1998, 3, 22),
  profileImageUrl: '',
    interests: [
      'Hiking', 'Photography', 'Coffee', 'Travel', 'Yoga', 'Reading',
      'Cooking', 'Music', 'Art', 'Movies', 'Dancing', 'Nature'
    ],
    personalityType: MBTIType.enfp,
    location: Location(
      latitude: 37.7749,
      longitude: -122.4194,
      city: 'San Francisco',
      state: 'CA',
      country: 'USA',
      formattedAddress: 'San Francisco, CA',
    ),
  photos: const <String>[],
    privacySettings: PrivacySettings(),
    profileCompletion: ProfileCompletion(
      hasProfilePhoto: true,
      hasBio: true,
      hasInterests: true,
      hasPersonalityTest: true,
      hasLocation: true,
      hasMultiplePhotos: true,
      isEmailVerified: true,
    ),
    createdAt: DateTime.now().subtract(const Duration(days: 45)),
    updatedAt: DateTime.now(),
    isVerified: true,
  );

  final MatchModel _match = MatchModel(
    id: 'match_123',
    userId1: 'current_user',
    userId2: 'user_123',
    status: MatchStatus.matched,
    compatibilityScore: 87.5,
    commonInterests: ['Hiking', 'Photography', 'Coffee', 'Travel', 'Music'],
    compatibilityBreakdown: CompatibilityBreakdown(
      overallScore: 87.5,
      personalityScore: 0.85,
      interestsScore: 0.92,
      locationScore: 0.88,
      ageCompatibilityScore: 0.95,
      topFactors: [
        CompatibilityFactor(
          name: 'Shared Adventures',
          score: 0.95,
          description: 'Both love outdoor activities and exploring new places',
          type: FactorType.interests,
        ),
        CompatibilityFactor(
          name: 'Communication Style',
          score: 0.88,
          description: 'Similar extroverted personalities make for great conversations',
          type: FactorType.personality,
        ),
        CompatibilityFactor(
          name: 'Lifestyle Match',
          score: 0.82,
          description: 'Compatible daily routines and social preferences',
          type: FactorType.lifestyle,
        ),
      ],
    ),
    createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    matchedAt: DateTime.now().subtract(const Duration(hours: 2)),
    initiator: MatchInitiator.mutual,
  );

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _startConversation() async {
    final me = FirebaseAuth.instance.currentUser?.uid;
    if (me == null) return;
    final chatService = ref.read(chatServiceProvider);
    try {
      final chat = await chatService.createOrGetDirectChat(me, widget.userId);
      if (!mounted) return;
      context.go('${AppRoutes.chat}/${chat.id}?otherUserId=${widget.userId}');
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to start chat'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  void _reportUser() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report User'),
        content: const Text('Are you sure you want to report this user?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Handle report
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('Report'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar with Photos
          SliverAppBar(
            expandedHeight: 500,
            pinned: true,
            backgroundColor: AppTheme.primaryColor,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onSelected: (value) {
                  if (value == 'report') {
                    _reportUser();
                  }
                  // TODO: Handle other actions
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'report',
                    child: Row(
                      children: [
                        Icon(Icons.report, color: Colors.red, size: 20),
                        SizedBox(width: 8),
                        Text('Report'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'block',
                    child: Row(
                      children: [
                        Icon(Icons.block, color: Colors.red, size: 20),
                        SizedBox(width: 8),
                        Text('Block'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                children: [
                  // Photo Carousel
                  if (_user.photos.isNotEmpty)
                    PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() => _currentPhotoIndex = index);
                    },
                    itemCount: _user.photos.length,
                    itemBuilder: (context, index) {
                      final path = _user.photos[index];
                      if (path.startsWith('assets/')) {
                        return Image.asset(
                          path,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: Colors.grey.shade200,
                            alignment: Alignment.center,
                            child: const Icon(Icons.person, size: 80, color: Colors.grey),
                          ),
                        );
                      }
                      return CachedNetworkImage(
                        imageUrl: path,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Shimmer.fromColors(
                          baseColor: Colors.grey.shade300,
                          highlightColor: Colors.grey.shade100,
                          child: Container(color: Colors.white),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.error),
                        ),
                      );
                    },
                    )
                  else
                    Container(
                      color: Colors.grey.shade200,
                      alignment: Alignment.center,
                      child: const Icon(Icons.person, size: 80, color: Colors.grey),
                    ),
                  
                  // Gradient Overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.7),
                        ],
                        stops: const [0.6, 1.0],
                      ),
                    ),
                  ),
                  
                  // Photo Indicators
                  if (_user.photos.length > 1)
                    Positioned(
                      top: 120,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          _user.photos.length,
                          (index) => Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                color: index == _currentPhotoIndex 
                  ? Colors.white 
                  : Colors.white.withValues(alpha: 0.5),
                            ),
                          ),
                        ),
                      ),
                    ).animate().fadeIn(),
                  
                  // User Info at Bottom
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          _user.name,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 32,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        if (_user.isVerified)
                                          const Icon(
                                            Icons.verified,
                                            color: Colors.blue,
                                            size: 24,
                                          ),
                                      ],
                                    ),
                                    Text(
                                      '${_user.age} • ${_user.location?.city}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      '${_match.compatibilityScore.round()}%',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const Text(
                                      'Match',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ).animate().slideY(
                    begin: 0.3,
                    duration: 800.ms,
                    curve: Curves.easeOut,
                  ).fadeIn(),
                ],
              ),
            ),
          ),
          
          // Profile Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Compatibility Breakdown
                  _buildSectionTitle('Why You Match'),
                  const SizedBox(height: 16),
                  ..._match.compatibilityBreakdown.topFactors.map((factor) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _getFactorColor(factor.type).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _getFactorColor(factor.type).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _getFactorIcon(factor.type),
                                color: _getFactorColor(factor.type),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  factor.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: _getFactorColor(factor.type),
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _getFactorColor(factor.type),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${(factor.score * 100).round()}%',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            factor.description,
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ).animate(delay: (300).ms).slideX(
                      begin: -0.3,
                      duration: 600.ms,
                      curve: Curves.easeOut,
                    ).fadeIn();
                  }),
                  
                  const SizedBox(height: 32),
                  
                  // Bio Section
                  if (_user.bio != null) ...[
                    _buildSectionTitle('About ${_user.name}'),
                    const SizedBox(height: 12),
                    Text(
                      _user.bio!,
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.5,
                        color: Colors.grey.shade700,
                      ),
                    ).animate(delay: 400.ms).fadeIn(),
                    const SizedBox(height: 32),
                  ],
                  
                  // Personality Section
                  if (_user.personalityType != null) ...[
                    _buildSectionTitle('Personality'),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  _user.personalityType!.type,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _user.personalityType!.title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _user.personalityType!.description,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ).animate(delay: 500.ms).slideX(
                      begin: -0.3,
                      duration: 600.ms,
                      curve: Curves.easeOut,
                    ).fadeIn(),
                    const SizedBox(height: 32),
                  ],
                  
                  // Common Interests
                  if (_match.commonInterests.isNotEmpty) ...[
                    _buildSectionTitle('You Both Love'),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _match.commonInterests.map((interest) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.successColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(
                              color: AppTheme.successColor.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.favorite,
                                color: AppTheme.successColor,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                interest,
                                style: const TextStyle(
                                  color: AppTheme.successColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ).animate(delay: 600.ms).fadeIn(),
                    const SizedBox(height: 32),
                  ],
                  
                  // All Interests
                  if (_user.interests.isNotEmpty) ...[
                    _buildSectionTitle('All Interests'),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _user.interests.map((interest) {
                        final isCommon = _match.commonInterests.contains(interest);
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: isCommon
                                ? AppTheme.successColor.withValues(alpha: 0.1)
                                : AppTheme.primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(
                              color: isCommon
                                  ? AppTheme.successColor.withValues(alpha: 0.3)
                                  : AppTheme.primaryColor.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            interest,
                            style: TextStyle(
                              color: isCommon
                                  ? AppTheme.successColor
                                  : AppTheme.primaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                    ).animate(delay: 700.ms).fadeIn(),
                  ],
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
      
      // Bottom Action Bar
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Back'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: AppTheme.primaryColor),
                    foregroundColor: AppTheme.primaryColor,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: _startConversation,
                  icon: const Icon(Icons.chat_bubble),
                  label: const Text('Say Hi'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ).animate().slideY(
        begin: 1,
        duration: 800.ms,
        curve: Curves.easeOut,
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Color _getFactorColor(FactorType type) {
    switch (type) {
      case FactorType.personality:
        return AppTheme.primaryColor;
      case FactorType.interests:
        return AppTheme.successColor;
      case FactorType.location:
        return AppTheme.warningColor;
      case FactorType.lifestyle:
        return AppTheme.secondaryColor;
      case FactorType.personalValues:
        return Colors.indigo;
    }
  // No default to keep switch exhaustive
    
  }

  IconData _getFactorIcon(FactorType type) {
    switch (type) {
      case FactorType.personality:
        return Icons.psychology;
      case FactorType.interests:
        return Icons.favorite;
      case FactorType.location:
        return Icons.location_on;
      case FactorType.lifestyle:
        return Icons.local_cafe; // Using local_cafe instead of lifestyle
      case FactorType.personalValues:
        return Icons.insights;
    }
  // No default to keep switch exhaustive
    
  }
}
