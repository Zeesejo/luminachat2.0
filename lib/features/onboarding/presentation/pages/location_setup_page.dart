import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart' hide Location;
import 'package:geocoding/geocoding.dart' as geocoding show Location;
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/models/user_model.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/custom_text_field.dart';

class LocationSetupPage extends ConsumerStatefulWidget {
  final Location? initialLocation;
  final Function(Location?) onCompleted;
  final VoidCallback? onSkipped;
  final VoidCallback? onBack;
  final bool allowSkip;

  const LocationSetupPage({
    super.key,
    this.initialLocation,
    required this.onCompleted,
    this.onSkipped,
    this.onBack,
    this.allowSkip = true,
  });

  @override
  ConsumerState<LocationSetupPage> createState() => _LocationSetupPageState();
}

class _LocationSetupPageState extends ConsumerState<LocationSetupPage> {
  final _cityController = TextEditingController();
  final _countryController = TextEditingController();
  
  Location? _currentLocation;
  bool _isLoadingLocation = false;
  bool _isSubmitting = false;
  String? _locationError;

  @override
  void initState() {
    super.initState();
    if (widget.initialLocation != null) {
      _currentLocation = widget.initialLocation;
      _cityController.text = widget.initialLocation!.city;
      _countryController.text = widget.initialLocation!.country;
    }
  }

