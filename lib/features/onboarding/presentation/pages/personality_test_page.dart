import 'package:flutter/material.dart';
import '../../../../shared/models/user_model.dart';

class PersonalityTestPage extends StatefulWidget {
  final MBTIType? initialPersonalityType;
  final Function(MBTIType) onCompleted;
  final VoidCallback onSkipped;
  final VoidCallback onBack;
  final bool allowSkip;

  const PersonalityTestPage({
    Key? key,
    this.initialPersonalityType,
    required this.onCompleted,
    required this.onSkipped,
    required this.onBack,
    this.allowSkip = true,
  }) : super(key: key);

  @override
  _PersonalityTestPageState createState() => _PersonalityTestPageState();
}

class _PersonalityTestPageState extends State<PersonalityTestPage> {
  int currentQuestionIndex = 0;
  Map<String, int> scores = {
    'E': 0, 'I': 0, // Extraversion vs Introversion
    'S': 0, 'N': 0, // Sensing vs Intuition
    'T': 0, 'F': 0, // Thinking vs Feeling
    'J': 0, 'P': 0, // Judging vs Perceiving
  };

  final List<Map<String, dynamic>> questions = [
    {
      'question': 'You feel energized by:',
      'options': [
        {'text': 'Being around people and social activities', 'scores': {'E': 2}},
        {'text': 'Spending time alone or with close friends', 'scores': {'I': 2}},
      ]
    },
    {
      'question': 'When making decisions, you:',
      'options': [
        {'text': 'Focus on facts and logical analysis', 'scores': {'T': 2}},
        {'text': 'Consider how it affects people and values', 'scores': {'F': 2}},
      ]
    },
    {
      'question': 'You prefer to:',
      'options': [
        {'text': 'Have things planned and organized', 'scores': {'J': 2}},
        {'text': 'Keep options open and be flexible', 'scores': {'P': 2}},
      ]
    },
    {
      'question': 'When learning new things, you:',
      'options': [
        {'text': 'Focus on details and practical applications', 'scores': {'S': 2}},
        {'text': 'Look for patterns and future possibilities', 'scores': {'N': 2}},
      ]
    },
    {
      'question': 'At parties, you:',
      'options': [
        {'text': 'Enjoy meeting new people and mingling', 'scores': {'E': 2}},
        {'text': 'Prefer talking with people you already know', 'scores': {'I': 2}},
      ]
    },
    {
      'question': 'You trust information that is:',
      'options': [
        {'text': 'Concrete and can be verified by experience', 'scores': {'S': 2}},
        {'text': 'Theoretical and points to future possibilities', 'scores': {'N': 2}},
      ]
    },
    {
      'question': 'When someone is upset, you:',
      'options': [
        {'text': 'Try to help them solve the problem logically', 'scores': {'T': 2}},
        {'text': 'Offer emotional support and understanding', 'scores': {'F': 2}},
      ]
    },
    {
      'question': 'You prefer your daily life to be:',
      'options': [
        {'text': 'Structured with clear schedules', 'scores': {'J': 2}},
        {'text': 'Spontaneous and adaptable', 'scores': {'P': 2}},
      ]
    },
  ];

