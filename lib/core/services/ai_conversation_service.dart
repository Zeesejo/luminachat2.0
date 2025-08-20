import 'dart:async';
import 'dart:math';

class AIConversationService {
  static final AIConversationService _instance = AIConversationService._internal();
  factory AIConversationService() => _instance;
  AIConversationService._internal();

  static AIConversationService get instance => _instance;

  // Simulated AI conversation starters based on personality and interests
  Future<List<String>> generateConversationStarters({
    required String userPersonality,
    required List<String> userInterests,
    required String partnerPersonality,
    required List<String> partnerInterests,
  }) async {
    // Simulate AI processing delay
    await Future.delayed(const Duration(milliseconds: 800));

    final commonInterests = userInterests.where((interest) => 
      partnerInterests.contains(interest)).toList();

    final starters = <String>[];
    final random = Random();

    // Personality-based starters
    if (userPersonality.contains('Extrovert') && partnerPersonality.contains('Extrovert')) {
      starters.addAll([
        "I love how energetic you seem! What's the most spontaneous thing you've done recently?",
        "Your vibe is amazing! Want to plan an adventure together?",
        "I can tell you're a people person like me! What's your favorite social activity?",
      ]);
    }

    if (userPersonality.contains('Introvert') && partnerPersonality.contains('Introvert')) {
      starters.addAll([
        "I appreciate deep conversations. What's something you've been thinking about lately?",
        "Your thoughtful nature really shows. What's your favorite way to recharge?",
        "I love meaningful connections. What's a book or movie that changed your perspective?",
      ]);
    }

    // Interest-based starters
    if (commonInterests.contains('Travel')) {
      starters.addAll([
        "I see we both love travel! What's the most beautiful place you've ever been?",
        "Your travel photos are amazing! What's next on your bucket list?",
        "We should swap travel stories! What's your most memorable trip?",
      ]);
    }

    if (commonInterests.contains('Music')) {
      starters.addAll([
        "Music lovers unite! What song gives you instant goosebumps?",
        "I notice we have similar music taste. Any concert recommendations?",
        "What's the soundtrack to your life right now?",
      ]);
    }

    if (commonInterests.contains('Fitness')) {
      starters.addAll([
        "Fitness buddy! What's your favorite way to stay active?",
        "I love your dedication to health! Want to be workout accountability partners?",
        "What's your go-to post-workout meal?",
      ]);
    }

    if (commonInterests.contains('Food')) {
      starters.addAll([
        "Fellow foodie! What's the best meal you've had recently?",
        "I see you love good food too! Want to explore new restaurants together?",
        "What's your signature dish? Maybe you can teach me sometime!",
      ]);
    }

    // Default creative starters if no specific matches
    if (starters.isEmpty) {
      starters.addAll([
        "Your profile caught my eye! What's something unique about you that most people don't know?",
        "I'm intrigued by your interests! What's your current passion project?",
        "You seem like someone with great stories. What's been the highlight of your week?",
        "I love your energy! What's something that always makes you smile?",
      ]);
    }

    // Shuffle and return top 3-5 suggestions
    starters.shuffle(random);
    return starters.take(5).toList();
  }

  // Generate mood-based conversation topics
  Future<List<String>> getMoodBasedTopics(String mood) async {
    await Future.delayed(const Duration(milliseconds: 500));

    switch (mood.toLowerCase()) {
      case 'excited':
        return [
          "What's got you excited lately?",
          "Share your latest adventure with me!",
          "What's the next big thing you're looking forward to?",
        ];
      
      case 'relaxed':
        return [
          "What's your perfect chill day like?",
          "Any good books or shows you'd recommend?",
          "How do you like to unwind after a long day?",
        ];
      
      case 'creative':
        return [
          "What project are you working on right now?",
          "Where do you find your inspiration?",
          "What's the most creative thing you've done recently?",
        ];
      
      case 'adventurous':
        return [
          "What's the most thrilling experience you've had?",
          "Any bucket list items you're dying to try?",
          "Want to plan an adventure together?",
        ];
      
      default:
        return [
          "How's your day going so far?",
          "What's been on your mind lately?",
          "Tell me something that made you happy today!",
        ];
    }
  }

