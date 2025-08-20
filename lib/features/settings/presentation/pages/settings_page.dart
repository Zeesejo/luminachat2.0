import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/loading_overlay.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool _isLoading = false;
  bool _notificationsEnabled = true;
  bool _locationEnabled = true;
  bool _biometricEnabled = false;
  bool _onlineStatusVisible = true;
  bool _readReceiptsEnabled = true;
  bool _voiceMessagesEnabled = true;
  bool _autoDownloadMedia = true;
  double _maxDistance = 50.0;
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _getAppVersion();
  }

  Future<void> _loadSettings() async {
    // TODO: Load from SharedPreferences
    setState(() {
      // Load saved settings
    });
  }

  Future<void> _getAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = packageInfo.version;
    });
  }

  Future<void> _enableBiometric(bool value) async {
    if (value) {
      final LocalAuthentication auth = LocalAuthentication();
      final bool canCheckBiometrics = await auth.canCheckBiometrics;
      
      if (!canCheckBiometrics) {
        _showError('Biometric authentication not available on this device');
        return;
      }

      final List<BiometricType> availableBiometrics = await auth.getAvailableBiometrics();
      
      if (availableBiometrics.isEmpty) {
        _showError('No biometric authentication methods set up');
        return;
      }

      try {
        final bool didAuthenticate = await auth.authenticate(
          localizedReason: 'Enable biometric authentication for Lumina Chat',
          options: const AuthenticationOptions(
            biometricOnly: true,
            stickyAuth: true,
          ),
        );

        if (didAuthenticate) {
          setState(() {
            _biometricEnabled = value;
          });
          // TODO: Save to SharedPreferences
        }
      } catch (e) {
        _showError('Failed to enable biometric authentication');
      }
    } else {
      setState(() {
        _biometricEnabled = value;
      });
      // TODO: Save to SharedPreferences
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorColor,
      ),
    );
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.errorColor,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        final authService = ref.read(authServiceProvider);
        await authService.signOut();
        if (mounted) {
          context.go(AppRoutes.welcome);
        }
      } catch (e) {
        if (mounted) {
          _showError('Failed to sign out. Please try again.');
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Settings',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 20),
              
              // Profile Section
              _buildSection(
                title: 'Profile',
                children: [
                  _buildListTile(
                    icon: Icons.person_outline,
                    title: 'Edit Profile',
                    subtitle: 'Update your profile information',
                    onTap: () => context.push(AppRoutes.editProfile),
                  ),
                  _buildListTile(
                    icon: Icons.photo_library_outlined,
                    title: 'Manage Photos',
                    subtitle: 'Add or remove profile photos',
                    onTap: () {
                      // TODO: Navigate to photo management
                    },
                  ),
                  _buildListTile(
                    icon: Icons.psychology_outlined,
                    title: 'Retake Personality Test',
                    subtitle: 'Update your personality type',
                    onTap: () {
                      // TODO: Navigate to personality test
                    },
                  ),
                ],
              ).animate().slideX(
                begin: -0.3,
                duration: 600.ms,
                curve: Curves.easeOut,
              ).fadeIn(),
              
              // Privacy & Security Section
              _buildSection(
                title: 'Privacy & Security',
                children: [
                  _buildSwitchTile(
                    icon: Icons.fingerprint,
                    title: 'Biometric Authentication',
                    subtitle: 'Use fingerprint or face ID to unlock',
                    value: _biometricEnabled,
                    onChanged: _enableBiometric,
                  ),
                  _buildSwitchTile(
                    icon: Icons.visibility_outlined,
                    title: 'Online Status',
                    subtitle: 'Show when you\'re online',
                    value: _onlineStatusVisible,
                    onChanged: (value) {
                      setState(() => _onlineStatusVisible = value);
                      // TODO: Save to preferences
                    },
                  ),
                  _buildSwitchTile(
                    icon: Icons.done_all,
                    title: 'Read Receipts',
                    subtitle: 'Let others know when you\'ve read their messages',
                    value: _readReceiptsEnabled,
                    onChanged: (value) {
                      setState(() => _readReceiptsEnabled = value);
                      // TODO: Save to preferences
                    },
                  ),
                  _buildListTile(
                    icon: Icons.block,
                    title: 'Blocked Users',
                    subtitle: 'Manage blocked users',
                    onTap: () {
                      // TODO: Navigate to blocked users
                    },
                  ),
                ],
              ).animate(delay: 200.ms).slideX(
                begin: -0.3,
                duration: 600.ms,
                curve: Curves.easeOut,
              ).fadeIn(),
              
              // Discovery Section
              _buildSection(
                title: 'Discovery',
                children: [
                  _buildSwitchTile(
                    icon: Icons.location_on_outlined,
                    title: 'Location Services',
                    subtitle: 'Find matches near you',
                    value: _locationEnabled,
                    onChanged: (value) {
                      setState(() => _locationEnabled = value);
                      // TODO: Save to preferences and handle permissions
                    },
                  ),
                  _buildSliderTile(
                    icon: Icons.social_distance,
                    title: 'Maximum Distance',
                    subtitle: '${_maxDistance.round()} km',
                    value: _maxDistance,
                    min: 1.0,
                    max: 100.0,
                    onChanged: (value) {
                      setState(() => _maxDistance = value);
                      // TODO: Save to preferences
                    },
                  ),
                  _buildListTile(
                    icon: Icons.tune,
                    title: 'Advanced Filters',
                    subtitle: 'Age, interests, and more',
                    onTap: () {
                      // TODO: Navigate to advanced filters
                    },
                  ),
                ],
              ).animate(delay: 400.ms).slideX(
                begin: -0.3,
                duration: 600.ms,
                curve: Curves.easeOut,
              ).fadeIn(),
              
              // Appearance Section
              _buildSection(
                title: 'Appearance',
                children: [
                  _buildSwitchTile(
                    icon: Icons.dark_mode_outlined,
                    title: 'Dark Mode',
                    subtitle: 'Switch to dark theme for better night viewing',
                    value: ref.watch(themeProvider),
                    onChanged: (value) {
                      ref.read(themeProvider.notifier).state = value;
                      // TODO: Save to SharedPreferences
                    },
                  ),
                  _buildSwitchTile(
                    icon: Icons.mic_outlined,
                    title: 'Voice Messages',
                    subtitle: 'Enable sending voice messages',
                    value: _voiceMessagesEnabled,
                    onChanged: (value) {
                      setState(() => _voiceMessagesEnabled = value);
                      // TODO: Save to preferences
                    },
                  ),
                  _buildSwitchTile(
                    icon: Icons.download_outlined,
                    title: 'Auto-Download Media',
                    subtitle: 'Automatically download photos and videos',
                    value: _autoDownloadMedia,
                    onChanged: (value) {
                      setState(() => _autoDownloadMedia = value);
                      // TODO: Save to preferences
                    },
                  ),
                ],
              ).animate(delay: 500.ms).slideX(
                begin: -0.3,
                duration: 600.ms,
                curve: Curves.easeOut,
              ).fadeIn(),
              
              // Notifications Section
              _buildSection(
                title: 'Notifications',
                children: [
                  _buildSwitchTile(
                    icon: Icons.notifications_outlined,
                    title: 'Push Notifications',
                    subtitle: 'Receive notifications for new messages and matches',
                    value: _notificationsEnabled,
                    onChanged: (value) {
                      setState(() => _notificationsEnabled = value);
                      // TODO: Save to preferences
                    },
                  ),
                  _buildListTile(
                    icon: Icons.schedule,
                    title: 'Notification Schedule',
                    subtitle: 'Set quiet hours',
                    onTap: () {
                      // TODO: Navigate to notification schedule
                    },
                  ),
                ],
              ).animate(delay: 600.ms).slideX(
                begin: -0.3,
                duration: 600.ms,
                curve: Curves.easeOut,
              ).fadeIn(),
              
              // Support Section
              _buildSection(
                title: 'Support',
                children: [
                  _buildListTile(
                    icon: Icons.help_outline,
                    title: 'Help & FAQ',
                    subtitle: 'Get answers to common questions',
                    onTap: () {
                      // TODO: Navigate to help
                    },
                  ),
                  _buildListTile(
                    icon: Icons.contact_support_outlined,
                    title: 'Contact Support',
                    subtitle: 'Get help from our team',
                    onTap: () {
                      // TODO: Navigate to contact support
                    },
                  ),
                  _buildListTile(
                    icon: Icons.privacy_tip_outlined,
                    title: 'Privacy Policy',
                    subtitle: 'Learn how we protect your data',
                    onTap: () {
                      // TODO: Open privacy policy
                    },
                  ),
                  _buildListTile(
                    icon: Icons.description_outlined,
                    title: 'Terms of Service',
                    subtitle: 'Read our terms and conditions',
                    onTap: () {
                      // TODO: Open terms of service
                    },
                  ),
                ],
              ).animate(delay: 800.ms).slideX(
                begin: -0.3,
                duration: 600.ms,
                curve: Curves.easeOut,
              ).fadeIn(),
              
              // About Section
              _buildSection(
                title: 'About',
                children: [
                  _buildListTile(
                    icon: Icons.info_outline,
                    title: 'App Version',
                    subtitle: _appVersion,
                    onTap: null,
                  ),
                  _buildListTile(
                    icon: Icons.star_border,
                    title: 'Rate App',
                    subtitle: 'Leave a review on the app store',
                    onTap: () {
                      // TODO: Open app store for rating
                    },
                  ),
                ],
              ).animate(delay: 1000.ms).slideX(
                begin: -0.3,
                duration: 600.ms,
                curve: Curves.easeOut,
              ).fadeIn(),
              
              const SizedBox(height: 40),
              
              // Sign Out Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _signOut,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.errorColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      'Sign Out',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ).animate(delay: 1200.ms).scale(
                duration: 400.ms,
                curve: Curves.elasticOut,
              ),
              
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryColor,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return ListTile(
    leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
      color: AppTheme.primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: AppTheme.primaryColor,
          size: 22,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: Colors.grey.shade600,
          fontSize: 13,
        ),
      ),
      trailing: trailing ?? (onTap != null 
          ? const Icon(Icons.chevron_right, color: Colors.grey)
          : null),
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return _buildListTile(
      icon: icon,
      title: title,
      subtitle: subtitle,
      onTap: () => onChanged(!value),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppTheme.primaryColor,
      ),
    );
  }

  Widget _buildSliderTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      children: [
        _buildListTile(
          icon: icon,
          title: title,
          subtitle: subtitle,
          onTap: null,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: (max - min).round(),
            activeColor: AppTheme.primaryColor,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
