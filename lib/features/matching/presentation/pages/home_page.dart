import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../core/config/environment.dart';
import '../../../../core/services/matching_service.dart';
import '../../../../core/utils/exceptions.dart';
import '../../../../shared/models/match_model.dart';
import '../../../../shared/widgets/loading_overlay.dart';
import '../../../../core/services/user_service.dart';
import '../../../../shared/models/user_model.dart';

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

  // Swipe interaction state
  Offset _cardOffset = Offset.zero;
  double _cardRotation = 0; // radians
  // Removed unused dragging flag to silence analyzer
  bool _actionInProgress = false;
  String? _currentUserId;

  // Cache profiles for rendering (name/photo)
  final Map<String, UserModel?> _userCache = {};

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
  const useFirebase = Environment.useFirebase;
      final userId = useFirebase
          ? (FirebaseAuth.instance.currentUser?.uid ?? '')
          : 'mock_user_123';

      if (userId.isEmpty) {
        throw const AppException('No authenticated user');
      }

      final matchingService = ref.read(matchingServiceProvider);
      final matches = await matchingService.findPotentialMatches(
        userId: userId,
        limit: 10,
      );

      setState(() {
        _potentialMatches = matches;
        _currentCardIndex = 0;
        _isLoading = false;
        _currentUserId = userId;
        _cardOffset = Offset.zero;
  _cardRotation = 0;
        _actionInProgress = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _onSwipe(bool isLike) async {
    if (_currentCardIndex >= _potentialMatches.length || _actionInProgress) return;
    final me = _currentUserId;
    if (me == null) return;
    final current = _potentialMatches[_currentCardIndex];

    setState(() => _actionInProgress = true);

    try {
      final matchingService = ref.read(matchingServiceProvider);
      final otherId = current.getOtherUserId(me);
      if (isLike) {
        await matchingService.likeUser(currentUserId: me, likedUserId: otherId);
      } else {
        await matchingService.passUser(currentUserId: me, passedUserId: otherId);
      }
    } catch (_) {
      // Ignore backend errors; keep UX flowing
    }

    setState(() {
      _currentCardIndex++;
      _cardOffset = Offset.zero;
      _cardRotation = 0;
  // dragging state removed
      _actionInProgress = false;
    });

    if (isLike) {
      await _likeController.forward();
      _likeController.reset();
    } else {
      await _passController.forward();
      _passController.reset();
    }
  }

  // Drag handlers for swipe
  void _onDragStart(DragStartDetails details) {
    if (_actionInProgress) return;
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (_actionInProgress) return;
    final offset = _cardOffset + details.delta;
    final rotation = (offset.dx / 300).clamp(-0.4, 0.4);
    setState(() {
      _cardOffset = offset;
      _cardRotation = rotation;
    });
  }

  void _onDragEnd(DragEndDetails details) {
    if (_actionInProgress) return;
    const threshold = 120.0;
    if (_cardOffset.dx > threshold) {
      _onSwipe(true);
    } else if (_cardOffset.dx < -threshold) {
      _onSwipe(false);
    } else {
      setState(() {
        _cardOffset = Offset.zero;
        _cardRotation = 0;
      });
    }
  }

  Future<UserModel?> _getUser(String userId) async {
    if (_userCache.containsKey(userId)) return _userCache[userId];
    try {
      final svc = ref.read(userServiceProvider);
      final user = await svc.getUserById(userId);
      _userCache[userId] = user;
      return user;
    } catch (_) {
      _userCache[userId] = null;
      return null;
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
                      child: i == _currentCardIndex
                          ? GestureDetector(
                              onPanStart: _onDragStart,
                              onPanUpdate: _onDragUpdate,
                              onPanEnd: _onDragEnd,
                              child: Transform.translate(
                                offset: _cardOffset,
                                child: Transform.rotate(
                                  angle: _cardRotation,
                                  child: Stack(
                                    children: [
                                      _buildMatchCard(_potentialMatches[i], true),
                                      _buildSwipeOverlays(),
                                    ],
                                  ),
                                ),
                              ),
                            )
                          : _buildMatchCard(_potentialMatches[i], false),
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

  Widget _buildSwipeOverlays() {
    final dx = _cardOffset.dx;
    final likeOpacity = (dx / 100).clamp(0.0, 1.0);
    final passOpacity = (-dx / 100).clamp(0.0, 1.0);
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: 24,
            left: 24,
            child: Opacity(
              opacity: likeOpacity,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green, width: 2),
                ),
                child: const Text(
                  'LIKE',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 24,
            right: 24,
            child: Opacity(
              opacity: passOpacity,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red, width: 2),
                ),
                child: const Text(
                  'PASS',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
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
    final otherUserId = _currentUserId == null ? match.userId2 : match.getOtherUserId(_currentUserId!);
    return Card(
      elevation: isActive ? 8 : 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Background image placeholder
            FutureBuilder<UserModel?>(
              future: _getUser(otherUserId),
              builder: (context, snapshot) {
                final user = snapshot.data;
                if (user != null && (user.photos.isNotEmpty || (user.profileImageUrl ?? '').isNotEmpty)) {
                  final photoUrl = user.photos.isNotEmpty ? user.photos.first : user.profileImageUrl!;
                  return Positioned.fill(
                    child: CachedNetworkImage(
                      imageUrl: photoUrl,
                      fit: BoxFit.cover,
                      placeholder: (c, _) => _fallbackGradient(),
                      errorWidget: (c, e, s) => _fallbackGradient(),
                    ),
                  );
                }
                return _fallbackGradient();
              },
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
                  FutureBuilder<UserModel?>(
                    future: _getUser(otherUserId),
                    builder: (context, snapshot) {
                      final user = snapshot.data;
      final title = user != null
        ? '${user.name}, ${user.age}'
        : 'Discover profile';
                      return Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      );
                    },
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

  Widget _fallbackGradient() {
    return Container(
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
    );
  }
}