  @override
  void initState() {
    super.initState();
    
    // If we have an initial personality type, skip the test
    if (widget.initialPersonalityType != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onCompleted(widget.initialPersonalityType!);
      });
    }
  }

  void _answerQuestion(Map<String, int> selectedScores) {
    setState(() {
      selectedScores.forEach((key, value) {
        scores[key] = scores[key]! + value;
      });

      if (currentQuestionIndex < questions.length - 1) {
        currentQuestionIndex++;
      } else {
        _showResults();
      }
    });
  }

  void _showResults() {
    String personalityTypeString = '';
    personalityTypeString += scores['E']! > scores['I']! ? 'E' : 'I';
    personalityTypeString += scores['S']! > scores['N']! ? 'S' : 'N';
    personalityTypeString += scores['T']! > scores['F']! ? 'T' : 'F';
    personalityTypeString += scores['J']! > scores['P']! ? 'J' : 'P';

    MBTIType? personalityType = _getMBTIType(personalityTypeString);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Your Personality Type'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).primaryColor,
                      Theme.of(context).primaryColor.withValues(alpha: 0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      personalityType?.name.toUpperCase() ?? personalityTypeString,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      personalityType?.title ?? _getPersonalityTitle(personalityTypeString),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _getPersonalityDescription(personalityTypeString),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                widget.onCompleted(personalityType!);
              },
              child: const Text('Continue'),
            ),
          ],
        );
      },
    );
  }

  MBTIType? _getMBTIType(String typeString) {
    switch (typeString.toLowerCase()) {
      case 'intj': return MBTIType.intj;
      case 'intp': return MBTIType.intp;
      case 'entj': return MBTIType.entj;
      case 'entp': return MBTIType.entp;
      case 'infj': return MBTIType.infj;
      case 'infp': return MBTIType.infp;
      case 'enfj': return MBTIType.enfj;
      case 'enfp': return MBTIType.enfp;
      case 'istj': return MBTIType.istj;
      case 'isfj': return MBTIType.isfj;
      case 'estj': return MBTIType.estj;
      case 'esfj': return MBTIType.esfj;
      case 'istp': return MBTIType.istp;
      case 'isfp': return MBTIType.isfp;
      case 'estp': return MBTIType.estp;
      case 'esfp': return MBTIType.esfp;
      default: return null;
    }
  }

  String _getPersonalityTitle(String type) {
    switch (type.toLowerCase()) {
      case 'intj': return 'The Architect';
      case 'intp': return 'The Logician';
      case 'entj': return 'The Commander';
      case 'entp': return 'The Debater';
      case 'infj': return 'The Advocate';
      case 'infp': return 'The Mediator';
      case 'enfj': return 'The Protagonist';
      case 'enfp': return 'The Campaigner';
      case 'istj': return 'The Logistician';
      case 'isfj': return 'The Protector';
      case 'estj': return 'The Executive';
      case 'esfj': return 'The Consul';
      case 'istp': return 'The Virtuoso';
      case 'isfp': return 'The Adventurer';
      case 'estp': return 'The Entrepreneur';
      case 'esfp': return 'The Entertainer';
      default: return 'Unknown Type';
    }
  }

  String _getPersonalityDescription(String type) {
    switch (type.toLowerCase()) {
      case 'intj': return 'Imaginative and strategic thinkers, with a plan for everything.';
      case 'intp': return 'Innovative inventors with an unquenchable thirst for knowledge.';
      case 'entj': return 'Bold, imaginative and strong-willed leaders.';
      case 'entp': return 'Smart and curious thinkers who cannot resist an intellectual challenge.';
      case 'infj': return 'Quiet and mystical, yet very inspiring and tireless idealists.';
      case 'infp': return 'Poetic, kind and altruistic people, always eager to help a good cause.';
      case 'enfj': return 'Charismatic and inspiring leaders, able to mesmerize their listeners.';
      case 'enfp': return 'Enthusiastic, creative and sociable free spirits.';
      case 'istj': return 'Practical and fact-minded, reliable and responsible.';
      case 'isfj': return 'Very dedicated and warm protectors, always ready to defend their loved ones.';
      case 'estj': return 'Excellent administrators, unsurpassed at managing things or people.';
      case 'esfj': return 'Extraordinarily caring, social and popular people, always eager to help.';
      case 'istp': return 'Bold and practical experimenters, masters of all kinds of tools.';
      case 'isfp': return 'Flexible and charming artists, always ready to explore new possibilities.';
      case 'estp': return 'Smart, energetic and very perceptive people, who truly enjoy living on the edge.';
      case 'esfp': return 'Spontaneous, enthusiastic and friendly people - life is never boring around them.';
      default: return 'A unique personality type with their own strengths and characteristics.';
    }
  }

  @override
  Widget build(BuildContext context) {
    // If we already have the personality type, show loading while we complete
    if (widget.initialPersonalityType != null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final currentQuestion = questions[currentQuestionIndex];
    final progress = (currentQuestionIndex + 1) / questions.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Personality Test'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBack,
        ),
        actions: widget.allowSkip ? [
          TextButton(
            onPressed: widget.onSkipped,
            child: const Text('Skip'),
          ),
        ] : null,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress indicator
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Question ${currentQuestionIndex + 1} of ${questions.length}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Question
            Text(
              currentQuestion['question'],
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 32),

            // Options
            Expanded(
              child: ListView.builder(
                itemCount: currentQuestion['options'].length,
                itemBuilder: (context, index) {
                  final option = currentQuestion['options'][index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Card(
                      elevation: 2,
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        title: Text(
                          option['text'],
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        onTap: () => _answerQuestion(option['scores']),
                        trailing: Icon(
                          Icons.arrow_forward_ios,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
