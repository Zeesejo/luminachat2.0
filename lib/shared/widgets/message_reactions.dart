import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';

class MessageReactionsWidget extends StatefulWidget {
  final String messageId;
  final Map<String, List<String>> reactions; // emoji -> list of user IDs
  final String currentUserId;
  final Function(String emoji) onReactionAdded;
  final Function(String emoji) onReactionRemoved;

  const MessageReactionsWidget({
    super.key,
    required this.messageId,
    required this.reactions,
    required this.currentUserId,
    required this.onReactionAdded,
    required this.onReactionRemoved,
  });

  @override
  State<MessageReactionsWidget> createState() => _MessageReactionsWidgetState();
}

class _MessageReactionsWidgetState extends State<MessageReactionsWidget> {
  final List<String> _quickReactions = ['❤️', '😂', '😮', '😢', '😡', '👍'];
  bool _showAllReactions = false;

  @override
  Widget build(BuildContext context) {
    final existingReactions = widget.reactions.entries
        .where((entry) => entry.value.isNotEmpty)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Existing reactions
        if (existingReactions.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: existingReactions.map((entry) {
              final emoji = entry.key;
              final users = entry.value;
              final hasCurrentUser = users.contains(widget.currentUserId);
              
              return GestureDetector(
                onTap: () {
                  if (hasCurrentUser) {
                    widget.onReactionRemoved(emoji);
                  } else {
                    widget.onReactionAdded(emoji);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: hasCurrentUser 
                        ? AppTheme.primaryColor.withValues(alpha: 0.2)
                        : AppTheme.getCardColor(context),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: hasCurrentUser 
                          ? AppTheme.primaryColor 
                          : Colors.grey.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(emoji, style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 4),
                      Text(
                        '${users.length}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: hasCurrentUser 
                              ? AppTheme.primaryColor 
                              : AppTheme.getTextColor(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate().scale(
                begin: const Offset(0.8, 0.8),
                duration: 200.ms,
                curve: Curves.easeOut,
              );
            }).toList(),
          ),
        
        // Quick reaction buttons
        if (_showAllReactions)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.getCardColor(context),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'React to this message',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.getTextColor(context),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _quickReactions.map((emoji) {
                    final isSelected = widget.reactions[emoji]?.contains(widget.currentUserId) ?? false;
                    
                    return GestureDetector(
                      onTap: () {
                        if (isSelected) {
                          widget.onReactionRemoved(emoji);
                        } else {
                          widget.onReactionAdded(emoji);
                        }
                        setState(() {
                          _showAllReactions = false;
                        });
                      },
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: isSelected 
                              ? AppTheme.primaryColor.withValues(alpha: 0.2)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: isSelected 
                                ? AppTheme.primaryColor 
                                : Colors.grey.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            emoji,
                            style: const TextStyle(fontSize: 20),
                          ),
                        ),
                      ),
                    ).animate().scale(
                      begin: const Offset(0.5, 0.5),
                      duration: (100 + (_quickReactions.indexOf(emoji) * 50)).ms,
                      curve: Curves.elasticOut,
                    );
                  }).toList(),
                ),
              ],
            ),
          ).animate().slideY(
            begin: 0.5,
            duration: 300.ms,
            curve: Curves.easeOut,
          ).fadeIn(),
      ],
    );
  }

  void showReactionPicker() {
    setState(() {
      _showAllReactions = !_showAllReactions;
    });
  }
}

class MessageReactionButton extends StatelessWidget {
  final VoidCallback onTap;

  const MessageReactionButton({
    super.key,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.getCardColor(context),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          Icons.add_reaction_outlined,
          size: 18,
          color: AppTheme.getTextColor(context).withValues(alpha: 0.7),
        ),
      ),
    ).animate().scale(
      begin: const Offset(0.8, 0.8),
      duration: 200.ms,
      curve: Curves.easeOut,
    );
  }
}

// Reaction animation widget for floating reactions
class FloatingReactionWidget extends StatefulWidget {
  final String emoji;
  final Offset startPosition;

  const FloatingReactionWidget({
    super.key,
    required this.emoji,
    required this.startPosition,
  });

  @override
  State<FloatingReactionWidget> createState() => _FloatingReactionWidgetState();
}

class _FloatingReactionWidgetState extends State<FloatingReactionWidget> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _positionAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
    ));

    _positionAnimation = Tween<Offset>(
      begin: widget.startPosition,
      end: Offset(widget.startPosition.dx + 50, widget.startPosition.dy - 100),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
    ));

    _opacityAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.7, 1.0, curve: Curves.easeOut),
    ));

    _controller.forward().then((_) {
      if (mounted) {
        // Remove this widget from the tree
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Positioned(
          left: _positionAnimation.value.dx,
          top: _positionAnimation.value.dy,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Opacity(
              opacity: _opacityAnimation.value,
              child: Text(
                widget.emoji,
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),
        );
      },
    );
  }
}
