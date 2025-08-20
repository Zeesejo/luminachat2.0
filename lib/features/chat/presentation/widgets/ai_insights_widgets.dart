import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/ai_conversation_service.dart';

class CompatibilityInsightsWidget extends StatefulWidget {
  final String userPersonality;
  final List<String> userInterests;
  final String partnerPersonality;
  final List<String> partnerInterests;

  const CompatibilityInsightsWidget({
    super.key,
    required this.userPersonality,
    required this.userInterests,
    required this.partnerPersonality,
    required this.partnerInterests,
  });

  @override
  State<CompatibilityInsightsWidget> createState() => _CompatibilityInsightsWidgetState();
}

class _CompatibilityInsightsWidgetState extends State<CompatibilityInsightsWidget> {
  Map<String, dynamic>? _insights;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInsights();
  }

  void _loadInsights() async {
    final insights = AIConversationService.instance.generateCompatibilityInsights(
      userPersonality: widget.userPersonality,
      userInterests: widget.userInterests,
      partnerPersonality: widget.partnerPersonality,
      partnerInterests: widget.partnerInterests,
    );
    
    setState(() {
      _insights = insights;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.all(20),
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF000000).withValues(alpha: 0.1),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 12),
              Text('Analyzing compatibility...', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    if (_insights == null) return const SizedBox.shrink();

    final score = _insights!['score'] as double;
    final insights = _insights!['insights'] as List<String>;
    final recommendation = _insights!['recommendation'] as String;

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
  gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor.withValues(alpha: 0.1),
            AppTheme.primaryColor.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
  border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.psychology,
                    color: AppTheme.primaryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Compatibility Insights',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Compatibility Score
            _buildCompatibilityScore(score),
            
            const SizedBox(height: 20),
            
            // Insights List
            ...insights.map((insight) => _buildInsightItem(insight)),
            
            const SizedBox(height: 16),
            
            // Recommendation
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.successColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.successColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    color: AppTheme.successColor,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      recommendation,
                      style: TextStyle(
                        color: AppTheme.successColor.withValues(alpha: 0.8),
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.3, end: 0);
  }

  Widget _buildCompatibilityScore(double score) {
    final color = score > 80 
      ? AppTheme.successColor
      : score > 60 
        ? Colors.orange
        : score > 40
          ? Colors.blue
          : Colors.grey;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
  color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
  border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          // Circular progress indicator
          SizedBox(
            width: 60,
            height: 60,
            child: Stack(
              children: [
                CircularProgressIndicator(
                  value: score / 100,
                  strokeWidth: 6,
                  backgroundColor: color.withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
                Center(
                  child: Text(
                    '${score.toInt()}%',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(width: 20),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Compatibility Score',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getScoreDescription(score),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightItem(String insight) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              insight,
              style: const TextStyle(
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getScoreDescription(double score) {
    if (score > 80) {
      return 'Exceptional compatibility!';
    } else if (score > 60) {
      return 'Great potential together';
    } else if (score > 40) {
      return 'Interesting connection';
    } else {
      return 'Different but intriguing';
    }
  }
}

class ConversationStartersWidget extends StatefulWidget {
  final String userPersonality;
  final List<String> userInterests;
  final String partnerPersonality;
  final List<String> partnerInterests;
  final Function(String) onStarterSelected;

  const ConversationStartersWidget({
    super.key,
    required this.userPersonality,
    required this.userInterests,
    required this.partnerPersonality,
    required this.partnerInterests,
    required this.onStarterSelected,
  });

  @override
  State<ConversationStartersWidget> createState() => _ConversationStartersWidgetState();
}

class _ConversationStartersWidgetState extends State<ConversationStartersWidget> {
  List<String> _starters = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStarters();
  }

  void _loadStarters() async {
    final starters = await AIConversationService.instance.generateConversationStarters(
      userPersonality: widget.userPersonality,
      userInterests: widget.userInterests,
      partnerPersonality: widget.partnerPersonality,
      partnerInterests: widget.partnerInterests,
    );
    
    setState(() {
      _starters = starters;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.all(20),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 12),
              Text('Generating conversation starters...', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.chat_bubble_outline,
                color: AppTheme.primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'AI Conversation Starters',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          ..._starters.asMap().entries.map((entry) {
            final index = entry.key;
            final starter = entry.value;
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () => widget.onStarterSelected(starter),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.1)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          starter,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 12,
                        color: AppTheme.primaryColor.withValues(alpha: 0.5),
                      ),
                    ],
                  ),
                ),
              ),
            ).animate(delay: (index * 100).ms).slideX(begin: -0.3, end: 0).fadeIn();
          }),
          
          const SizedBox(height: 8),
          
          Center(
            child: TextButton.icon(
              onPressed: _loadStarters,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Generate New Starters'),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
