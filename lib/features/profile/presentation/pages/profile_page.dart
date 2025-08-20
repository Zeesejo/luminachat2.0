import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/models/user_model.dart';
import '../../../../core/services/user_service.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  late PageController _pageController;
  int _currentPhotoIndex = 0;

  UserModel? _user;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<UserModel?>(
        stream: ref.read(userServiceProvider).getCurrentUserStream(),
        builder: (context, snapshot) {
          _user = snapshot.data;
          return CustomScrollView(
            slivers: [
              // App Bar with Photos
              SliverAppBar(
            expandedHeight: 400,
            pinned: true,
            backgroundColor: AppTheme.primaryColor,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.white),
                onPressed: () {
                  // TODO: Navigate to edit profile
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                children: [
                  // Photo Carousel
                  if ((_user?.photos.isNotEmpty ?? false))
                    PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() => _currentPhotoIndex = index);
                    },
                    itemCount: _user!.photos.length,
                    itemBuilder: (context, index) {
                      final path = _user!.photos[index];
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
                  if ((_user?.photos.length ?? 0) > 1)
                    Positioned(
                      top: 100,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          _user!.photos.length,
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
                              Text(
                                _user?.name ?? 'Your Profile',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (_user?.isVerified == true)
                                const Icon(
                                  Icons.verified,
                                  color: Colors.blue,
                                  size: 24,
                                ),
                            ],
                          ),
                                    Text(
                                      _user == null ? '' : '${_user!.age} • ${_user!.location?.city ?? ''}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
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
                  // Bio Section
                  if (_user?.bio != null) ...[
                    _buildSectionTitle('About'),
                    const SizedBox(height: 12),
                    Text(
                      _user!.bio!,
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.5,
                        color: Colors.grey.shade700,
                      ),
                    ).animate().fadeIn(delay: 200.ms),
                    const SizedBox(height: 32),
                  ],
                  
                  // Personality Section
                  if (_user?.personalityType != null) ...[
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
                                  _user!.personalityType!.type,
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
                                  _user!.personalityType!.title,
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
                            _user!.personalityType!.description,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ).animate().slideX(
                      begin: -0.3,
                      duration: 600.ms,
                      delay: 400.ms,
                      curve: Curves.easeOut,
                    ).fadeIn(),
                    const SizedBox(height: 32),
                  ],
                  
                  // Interests Section
                  if ((_user?.interests.isNotEmpty ?? false)) ...[
                    _buildSectionTitle('Interests'),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _user!.interests.map((interest) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(
                              color: AppTheme.primaryColor.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            interest,
                            style: const TextStyle(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                    ).animate().fadeIn(delay: 600.ms),
                    const SizedBox(height: 32),
                  ],
                  
                  // Profile Stats
                  _buildSectionTitle('Profile'),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                                  _buildStatRow(
                          icon: Icons.check_circle_outline,
                          label: 'Profile Completion',
                                    value: _user == null ? '0%' : '${_user!.profileCompletionPercentage.round()}%',
                          color: AppTheme.successColor,
                        ),
                        const SizedBox(height: 16),
                                  _buildStatRow(
                          icon: Icons.verified_user_outlined,
                          label: 'Verification Status',
                          value: _user?.isVerified == true ? 'Verified' : 'Pending',
                          color: _user?.isVerified == true 
                              ? AppTheme.successColor 
                              : AppTheme.warningColor,
                        ),
                        const SizedBox(height: 16),
                        _buildStatRow(
                          icon: Icons.calendar_today_outlined,
                          label: 'Member Since',
                          value: _user == null ? '-' : _formatDate(_user!.createdAt),
                          color: Colors.grey.shade600,
                        ),
                      ],
                    ),
                  ).animate().slideY(
                    begin: 0.3,
                    duration: 600.ms,
                    delay: 800.ms,
                    curve: Curves.easeOut,
                  ).fadeIn(),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
          ],
        );
        },
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

  Widget _buildStatRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: color,
            size: 22,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays >= 365) {
      final years = (difference.inDays / 365).floor();
  return '$years year${years == 1 ? '' : 's'} ago';
    } else if (difference.inDays >= 30) {
      final months = (difference.inDays / 30).floor();
  return '$months month${months == 1 ? '' : 's'} ago';
    } else {
  return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    }
  }
}
