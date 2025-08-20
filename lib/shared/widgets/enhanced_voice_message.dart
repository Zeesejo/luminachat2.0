import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../core/theme/app_theme.dart';
import 'dart:async';

class EnhancedVoiceMessageWidget extends StatefulWidget {
  final String audioPath;
  final Duration duration;
  final bool isCurrentUser;
  final VoidCallback? onPlay;
  final VoidCallback? onPause;
  final VoidCallback? onStop;

  const EnhancedVoiceMessageWidget({
    super.key,
    required this.audioPath,
    required this.duration,
    required this.isCurrentUser,
    this.onPlay,
    this.onPause,
    this.onStop,
  });

  @override
  State<EnhancedVoiceMessageWidget> createState() => _EnhancedVoiceMessageWidgetState();
}

class _EnhancedVoiceMessageWidgetState extends State<EnhancedVoiceMessageWidget>
    with TickerProviderStateMixin {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  bool _isLoading = false;
  Duration _currentPosition = Duration.zero;
  late AnimationController _waveController;
  late AnimationController _playButtonController;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<PlayerState>? _stateSubscription;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _playButtonController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _setupAudioPlayer();
  }

  void _setupAudioPlayer() {
    _positionSubscription = _audioPlayer.onPositionChanged.listen((position) {
      if (mounted) {
        setState(() {
          _currentPosition = position;
        });
      }
    });

    _stateSubscription = _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
          _isLoading = state == PlayerState.stopped && _currentPosition == Duration.zero;
        });

        if (_isPlaying) {
          _waveController.repeat();
          _playButtonController.forward();
        } else {
          _waveController.stop();
          _playButtonController.reverse();
        }
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _waveController.dispose();
    _playButtonController.dispose();
    _positionSubscription?.cancel();
    _stateSubscription?.cancel();
    super.dispose();
  }

  Future<void> _togglePlayPause() async {
    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
        widget.onPause?.call();
      } else {
        if (_currentPosition == Duration.zero) {
          await _audioPlayer.play(UrlSource(widget.audioPath));
        } else {
          await _audioPlayer.resume();
        }
        widget.onPlay?.call();
      }
    } catch (e) {
      debugPrint('Error playing audio: $e');
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    final progress = widget.duration.inMilliseconds > 0
        ? _currentPosition.inMilliseconds / widget.duration.inMilliseconds
        : 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: widget.isCurrentUser
            ? AppTheme.primaryColor.withValues(alpha: 0.1)
            : AppTheme.getCardColor(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: widget.isCurrentUser
              ? AppTheme.primaryColor.withValues(alpha: 0.3)
              : Colors.grey.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Play/Pause Button
          GestureDetector(
            onTap: _isLoading ? null : _togglePlayPause,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: widget.isCurrentUser 
                    ? AppTheme.primaryColor 
                    : AppTheme.secondaryColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (widget.isCurrentUser 
                        ? AppTheme.primaryColor 
                        : AppTheme.secondaryColor).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : AnimatedBuilder(
                      animation: _playButtonController,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: 1.0 + (_playButtonController.value * 0.1),
                          child: Icon(
                            _isPlaying ? Icons.pause : Icons.play_arrow,
                            color: Colors.white,
                            size: 20,
                          ),
                        );
                      },
                    ),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Waveform and Progress
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Animated Waveform
                SizedBox(
                  height: 30,
                  child: _buildAnimatedWaveform(),
                ),
                
                const SizedBox(height: 4),
                
                // Progress Bar
                Stack(
                  children: [
                    Container(
                      height: 3,
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(1.5),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: progress,
                      child: Container(
                        height: 3,
                        decoration: BoxDecoration(
                          color: widget.isCurrentUser 
                              ? AppTheme.primaryColor 
                              : AppTheme.secondaryColor,
                          borderRadius: BorderRadius.circular(1.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Duration
          Text(
            _isPlaying || _currentPosition > Duration.zero
                ? _formatDuration(_currentPosition)
                : _formatDuration(widget.duration),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppTheme.getTextColor(context).withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedWaveform() {
    return AnimatedBuilder(
      animation: _waveController,
      builder: (context, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(20, (index) {
            final baseHeight = 4.0 + (index % 3) * 3.0;
            final animationProgress = (_waveController.value - (index * 0.05)) % 1.0;
            final height = _isPlaying 
                ? baseHeight + (animationProgress * 15) 
                : baseHeight;
            
            return Container(
              width: 2,
              height: height,
              decoration: BoxDecoration(
                color: (widget.isCurrentUser 
                    ? AppTheme.primaryColor 
                    : AppTheme.secondaryColor).withValues(
                  alpha: _isPlaying ? 0.8 : 0.4,
                ),
                borderRadius: BorderRadius.circular(1),
              ),
            );
          }),
        );
      },
    );
  }
}

// Voice Recording Widget
class VoiceRecordingWidget extends StatefulWidget {
  final VoidCallback onStartRecording;
  final VoidCallback onStopRecording;
  final VoidCallback onCancelRecording;
  final bool isRecording;
  final Duration recordingDuration;

  const VoiceRecordingWidget({
    super.key,
    required this.onStartRecording,
    required this.onStopRecording,
    required this.onCancelRecording,
    required this.isRecording,
    required this.recordingDuration,
  });

  @override
  State<VoiceRecordingWidget> createState() => _VoiceRecordingWidgetState();
}

class _VoiceRecordingWidgetState extends State<VoiceRecordingWidget>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _slideController;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOut,
    ));
  }

  @override
  void didUpdateWidget(VoiceRecordingWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRecording && !oldWidget.isRecording) {
      _slideController.forward();
      _pulseController.repeat(reverse: true);
    } else if (!widget.isRecording && oldWidget.isRecording) {
      _slideController.reverse();
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isRecording) {
      return GestureDetector(
        onTap: widget.onStartRecording,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(
            Icons.mic,
            color: Colors.white,
            size: 20,
          ),
        ),
      );
    }

    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.getCardColor(context),
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Cancel button
            GestureDetector(
              onTap: widget.onCancelRecording,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.close,
                  color: AppTheme.errorColor,
                  size: 16,
                ),
              ),
            ),
            
            const SizedBox(width: 12),
            
            // Recording indicator
            ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: AppTheme.errorColor,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            
            const SizedBox(width: 8),
            
            // Recording text and duration
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recording...',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.getTextColor(context),
                    ),
                  ),
                  Text(
                    _formatDuration(widget.recordingDuration),
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.getTextColor(context).withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            
            // Stop and send button
            GestureDetector(
              onTap: widget.onStopRecording,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.send,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
