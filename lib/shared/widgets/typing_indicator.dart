import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';

class TypingIndicatorWidget extends StatefulWidget {
  final String userName;
  final bool isVisible;

  const TypingIndicatorWidget({
    super.key,
    required this.userName,
    required this.isVisible,
  });

  @override
  State<TypingIndicatorWidget> createState() => _TypingIndicatorWidgetState();
}

class _TypingIndicatorWidgetState extends State<TypingIndicatorWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    if (widget.isVisible) {
      _startAnimations();
    }
  }

  @override
  void didUpdateWidget(TypingIndicatorWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible && !oldWidget.isVisible) {
      _startAnimations();
    } else if (!widget.isVisible && oldWidget.isVisible) {
      _stopAnimations();
    }
  }

  void _startAnimations() {
    _scaleController.forward();
    _animationController.repeat();
  }

  void _stopAnimations() {
    _scaleController.reverse();
    _animationController.stop();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) {
      return const SizedBox.shrink();
    }

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.getCardColor(context),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 12,
              backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.2),
              child: Text(
                widget.userName.isNotEmpty ? widget.userName[0].toUpperCase() : '?',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '${widget.userName} is typing',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.getTextColor(context).withValues(alpha: 0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
            _buildTypingDots(),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingDots() {
    return SizedBox(
      width: 24,
      height: 16,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(3, (index) {
              final delay = index * 0.15;
              final progress = (_animationController.value - delay).clamp(0.0, 1.0);
              final opacity = (progress < 0.5) 
                  ? (progress * 2) 
                  : (2 - progress * 2);
              
              return Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: opacity.clamp(0.3, 1.0)),
                  shape: BoxShape.circle,
                ),
              );
            }),
          );
        },
      ),
    );
  }
}

class EnhancedTypingIndicator extends StatelessWidget {
  final Map<String, String> typingUsers; // userId -> userName
  final int maxVisible;

  const EnhancedTypingIndicator({
    super.key,
    required this.typingUsers,
    this.maxVisible = 3,
  });

  @override
  Widget build(BuildContext context) {
    if (typingUsers.isEmpty) {
      return const SizedBox.shrink();
    }

    final visibleUsers = typingUsers.entries.take(maxVisible).toList();
    final additionalCount = typingUsers.length - maxVisible;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          ...visibleUsers.map((entry) => TypingIndicatorWidget(
            userName: entry.value,
            isVisible: true,
          )),
          if (additionalCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              margin: const EdgeInsets.only(top: 4),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'and $additionalCount more ${additionalCount == 1 ? 'person is' : 'people are'} typing...',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ).animate().fadeIn(duration: 300.ms),
        ],
      ),
    );
  }
}

// Widget for showing typing status in chat list
class ChatListTypingIndicator extends StatelessWidget {
  final bool isTyping;
  final String typingUserName;

  const ChatListTypingIndicator({
    super.key,
    required this.isTyping,
    this.typingUserName = '',
  });

  @override
  Widget build(BuildContext context) {
    if (!isTyping) {
      return const SizedBox.shrink();
    }

    return Row(
      children: [
        _buildMiniTypingDots(),
        const SizedBox(width: 4),
        Text(
          typingUserName.isNotEmpty ? '$typingUserName is typing' : 'Typing...',
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.w500,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    ).animate().fadeIn(duration: 200.ms);
  }

  Widget _buildMiniTypingDots() {
    return SizedBox(
      width: 16,
      height: 12,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(3, (index) {
          return Container(
            width: 3,
            height: 3,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              shape: BoxShape.circle,
            ),
          ).animate(onPlay: (controller) => controller.repeat())
            .scale(
              begin: const Offset(0.5, 0.5),
              end: const Offset(1.2, 1.2),
              duration: 600.ms,
              delay: (index * 200).ms,
              curve: Curves.easeInOut,
            );
        }),
      ),
    );
  }
}
