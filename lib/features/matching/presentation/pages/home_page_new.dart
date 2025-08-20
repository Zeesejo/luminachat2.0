import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/services/matching_service.dart';
import '../../../../core/utils/exceptions.dart';
import '../../../../shared/models/match_model.dart';
import '../../../../shared/widgets/loading_overlay.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage>
    with TickerProviderStateMixin {
  late AnimationController _cardController;
  late AnimationController _likeController;
  late AnimationController _passController;
  
  List<MatchModel> _potentialMatches = [];
  int _currentCardIndex = 0;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cardController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _likeController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _passController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _loadPotentialMatches();
  }

  @override
  void dispose() {
    _cardController.dispose();
    _likeController.dispose();
    _passController.dispose();
    super.dispose();
  }

  Future<void> _loadPotentialMatches() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw const AppException('No authenticated user');
      }

      final matchingService = ref.read(matchingServiceProvider);
      final matches = await matchingService.findPotentialMatches(
        userId: currentUser.uid,
        limit: 20,
      );

      setState(() {
        _potentialMatches = matches;
        _currentCardIndex = 0;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _onSwipe(bool isLike) async {
    if (_currentCardIndex >= _potentialMatches.length) return;
    
    // TODO: Send like/pass to backend
    
    setState(() {
      _currentCardIndex++;
    });

    if (isLike) {
      await _likeController.forward();
      _likeController.reset();
    } else {
      await _passController.forward();
      _passController.reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Discover',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: () {
              // TODO: Show filters
            },
          ),
        ],
      ),
      body: _isLoading 
        ? const LoadingOverlay(isLoading: true, child: SizedBox())
        : _error != null
          ? _buildErrorView()
          : _currentCardIndex >= _potentialMatches.length
            ? _buildNoMoreCardsView()
            : _buildCardStack(),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(_error ?? 'An error occurred'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadPotentialMatches,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildNoMoreCardsView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.favorite, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'No more profiles',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Check back later for new matches!',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadPotentialMatches,
            child: const Text('Refresh'),
          ),
        ],
      ),
    );
  }

  Widget _buildCardStack() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                // Show multiple cards for depth effect
                for (int i = _currentCardIndex + 2; i >= _currentCardIndex; i--)
                  if (i < _potentialMatches.length)
                    Positioned(
                      top: (i - _currentCardIndex) * 4.0,
                      left: (i - _currentCardIndex) * 2.0,
                      right: (i - _currentCardIndex) * 2.0,
                      bottom: (i - _currentCardIndex) * 4.0,
                      child: _buildMatchCard(_potentialMatches[i], i == _currentCardIndex),
                    ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        FloatingActionButton(
          heroTag: 'pass',
          backgroundColor: Colors.grey.shade300,
          onPressed: () => _onSwipe(false),
          child: const Icon(Icons.close, color: Colors.white),
        ),
        FloatingActionButton(
          heroTag: 'like',
          backgroundColor: Colors.red,
          onPressed: () => _onSwipe(true),
          child: const Icon(Icons.favorite, color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildMatchCard(MatchModel match, bool isActive) {
    return Card(
      elevation: isActive ? 8 : 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Background image placeholder
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.blue.shade300,
                    Colors.purple.shade300,
                  ],
                ),
              ),
            ),
            // Content overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.7),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Match ${match.userId2}', // This would normally be user name
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${match.compatibilityScore.toInt()}% Match',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Common interests: ${match.commonInterests.take(3).join(', ')}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Provider for MatchingService
final matchingServiceProvider = Provider<MatchingService>((ref) {
  return MatchingService();
});
