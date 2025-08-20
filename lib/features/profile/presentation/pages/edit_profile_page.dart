import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/services/storage_service.dart';
import '../../../../core/services/user_service.dart';
import '../../../../shared/models/user_model.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../../../../shared/widgets/loading_overlay.dart';

class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  
  bool _isLoading = false;
  UserModel? _currentUser;
  List<String> _photos = [];
  List<String> _selectedInterests = [];
  
  // Available interests
  final List<String> _availableInterests = [
    'Adventure', 'Art', 'Books', 'Coffee', 'Cooking', 'Dancing', 'Fashion',
    'Fitness', 'Gaming', 'Hiking', 'Movies', 'Music', 'Nature', 'Photography',
    'Reading', 'Sports', 'Technology', 'Travel', 'Yoga', 'Writing',
    'Pets', 'Food', 'Wine', 'Camping', 'Cycling', 'Running', 'Swimming',
    'Meditation', 'Volunteering', 'Languages', 'Business', 'Science',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    try {
      final userService = ref.read(userServiceProvider);
      final user = await userService.getCurrentUser();
      if (user == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No authenticated user. Please sign in again.'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
        return;
      }

      setState(() {
        _currentUser = user;
        _nameController.text = user.name;
        _bioController.text = user.bio ?? '';
        _selectedInterests = List<String>.from(user.interests);
        // Seed photos from user model: prefer photos list, fallback to profileImageUrl
        final photos = <String>[];
        if (user.photos.isNotEmpty) {
          photos.addAll(user.photos);
        } else if ((user.profileImageUrl ?? '').isNotEmpty) {
          photos.add(user.profileImageUrl!);
        }
        _photos = photos;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load profile: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() => _isLoading = true);
        try {
          final storage = ref.read(storageServiceProvider);
          final userId = _currentUser?.id;
          if (userId == null) {
            throw 'No authenticated user.';
          }
          final url = await storage.uploadProfileImage(userId, File(image.path));
          if (!mounted) return;
          setState(() {
            if (_photos.length < 6) {
              _photos.add(url);
            }
          });
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Upload failed: $e'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        } finally {
          if (mounted) setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to pick image: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  Future<void> _takePhoto() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() => _isLoading = true);
        try {
          final storage = ref.read(storageServiceProvider);
          final userId = _currentUser?.id;
          if (userId == null) {
            throw 'No authenticated user.';
          }
          final url = await storage.uploadProfileImage(userId, File(image.path));
          if (!mounted) return;
          setState(() {
            if (_photos.length < 6) {
              _photos.add(url);
            }
          });
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Upload failed: $e'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        } finally {
          if (mounted) setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to take photo: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  void _removePhoto(int index) {
    final url = _photos[index];
    setState(() {
      _photos.removeAt(index);
    });
    // Best-effort remote cleanup for Cloudinary URLs
    if (url.startsWith('http')) {
      // Fire and forget; no need to block UI
      Future(() async {
        try {
          await ref.read(storageServiceProvider).deleteProfileImage(url);
        } catch (_) {}
      });
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Add Photo',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildImageSourceOption(
                    icon: Icons.photo_library,
                    label: 'Gallery',
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage();
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildImageSourceOption(
                    icon: Icons.camera_alt,
                    label: 'Camera',
                    onTap: () {
                      Navigator.pop(context);
                      _takePhoto();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSourceOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.primaryColor.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: AppTheme.primaryColor,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    if (_photos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one photo'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    if (_selectedInterests.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least 3 interests'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = _currentUser;
      if (user == null) {
        throw 'No authenticated user.';
      }

      final updatedFlags = user.profileCompletion.copyWith(
        hasProfilePhoto: _photos.isNotEmpty,
        hasBio: _bioController.text.trim().isNotEmpty,
        hasInterests: _selectedInterests.isNotEmpty,
        hasMultiplePhotos: _photos.length >= 2,
      );

      final updated = user.copyWith(
        name: _nameController.text.trim(),
        bio: _bioController.text.trim(),
        interests: List<String>.from(_selectedInterests),
        photos: List<String>.from(_photos),
        profileImageUrl: _photos.isNotEmpty ? _photos.first : user.profileImageUrl,
        profileCompletion: updatedFlags,
        updatedAt: DateTime.now(),
      );

      await ref.read(userServiceProvider).updateUser(updated);

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully!'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: Colors.transparent,
        actions: [
          TextButton(
            onPressed: _saveProfile,
            child: const Text(
              'Save',
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Photos Section
                Text(
                  'Photos',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ).animate().fadeIn(),
                
                const SizedBox(height: 16),
                
                SizedBox(
                  height: 120,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _photos.length + 1,
                    itemBuilder: (context, index) {
                      if (index == _photos.length) {
                        // Add photo button
                        return GestureDetector(
                          onTap: _photos.length < 6 ? _showImageSourceDialog : null,
                          child: Container(
                            width: 100,
                            height: 120,
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                color: _photos.length < 6 
                  ? AppTheme.primaryColor.withValues(alpha: 0.1)
                                  : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                color: _photos.length < 6 
                  ? AppTheme.primaryColor.withValues(alpha: 0.3)
                                    : Colors.grey.shade300,
                                style: BorderStyle.solid,
                              ),
                            ),
                            child: Icon(
                              Icons.add_photo_alternate,
                              color: _photos.length < 6 
                                  ? AppTheme.primaryColor
                                  : Colors.grey.shade400,
                              size: 32,
                            ),
                          ),
                        );
                      }
                      
                      // Photo item
                      return Container(
                        width: 100,
                        height: 120,
                        margin: const EdgeInsets.only(right: 12),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Builder(
                                builder: (context) {
                                  final path = _photos[index];
                                  if (path.startsWith('assets/')) {
                                    return Image.asset(
                                      path,
                                      width: 100,
                                      height: 120,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        color: Colors.grey.shade200,
                                        alignment: Alignment.center,
                                        child: const Icon(Icons.person, color: Colors.grey),
                                      ),
                                    );
                                  }
                                  return CachedNetworkImage(
                                    imageUrl: path,
                                    width: 100,
                                    height: 120,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Shimmer.fromColors(
                                      baseColor: Colors.grey.shade300,
                                      highlightColor: Colors.grey.shade100,
                                      child: Container(
                                        color: Colors.white,
                                        width: 100,
                                        height: 120,
                                      ),
                                    ),
                                    errorWidget: (context, url, error) => Container(
                                      color: Colors.grey.shade200,
                                      child: const Icon(Icons.error),
                                    ),
                                  );
                                },
                              ),
                            ),
                            
                            // Remove button
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () => _removePhoto(index),
                                child: Container(
                                  width: 24,
                                  height: 24,
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),
                            
                            // Primary photo indicator
                            if (index == 0)
                              Positioned(
                                bottom: 4,
                                left: 4,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'Main',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ).animate(delay: (index * 100).ms).slideX(
                        begin: 0.3,
                        duration: 400.ms,
                        curve: Curves.easeOut,
                      ).fadeIn();
                    },
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Basic Info Section
                Text(
                  'Basic Information',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ).animate(delay: 200.ms).fadeIn(),
                
                const SizedBox(height: 16),
                
                CustomTextField(
                  controller: _nameController,
                  label: 'Name',
                  hintText: 'Enter your name',
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Name is required';
                    }
                    if (value.trim().length < 2) {
                      return 'Name must be at least 2 characters';
                    }
                    return null;
                  },
                ).animate(delay: 300.ms).slideX(
                  begin: -0.3,
                  duration: 600.ms,
                  curve: Curves.easeOut,
                ).fadeIn(),
                
                const SizedBox(height: 16),
                
                CustomTextField(
                  controller: _bioController,
                  label: 'Bio',
                  hintText: 'Tell us about yourself...',
                  maxLines: 4,
                  maxLength: 500,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Bio is required';
                    }
                    if (value.trim().length < 20) {
                      return 'Bio must be at least 20 characters';
                    }
                    return null;
                  },
                ).animate(delay: 400.ms).slideX(
                  begin: -0.3,
                  duration: 600.ms,
                  curve: Curves.easeOut,
                ).fadeIn(),
                
                const SizedBox(height: 32),
                
                // Interests Section
                Text(
                  'Interests',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ).animate(delay: 500.ms).fadeIn(),
                
                const SizedBox(height: 8),
                
                Text(
                  'Select at least 3 interests (${_selectedInterests.length}/10)',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ).animate(delay: 600.ms).fadeIn(),
                
                const SizedBox(height: 16),
                
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _availableInterests.map((interest) {
                    final isSelected = _selectedInterests.contains(interest);
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selectedInterests.remove(interest);
                          } else if (_selectedInterests.length < 10) {
                            _selectedInterests.add(interest);
                          }
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected 
                              ? AppTheme.primaryColor 
                              : AppTheme.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(
                            color: AppTheme.primaryColor.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          interest,
                          style: TextStyle(
                            color: isSelected 
                                ? Colors.white 
                                : AppTheme.primaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ).animate(delay: 700.ms).fadeIn(),
                
                const SizedBox(height: 40),
                
                // Save Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saveProfile,
                    child: const Text('Save Changes'),
                  ),
                ).animate(delay: 800.ms).scale(
                  duration: 400.ms,
                  curve: Curves.elasticOut,
                ),
                
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