  // Compatibility insights based on personalities
  Map<String, dynamic> generateCompatibilityInsights({
    required String userPersonality,
    required List<String> userInterests,
    required String partnerPersonality,
    required List<String> partnerInterests,
  }) {
    final commonInterests = userInterests.where((interest) => 
      partnerInterests.contains(interest)).toList();

    double compatibilityScore = 0.0;
    final insights = <String>[];

    // Interest compatibility (40% of score)
    final interestScore = (commonInterests.length / userInterests.length) * 40;
    compatibilityScore += interestScore;

    if (commonInterests.isNotEmpty) {
      insights.add("🎯 You share ${commonInterests.length} common interests: ${commonInterests.join(', ')}");
    }

    // Personality compatibility (60% of score)
    final personalityScore = _calculatePersonalityCompatibility(userPersonality, partnerPersonality);
    compatibilityScore += personalityScore * 60;

    if (userPersonality.contains('Extrovert') && partnerPersonality.contains('Introvert')) {
      insights.add("⚖️ Great balance: Your outgoing nature complements their thoughtful approach");
    } else if (userPersonality.contains('Introvert') && partnerPersonality.contains('Extrovert')) {
      insights.add("⚖️ Perfect match: Their energy can bring out your adventurous side");
    } else if (userPersonality.contains('Extrovert') && partnerPersonality.contains('Extrovert')) {
      insights.add("🔥 Double energy: You both love excitement and new experiences");
    } else {
      insights.add("🧘 Deep connection potential: You both value meaningful conversations");
    }

    // Add specific compatibility insights
    if (compatibilityScore > 80) {
      insights.add("💫 Exceptional match! You have incredible potential together");
    } else if (compatibilityScore > 60) {
      insights.add("✨ Great compatibility with room for beautiful growth");
    } else if (compatibilityScore > 40) {
      insights.add("🌱 Interesting differences that could lead to growth");
    }

    return {
      'score': compatibilityScore.clamp(0, 100),
      'insights': insights,
      'commonInterests': commonInterests,
      'recommendation': _getRelationshipRecommendation(compatibilityScore),
    };
  }

  double _calculatePersonalityCompatibility(String user, String partner) {
    // Simplified compatibility calculation
    // In a real app, this would use more sophisticated personality matching
    if ((user.contains('Extrovert') && partner.contains('Introvert')) ||
        (user.contains('Introvert') && partner.contains('Extrovert'))) {
      return 0.9; // Opposites attract
    }
    
    if ((user.contains('Extrovert') && partner.contains('Extrovert')) ||
        (user.contains('Introvert') && partner.contains('Introvert'))) {
      return 0.7; // Similar personalities
    }
    
    return 0.6; // Default compatibility
  }

  String _getRelationshipRecommendation(double score) {
    if (score > 80) {
      return "This connection has amazing potential! Focus on your common interests and embrace your differences.";
    } else if (score > 60) {
      return "Great foundation for a connection! Take time to explore each other's interests.";
    } else if (score > 40) {
      return "Interesting match! Your differences could lead to personal growth and new experiences.";
    } else {
      return "Every connection teaches us something. Be open to learning from each other!";
    }
  }

  // Generate virtual date ideas based on common interests
  Future<List<Map<String, dynamic>>> generateVirtualDateIdeas({
    required List<String> commonInterests,
    required String mood,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));

    final dateIdeas = <Map<String, dynamic>>[];
    
    if (commonInterests.contains('Movies')) {
      dateIdeas.add({
        'title': 'Virtual Movie Night',
        'description': 'Watch a movie together online and video chat during it',
        'duration': '2-3 hours',
        'mood': 'cozy',
        'icon': '🍿',
      });
    }

    if (commonInterests.contains('Cooking')) {
      dateIdeas.add({
        'title': 'Cook Together Challenge',
        'description': 'Choose the same recipe and cook together over video call',
        'duration': '1-2 hours',
        'mood': 'fun',
        'icon': '👨‍🍳',
      });
    }

    if (commonInterests.contains('Music')) {
      dateIdeas.add({
        'title': 'Virtual Concert Experience',
        'description': 'Share favorite songs and create playlists together',
        'duration': '1 hour',
        'mood': 'romantic',
        'icon': '🎵',
      });
    }

    if (commonInterests.contains('Games')) {
      dateIdeas.add({
        'title': 'Online Game Tournament',
        'description': 'Play online games together - from trivia to multiplayer adventures',
        'duration': '1-3 hours',
        'mood': 'playful',
        'icon': '🎮',
      });
    }

    // Default creative ideas
    dateIdeas.addAll([
      {
        'title': 'Virtual Art Gallery Tour',
        'description': 'Explore famous museums online together and discuss your favorites',
        'duration': '1 hour',
        'mood': 'cultured',
        'icon': '🎨',
      },
      {
        'title': 'Sunrise/Sunset Watch',
        'description': 'Watch the sunrise or sunset together from your locations',
        'duration': '30 minutes',
        'mood': 'romantic',
        'icon': '🌅',
      },
      {
        'title': 'Virtual Travel Planning',
        'description': 'Plan a future trip together using travel websites and apps',
        'duration': '1-2 hours',
        'mood': 'exciting',
        'icon': '✈️',
      },
    ]);

    return dateIdeas.take(4).toList();
  }
}
