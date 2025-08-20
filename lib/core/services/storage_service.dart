import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:injectable/injectable.dart';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';

import '../utils/exceptions.dart';

@singleton
class StorageService {
  final Uuid _uuid = const Uuid();
  
  // Cloudinary Configuration
  static const String _cloudName = 'dricz4rqn';
  static const String _apiKey = '591573241333821';
  static const String _apiSecret = 'jltnSa8zSkvsV_U4sLpT13oeVEk';

  StorageService();

  /// Generate Cloudinary signature for secure uploads
  String _generateSignature(Map<String, String> params, String apiSecret) {
    // Sort parameters alphabetically
    final sortedKeys = params.keys.toList()..sort();
    final sortedParams = sortedKeys.map((key) => '$key=${params[key]}').join('&');
  final stringToSign = '$sortedParams$apiSecret';
    
    // Generate SHA-1 hash
    final bytes = utf8.encode(stringToSign);
    final digest = sha1.convert(bytes);
  final signature = digest.toString();
  // Do not log signature or stringToSign as they include sensitive data.
  return signature;
  }

  /// Upload profile image to Cloudinary
  Future<String> uploadProfileImage(String userId, File imageFile) async {
    try {
      // Validate file exists and is readable
      if (!await imageFile.exists()) {
        throw const AppException('Image file does not exist');
      }

      final fileSize = await imageFile.length();
      if (fileSize == 0) {
        throw const AppException('Image file is empty');
      }

      if (fileSize > 10 * 1024 * 1024) { // 10MB limit
        throw const AppException('Image is too large. Please select a smaller image.');
      }

      if (kDebugMode) {
        // Lightweight diagnostics in debug only
        // Avoid logging paths or PII
        debugPrint('Cloudinary upload init (size: $fileSize)');
      }

      // Generate unique public ID for the image
      final uniqueId = _uuid.v4();
  final publicId = 'profile_images/${userId}_$uniqueId';
      final timestamp = (DateTime.now().millisecondsSinceEpoch / 1000).floor().toString();

      // Prepare upload parameters
      final params = <String, String>{
        'public_id': publicId,
        'timestamp': timestamp,
      };

      // Generate signature
      final signature = _generateSignature(params, _apiSecret);

      // Create multipart request
  final uri = Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/image/upload');
  final request = http.MultipartRequest('POST', uri);

      // Add parameters
      request.fields.addAll(params);
      request.fields['api_key'] = _apiKey;
      request.fields['signature'] = signature;

      // Add file
      final multipartFile = await http.MultipartFile.fromPath(
        'file',
        imageFile.path,
      );
      request.files.add(multipartFile);

      if (kDebugMode) {
  debugPrint('Uploading to Cloudinary…');
      }
      
      // Send request
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
  final jsonResponse = json.decode(responseBody);
        final imageUrl = jsonResponse['secure_url'] as String;
        
        if (kDebugMode) {
          debugPrint('Cloudinary upload success');
        }
        return imageUrl;
      } else {
        if (kDebugMode) {
          debugPrint('Cloudinary upload failed: ${response.statusCode}');
          debugPrint('Response: $responseBody');
        }
  throw AppException('Upload failed: ${response.statusCode} - $responseBody');
      }
      
    } on AppException {
      rethrow;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Storage service error: $e');
      }
      throw AppException('Failed to upload profile image: $e');
    }
  }

  /// Test connection to Cloudinary (simplified version)
  Future<bool> testStorageConnection() async {
    try {
      if (kDebugMode) {
        debugPrint('Testing Cloudinary connection…');
      }
      
      // Simple ping to Cloudinary API
      final response = await http.get(
        Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/image/list'),
      );
      
      if (response.statusCode == 401) {
        // 401 is expected without authentication, but means the service is reachable
        if (kDebugMode) {
          debugPrint('Cloudinary reachable (401)');
        }
        return true;
      } else if (response.statusCode == 200) {
        if (kDebugMode) {
          debugPrint('Cloudinary connection OK');
        }
        return true;
      } else if (response.statusCode == 404) {
        // 404 is also acceptable - means Cloudinary is reachable but endpoint needs auth
        if (kDebugMode) {
          debugPrint('Cloudinary reachable (404)');
        }
        return true;
      } else {
        if (kDebugMode) {
          debugPrint('Unexpected Cloudinary response: ${response.statusCode}');
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Cloudinary connection test failed: $e');
      }
      return false;
    }
  }

  /// Delete profile image (optional - for cleanup)
  Future<void> deleteProfileImage(String imageUrl) async {
    try {
      // Extract public_id from Cloudinary URL
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;
      
      // Find the public_id in the URL path
      String? publicId;
      for (int i = 0; i < pathSegments.length; i++) {
        if (pathSegments[i] == 'image' && i + 2 < pathSegments.length) {
          publicId = pathSegments[i + 2].split('.').first; // Remove file extension
          break;
        }
      }
      
      if (publicId == null) {
        if (kDebugMode) {
          debugPrint('Could not extract public_id from URL: $imageUrl');
        }
        return;
      }

      final timestamp = (DateTime.now().millisecondsSinceEpoch / 1000).floor().toString();
      
      // Prepare deletion parameters
      final params = <String, String>{
        'public_id': publicId,
        'timestamp': timestamp,
      };

      // Generate signature
      final signature = _generateSignature(params, _apiSecret);

      // Send deletion request
      final response = await http.post(
        Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/image/destroy'),
        body: {
          ...params,
          'api_key': _apiKey,
          'signature': signature,
        },
      );

      if (kDebugMode) {
        if (response.statusCode == 200) {
          debugPrint('Image deleted from Cloudinary');
        } else {
          debugPrint('Failed to delete image: ${response.statusCode}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error deleting image: $e');
      }
    }
  }

  // Validation methods
  bool isValidImageType(File file) {
    final allowedExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp'];
    final extension = file.path.toLowerCase().split('.').last;
    return allowedExtensions.contains('.$extension');
  }

  bool isFileSizeValid(File file, {int maxSizeInMB = 10}) {
    final fileSize = file.lengthSync();
    final maxSizeInBytes = maxSizeInMB * 1024 * 1024;
    return fileSize <= maxSizeInBytes;
  }

  bool isValidAudioType(File file) {
    final allowedExtensions = ['.mp3', '.wav', '.aac', '.m4a', '.ogg'];
    final extension = file.path.toLowerCase().split('.').last;
    return allowedExtensions.contains('.$extension');
  }

  // Chat-specific upload methods
  Future<String> uploadChatImage(String chatId, File imageFile) async {
    try {
      if (!imageFile.existsSync()) {
  throw const AppException('Image file does not exist');
      }

      final bytes = await imageFile.readAsBytes();
      if (bytes.isEmpty) {
  throw const AppException('Image file is empty');
      }

      // Check file size (10MB limit for chat images)
      if (!isFileSizeValid(imageFile, maxSizeInMB: 10)) {
        throw const AppException('Image is too large. Please select a smaller image.');
      }

      final timestamp = (DateTime.now().millisecondsSinceEpoch / 1000).floor().toString();
  final publicId = 'chat_images/$chatId/${_uuid.v4()}';
      
      // Prepare upload parameters for chat images with different transformations
      final params = <String, String>{
        'public_id': publicId,
        'timestamp': timestamp,
        'transformation': 'w_800,h_600,c_limit,q_auto,f_auto', // Larger for chat images
      };

      // Generate signature
      final signature = _generateSignature(params, _apiSecret);

      // Create multipart request
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/image/upload'),
      );

      // Add fields
      request.fields['api_key'] = _apiKey;
      request.fields['timestamp'] = timestamp;
      request.fields['public_id'] = publicId;
      request.fields['transformation'] = 'w_800,h_600,c_limit,q_auto,f_auto';
      request.fields['signature'] = signature;

      // Add file
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: 'chat_image_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
      );

      // Send request
      final response = await request.send();
      final responseString = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final responseData = json.decode(responseString);
        final imageUrl = responseData['secure_url'] as String;
        if (kDebugMode) {
          debugPrint('Chat image uploaded successfully to Cloudinary: $imageUrl');
        }
        return imageUrl;
      } else {
  throw AppException('Upload failed: ${response.statusCode} - $responseString');
      }
    } on AppException {
      rethrow;
    } catch (e) {
      throw AppException('Failed to upload chat image: $e');
    }
  }

  Future<String> uploadChatFile(String chatId, File file, {String? fileName, String? mimeType}) async {
    try {
      if (!file.existsSync()) {
  throw const AppException('File does not exist');
      }

      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) {
  throw const AppException('File is empty');
      }

      // Check file size (50MB limit for general files)
      if (!isFileSizeValid(file, maxSizeInMB: 50)) {
        throw const AppException('File is too large. Please select a smaller file.');
      }

      final timestamp = (DateTime.now().millisecondsSinceEpoch / 1000).floor().toString();
  final publicId = 'chat_files/$chatId/${_uuid.v4()}';
      
      // For non-image files, use raw upload
      final params = <String, String>{
        'public_id': publicId,
        'timestamp': timestamp,
        'resource_type': 'raw', // For non-image files
      };

      // Generate signature
      final signature = _generateSignature(params, _apiSecret);

      // Create multipart request for raw file upload
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/raw/upload'),
      );

      // Add fields
      request.fields['api_key'] = _apiKey;
      request.fields['timestamp'] = timestamp;
      request.fields['public_id'] = publicId;
      request.fields['resource_type'] = 'raw';
      request.fields['signature'] = signature;

      // Add file
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: fileName ?? 'chat_file_${DateTime.now().millisecondsSinceEpoch}',
        ),
      );

      // Send request
      final response = await request.send();
      final responseString = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final responseData = json.decode(responseString);
        final fileUrl = responseData['secure_url'] as String;
        if (kDebugMode) {
          debugPrint('Chat file uploaded successfully to Cloudinary: $fileUrl');
        }
        return fileUrl;
      } else {
  throw AppException('Upload failed: ${response.statusCode} - $responseString');
      }
    } on AppException {
      rethrow;
    } catch (e) {
      throw AppException('Failed to upload chat file: $e');
    }
  }

  Future<String> uploadVoiceMessage(String chatId, File audioFile) async {
    try {
      if (!audioFile.existsSync()) {
  throw const AppException('Audio file does not exist');
      }

      final bytes = await audioFile.readAsBytes();
      if (bytes.isEmpty) {
  throw const AppException('Audio file is empty');
      }

      // Check file size (25MB limit for audio)
      if (!isFileSizeValid(audioFile, maxSizeInMB: 25)) {
        throw const AppException('Audio file is too large. Please select a smaller file.');
      }

      final timestamp = (DateTime.now().millisecondsSinceEpoch / 1000).floor().toString();
  final publicId = 'voice_messages/$chatId/${_uuid.v4()}';
      
      // For audio files, use raw upload
      final params = <String, String>{
        'public_id': publicId,
        'timestamp': timestamp,
        'resource_type': 'raw',
      };

      // Generate signature
      final signature = _generateSignature(params, _apiSecret);

      // Create multipart request for audio upload
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/raw/upload'),
      );

      // Add fields
      request.fields['api_key'] = _apiKey;
      request.fields['timestamp'] = timestamp;
      request.fields['public_id'] = publicId;
      request.fields['resource_type'] = 'raw';
      request.fields['signature'] = signature;

      // Add file
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: 'voice_message_${DateTime.now().millisecondsSinceEpoch}.m4a',
        ),
      );

      // Send request
      final response = await request.send();
      final responseString = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final responseData = json.decode(responseString);
        final audioUrl = responseData['secure_url'] as String;
        if (kDebugMode) {
          debugPrint('Voice message uploaded successfully to Cloudinary: $audioUrl');
        }
        return audioUrl;
      } else {
        throw AppException('Upload failed: ${response.statusCode} - $responseString');
      }
    } on AppException {
      rethrow;
    } catch (e) {
      throw AppException('Failed to upload voice message: $e');
    }
  }
}

// Provider for dependency injection
final storageServiceProvider = Provider<StorageService>((ref) => StorageService());