  @override
  void dispose() {
    _cityController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
      _locationError = null;
    });

    try {
      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _locationError = 'Location permission is required to use this feature.';
            _isLoadingLocation = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showPermissionDialog();
        return;
      }

      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _locationError = 'Location services are disabled. Please enable them in settings.';
          _isLoadingLocation = false;
        });
        return;
      }

      // Try to get a fast fix with a timeout; fall back to last known or low accuracy
      late final Position pos;
      try {
        pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 10),
        );
      } on TimeoutException {
        // Fallbacks if GPS fix times out (common on emulators)
        final last = await Geolocator.getLastKnownPosition();
        if (last != null) {
          pos = last;
        } else {
          pos = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.low,
            timeLimit: const Duration(seconds: 8),
          );
        }
      }

      // Reverse geocoding to get address
      List<Placemark> placemarks = await placemarkFromCoordinates(
        pos.latitude,
        pos.longitude,
      ).timeout(const Duration(seconds: 10), onTimeout: () => <Placemark>[]);

      if (placemarks.isNotEmpty && mounted) {
        final placemark = placemarks.first;
        final location = Location(
          latitude: pos.latitude,
          longitude: pos.longitude,
          city: placemark.locality ?? placemark.subAdministrativeArea ?? 'Unknown City',
          state: placemark.administrativeArea ?? 'Unknown State',
          country: placemark.country ?? 'Unknown Country',
          formattedAddress: '${placemark.locality ?? ''}, ${placemark.country ?? ''}',
        );

        setState(() {
          _currentLocation = location;
          _cityController.text = location.city;
          _countryController.text = location.country;
        });
        
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✓ Current location detected: ${location.city}, ${location.country}'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else if (mounted) {
        setState(() {
          _locationError = 'Could not resolve address for your coordinates.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _locationError = 'Failed to get your location. Please try again or enter manually.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
        });
      }
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Permission'),
        content: const Text(
          'Location permission is permanently denied. Please enable it in app settings to use location features.',
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

    setState(() {
      _isLoadingLocation = false;
    });
  }

  Future<void> _searchLocation() async {
    final city = _cityController.text.trim();
    final country = _countryController.text.trim();
    
    if (city.isEmpty || country.isEmpty) {
      setState(() {
        _locationError = 'Please enter both city and country.';
      });
      return;
    }

    setState(() {
      _isLoadingLocation = true;
      _locationError = null;
    });

    try {
      // Geocoding to get coordinates (with a timeout to avoid indefinite spinner)
      List<geocoding.Location> locations = await locationFromAddress('$city, $country')
          .timeout(const Duration(seconds: 12));
      
      if (locations.isNotEmpty && mounted) {
        final location = locations.first;
        final userLocation = Location(
          latitude: location.latitude,
          longitude: location.longitude,
          city: city,
          state: '',
          country: country,
          formattedAddress: '$city, $country',
        );

        setState(() {
          _currentLocation = userLocation;
          _isLoadingLocation = false;
        });
        
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✓ Location found: $city, $country'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else if (mounted) {
        setState(() {
          _locationError = 'No results for "$city, $country". Please refine your input.';
        });
      }
    } on TimeoutException {
      if (mounted) {
        setState(() {
          _locationError = 'Search timed out. Check internet connection and try again.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _locationError = 'Could not find this location. Please check the spelling.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
        });
      }
    }
  }

  void _submit() async {
    if (kDebugMode) {
      debugPrint('Location submit called with: $_currentLocation');
    }
    
    setState(() {
      _isSubmitting = true;
    });

    // Simulate minimal processing time for UX consistency
    await Future.delayed(const Duration(milliseconds: 200));

    if (_currentLocation != null) {
      if (kDebugMode) {
        debugPrint('Calling onCompleted with location: ${_currentLocation!.city}, ${_currentLocation!.country}');
      }
      // Hand off to coordinator and stop local spinner to avoid indefinite loading
      widget.onCompleted(_currentLocation);
    } else {
      if (kDebugMode) {
        debugPrint('Error: _currentLocation is null, proceeding with skip');
      }
      // If no location is set, treat as skip
      if (widget.onSkipped != null) {
        widget.onSkipped!();
      }
    }
    
    if (mounted) {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  Widget _buildCurrentLocationButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _isLoadingLocation ? null : _getCurrentLocation,
        icon: _isLoadingLocation
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.my_location),
        label: Text(_isLoadingLocation ? 'Getting location...' : 'Use current location'),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.all(16),
          side: BorderSide(color: AppTheme.primaryColor),
          foregroundColor: AppTheme.primaryColor,
        ),
      ),
    );
  }

  Widget _buildManualLocationInput() {
    return Column(
      children: [
        CustomTextField(
          controller: _cityController,
          label: 'City',
          hintText: 'Enter your city',
          prefixIcon: Icons.location_city,
          textCapitalization: TextCapitalization.words,
          onChanged: (_) => setState(() => _locationError = null),
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _countryController,
          label: 'Country',
          hintText: 'Enter your country',
          prefixIcon: Icons.public,
          textCapitalization: TextCapitalization.words,
          onChanged: (_) => setState(() => _locationError = null),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _isLoadingLocation ? null : _searchLocation,
            icon: _isLoadingLocation
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.search),
            label: Text(_isLoadingLocation ? 'Searching...' : 'Search location'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.all(16),
              side: BorderSide(color: AppTheme.primaryColor),
              foregroundColor: AppTheme.primaryColor,
            ),
          ),
        ),
        if (kDebugMode) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              icon: const Icon(Icons.place_outlined),
              label: const Text('Use demo location (San Francisco)'),
              onPressed: _useDemoLocation,
            ),
          ),
        ],
      ],
    );
  }

  void _useDemoLocation() {
    final demo = Location(
      latitude: 37.7749,
      longitude: -122.4194,
      city: 'San Francisco',
      state: 'CA',
      country: 'USA',
      formattedAddress: 'San Francisco, USA',
    );
    setState(() {
      _currentLocation = demo;
      _cityController.text = demo.city;
      _countryController.text = demo.country;
      _locationError = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✓ Demo location set: San Francisco, USA')),
    );
  }

  Widget _buildLocationPreview() {
    if (_currentLocation == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.location_on,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _currentLocation!.city,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _currentLocation!.country,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.check_circle,
                color: Colors.white,
              ),
            ],
          ),
        ],
      ),
    );
  }

  bool get _canProceed => _currentLocation != null;

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
                'Where are you?',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ).animate().fadeIn(delay: 100.ms),
              
              const SizedBox(height: 8),
              
              Text(
                'We\'ll help you find people nearby and show your distance to potential matches.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ).animate().fadeIn(delay: 200.ms),
              
              const SizedBox(height: 32),
              
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildCurrentLocationButton()
                          .animate(delay: 300.ms)
                          .fadeIn()
                          .slideY(begin: 0.2),
                      
                      const SizedBox(height: 24),
                      
                      Row(
                        children: [
                          Expanded(child: Divider(color: Colors.grey.shade300)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'or',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ),
                          Expanded(child: Divider(color: Colors.grey.shade300)),
                        ],
                      ).animate(delay: 400.ms).fadeIn(),
                      
                      const SizedBox(height: 24),
                      
                      _buildManualLocationInput()
                          .animate(delay: 500.ms)
                          .fadeIn()
                          .slideY(begin: 0.2),
                      
                      const SizedBox(height: 24),
                      
                      if (_locationError != null)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: Colors.red.shade700,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _locationError!,
                                  style: TextStyle(
                                    color: Colors.red.shade700,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ).animate().fadeIn().shake(),
                      
                      if (_currentLocation != null) ...[
                        const SizedBox(height: 24),
                        _buildLocationPreview()
                            .animate(delay: 600.ms)
                            .fadeIn()
                            .scale(begin: const Offset(0.9, 0.9)),
                      ],
                      
                      const SizedBox(height: 24),
                      
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.location_off_outlined,
                              color: Colors.orange.shade700,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Having trouble with location?',
                                    style: TextStyle(
                                      color: Colors.orange.shade700,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'You can skip this step and set your location later in Settings.',
                                    style: TextStyle(
                                      color: Colors.orange.shade600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (widget.allowSkip && widget.onSkipped != null)
                              TextButton(
                                onPressed: widget.onSkipped,
                                child: Text(
                                  'Skip',
                                  style: TextStyle(
                                    color: Colors.orange.shade700,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ).animate(delay: 750.ms).fadeIn(),
                    ],
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
                    child: CustomButton(
                      text: _canProceed ? 'Continue' : 'Skip',
                      onPressed: _canProceed 
                          ? _submit 
                          : (widget.allowSkip && widget.onSkipped != null) 
                              ? widget.onSkipped 
                              : null,
                      isLoading: _isSubmitting,
                      isEnabled: true, // Always enable so user can skip
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
