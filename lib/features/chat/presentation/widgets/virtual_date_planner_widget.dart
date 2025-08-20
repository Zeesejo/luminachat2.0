import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/ai_conversation_service.dart';

class VirtualDatePlannerWidget extends StatefulWidget {
  final List<String> commonInterests;
  final String currentMood;
  final Function(Map<String, dynamic>) onDateSelected;

  const VirtualDatePlannerWidget({
    super.key,
    required this.commonInterests,
    required this.currentMood,
    required this.onDateSelected,
  });

  @override
  State<VirtualDatePlannerWidget> createState() => _VirtualDatePlannerWidgetState();
}

class _VirtualDatePlannerWidgetState extends State<VirtualDatePlannerWidget> {
  List<Map<String, dynamic>> _dateIdeas = [];
  bool _isLoading = true;
  String _selectedMood = 'fun';

  @override
  void initState() {
    super.initState();
    _selectedMood = widget.currentMood;
    _loadDateIdeas();
  }

  void _loadDateIdeas() async {
    setState(() => _isLoading = true);
    
    final ideas = await AIConversationService.instance.generateVirtualDateIdeas(
      commonInterests: widget.commonInterests,
      mood: _selectedMood,
    );
    
    setState(() {
      _dateIdeas = ideas;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.purple.shade50,
            Colors.pink.shade50,
          ],
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.purple.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.favorite,
                        color: Colors.purple,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Virtual Date Ideas',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Mood selector
                _buildMoodSelector(),
              ],
            ),
          ),
          
          // Date ideas list
          if (_isLoading)
            const Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 12),
                    Text('Planning perfect dates...', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _dateIdeas.length,
                itemBuilder: (context, index) {
                  final idea = _dateIdeas[index];
                  return _buildDateIdeaCard(idea, index);
                },
              ),
            ),
          
          // Bottom actions
          Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _loadDateIdeas,
                    icon: const Icon(Icons.refresh),
                    label: const Text('More Ideas'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple.withValues(alpha: 0.1),
                      foregroundColor: Colors.purple,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showCustomDateBuilder(context),
                    icon: const Icon(Icons.create),
                    label: const Text('Custom Date'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodSelector() {
    final moods = [
      {'name': 'Fun', 'value': 'fun', 'color': Colors.orange, 'icon': Icons.emoji_emotions},
      {'name': 'Romantic', 'value': 'romantic', 'color': Colors.pink, 'icon': Icons.favorite},
      {'name': 'Cozy', 'value': 'cozy', 'color': Colors.brown, 'icon': Icons.home},
      {'name': 'Exciting', 'value': 'exciting', 'color': Colors.red, 'icon': Icons.flash_on},
      {'name': 'Creative', 'value': 'creative', 'color': Colors.purple, 'icon': Icons.palette},
    ];

    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: moods.length,
        itemBuilder: (context, index) {
          final mood = moods[index];
          final isSelected = _selectedMood == mood['value'];
          
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () {
                setState(() => _selectedMood = mood['value'] as String);
                _loadDateIdeas();
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected 
                    ? (mood['color'] as Color).withValues(alpha: 0.2)
                    : Colors.white.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected 
                      ? mood['color'] as Color
                      : Colors.grey.shade300,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      mood['icon'] as IconData,
                      size: 16,
                      color: isSelected 
                        ? mood['color'] as Color
                        : Colors.grey.shade600,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      mood['name'] as String,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        color: isSelected 
                          ? mood['color'] as Color
                          : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDateIdeaCard(Map<String, dynamic> idea, int index) {
    final moodColor = _getMoodColor(idea['mood'] ?? 'fun');
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => widget.onDateSelected(idea),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF000000).withValues(alpha: 0.1),
                blurRadius: 8,
                spreadRadius: 2,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(color: moodColor.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: moodColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        idea['icon'] ?? '💕',
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          idea['title'] ?? 'Virtual Date',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.schedule, size: 14, color: Colors.grey.shade600),
                            const SizedBox(width: 4),
                            Text(
                              idea['duration'] ?? '1 hour',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: moodColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      idea['mood'] ?? 'fun',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: moodColor,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              Text(
                idea['description'] ?? 'A fun virtual date experience',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                  height: 1.4,
                ),
              ),
              
              const SizedBox(height: 16),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.favorite_border, size: 16, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Text(
                        'Perfect for you two',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: moodColor,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ).animate(delay: (index * 100).ms).slideY(begin: 0.3, end: 0).fadeIn();
  }

  Color _getMoodColor(String mood) {
    switch (mood.toLowerCase()) {
      case 'romantic': return Colors.pink;
      case 'fun': return Colors.orange;
      case 'cozy': return Colors.brown;
      case 'exciting': return Colors.red;
      case 'creative': return Colors.purple;
      case 'cultured': return Colors.blue;
      default: return AppTheme.primaryColor;
    }
  }

  void _showCustomDateBuilder(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Create Custom Date',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(ctx),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            const Text('Coming soon: Build your perfect custom date experience!'),
            
            const SizedBox(height: 20),
            
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Custom date builder coming soon!')),
                );
              },
              child: const Text('Get Notified When Ready'),
            ),
          ],
        ),
      ),
    );
  }
}
