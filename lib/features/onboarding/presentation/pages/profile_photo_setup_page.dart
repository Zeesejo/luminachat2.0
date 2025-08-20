import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../shared/widgets/custom_button.dart';

class ProfilePhotoSetupPage extends ConsumerStatefulWidget {
  final List<String> initialPhotos;
  final Function(List<String>) onCompleted;
  final VoidCallback? onSkipped;
  final VoidCallback? onBack;
  final bool allowSkip;

  const ProfilePhotoSetupPage({
    super.key,
    required this.initialPhotos,
    required this.onCompleted,
    this.onSkipped,
    this.onBack,
    this.allowSkip = true,
  });

  @override
  ConsumerState<ProfilePhotoSetupPage> createState() => _ProfilePhotoSetupPageState();
}

class _ProfilePhotoSetupPageState extends ConsumerState<ProfilePhotoSetupPage> {
  late List<String> _photos;
  bool _isUploading = false;
  final int _maxPhotos = 6;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _photos = List.from(widget.initialPhotos);
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      // Request permission
      Permission permission = source == ImageSource.camera 
          ? Permission.camera 
          : Permission.photos;
      
      final status = await permission.request();
      if (!status.isGranted) {
        _showPermissionDialog(source);
        return;
      }

      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        await _cropAndUploadImage(image.path);
      }
    } catch (e) {
      _showErrorDialog('Failed to pick image: $e');
    }
  }

  Future<void> _cropAndUploadImage(String imagePath) async {
    // Since UCrop has UI positioning issues on some Android versions,
    // let's show a simple confirmation dialog instead
    final shouldUpload = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Upload Photo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Your photo is ready to upload!'),
            const SizedBox(height: 16),
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(50),
                image: DecorationImage(
                  image: FileImage(File(imagePath)),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('We\'ll automatically resize it for your profile.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
            ),
            child: const Text('Upload'),
          ),
        ],
      ),
    );
    
    if (shouldUpload == true && mounted) {
      await _uploadImage(imagePath);
    }
  }

  Future<void> _uploadImage(String imagePath) async {
    setState(() {
      _isUploading = true;
    });

    try {
      final storageService = ref.read(storageServiceProvider);
      final authService = ref.read(authServiceProvider);
      final userId = authService.currentUser?.uid;
      
      if (userId == null) {
        throw Exception('User not authenticated');
      }
      
      // Test Cloudinary connection first (debug only)
      if (kDebugMode) {
        debugPrint('Testing Cloudinary connection…');
      }
      final storageConnected = await storageService.testStorageConnection();
      if (!storageConnected) {
        throw Exception('Cannot connect to Cloudinary. Please check your internet connection.');
      }
      
      // Process the image to ensure reasonable size
      File imageFile = File(imagePath);
      
      // Optional: Resize image if it's too large (basic implementation)
      // The StorageService can handle this, or we can do basic checks here
      final fileSize = await imageFile.length();
      if (fileSize > 10 * 1024 * 1024) { // 10MB limit
        throw Exception('Image is too large. Please select a smaller image.');
      }
      
      if (kDebugMode) {
        debugPrint('Starting image upload for user: $userId');
      }
      final imageUrl = await storageService.uploadProfileImage(userId, imageFile);
      if (kDebugMode) {
        debugPrint('Image upload completed successfully: $imageUrl');
      }
      
      if (mounted) {
        setState(() {
          _photos.add(imageUrl);
          _isUploading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
        _showErrorDialog('Failed to upload image: $e');
      }
    }
  }

  void _removePhoto(int index) {
    setState(() {
      _photos.removeAt(index);
    });
  }

  void _reorderPhotos(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) {
      newIndex--;
    }
    setState(() {
      final item = _photos.removeAt(oldIndex);
      _photos.insert(newIndex, item);
    });
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Add Photo',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showPermissionDialog(ImageSource source) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permission Required'),
        content: Text(
          source == ImageSource.camera
              ? 'Camera permission is required to take photos.'
              : 'Photo library permission is required to select photos.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Settings'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // ignore: unused_element
  Widget _buildPhotoGrid() {
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: (_photos.length < _maxPhotos) ? _photos.length + 1 : _photos.length,
      onReorder: _reorderPhotos,
      itemBuilder: (context, index) {
        if (index == _photos.length && _photos.length < _maxPhotos) {
          // Add photo tile
          return _buildAddPhotoTile(key: ValueKey('add_$index'));
        } else {
          // Photo tile
          return _buildPhotoTile(index, key: ValueKey(_photos[index]));
        }
      },
    );
  }

  Widget _buildAddPhotoTile({required Key key}) {
    return Card(
      key: key,
      margin: const EdgeInsets.all(8),
      child: InkWell(
        onTap: _isUploading ? null : _showImagePickerOptions,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 120,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.primaryColor.withValues(alpha: 0.3),
              style: BorderStyle.solid,
              width: 2,
            ),
          ),
          child: _isUploading
              ? const Center(
                  child: CircularProgressIndicator(),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_a_photo,
                      size: 32,
                      color: AppTheme.primaryColor,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add Photo',
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildPhotoTile(int index, {required Key key}) {
    final photoUrl = _photos[index];
    
    return Card(
      key: key,
      margin: const EdgeInsets.all(8),
      child: Stack(
        children: [
          Container(
            height: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              image: DecorationImage(
                image: NetworkImage(photoUrl),
                fit: BoxFit.cover,
              ),
            ),
          ),
          if (index == 0)
            Positioned(
              bottom: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Main',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          Positioned(
            top: 8,
            right: 8,
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
          // Drag handle
          Positioned(
            bottom: 8,
            right: 8,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.drag_indicator,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canProceed = _photos.isNotEmpty;
    
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
                'Add your photos',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ).animate().fadeIn(delay: 100.ms),
              
              const SizedBox(height: 8),
              
              Text(
                'Upload up to $_maxPhotos photos. Your first photo will be your main profile picture.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ).animate().fadeIn(delay: 200.ms),
              
              const SizedBox(height: 32),
              
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: 1.0,
                        ),
                        itemCount: (_photos.length < _maxPhotos) 
                            ? _photos.length + 1 
                            : _photos.length,
                        itemBuilder: (context, index) {
                          if (index == _photos.length && _photos.length < _maxPhotos) {
                            return _buildAddPhotoTile(key: ValueKey('add_$index'))
                                .animate(delay: (index * 100).ms)
                                .fadeIn()
                                .scale(begin: const Offset(0.8, 0.8));
                          } else {
                            return _buildPhotoTile(index, key: ValueKey(_photos[index]))
                                .animate(delay: (index * 100).ms)
                                .fadeIn()
                                .scale(begin: const Offset(0.8, 0.8));
                          }
                        },
                      ),
                    ),
                    
                    if (_photos.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: AppTheme.primaryColor,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Hold and drag photos to reorder them. Your first photo is your main profile picture.',
                                style: TextStyle(
                                  color: AppTheme.primaryColor,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: 400.ms),
                    ],
                  ],
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
                      ).animate().fadeIn(delay: 500.ms),
                    ),
                  if (widget.allowSkip && widget.onSkipped != null)
                    const SizedBox(width: 16),
                  Expanded(
                    flex: canProceed ? 2 : 1,
                    child: CustomButton(
                      text: canProceed ? 'Continue' : 'Add at least one photo',
                      onPressed: canProceed ? () => widget.onCompleted(_photos) : _showImagePickerOptions,
                      isEnabled: !_isUploading,
                      isLoading: _isUploading,
                    ).animate().fadeIn(delay: 600.ms),
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
