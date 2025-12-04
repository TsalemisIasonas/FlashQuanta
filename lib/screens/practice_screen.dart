import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/project_provider.dart';
import '../widgets/flashcard_widget.dart';
import '../models/flashcard.dart';

class PracticeScreen extends StatefulWidget {
  const PracticeScreen({Key? key}) : super(key: key);

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> with SingleTickerProviderStateMixin {
  int _index = 0;
  bool _showFront = true;
  List<Flashcard> _cards = [];
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  int? _outgoingIndex;
  double _dragDx = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideAnimation = Tween<Offset>(begin: Offset.zero, end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _fadeAnimation = Tween<double>(begin: 1.0, end: 1.0)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = Provider.of<ProjectProvider>(context);
    // Always start a practice session on the Unknown tab if there
    // are any unknown cards. Do this after the first frame to avoid
    // notifyListeners during build, and leave the current filter if
    // everything is already known so the user can switch manually.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final p = Provider.of<ProjectProvider>(context, listen: false);
      final allCards = p.flashcardsForSelectedProject();
      final hasUnknown = allCards.any((c) => !c.known);
      if (hasUnknown) {
        p.setPracticeFilterUnknownOnly();
      }
    });
    _cards = provider.flashcardsForPractice();
    _index = 0;
    _showFront = true;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_cards.isEmpty) return;
    _animateTo(indexDelta: 1);
  }

  void _prev() {
    if (_cards.isEmpty) return;
    _animateTo(indexDelta: -1);
  }

  void _animateTo({required int indexDelta}) {
    if (_cards.isEmpty) return;
    if (_controller.isAnimating) return; // avoid overlapping animations

    final bool forward = indexDelta > 0;
    final int fromIndex = _index;
    _outgoingIndex = fromIndex;
    _controller.reset();
    // card moves up and diagonally (right for next, left for prev) and fades out
    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: forward ? const Offset(0.6, -1.2) : const Offset(-0.6, -1.2),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));
    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _controller.forward().then((_) {
      if (!mounted) return;
      setState(() {
        _index = (fromIndex + indexDelta) % _cards.length;
        if (_index < 0) _index += _cards.length;
        _showFront = true;
        _outgoingIndex = null;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProjectProvider>(context);
    _cards = provider.flashcardsForPractice();
    if (_cards.isNotEmpty && _index >= _cards.length) {
      _index = 0;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Practice'),
        leading: IconButton(
          icon: const Icon(Icons.home),
          onPressed: () {
                provider.selectedProjectId = null;
                Navigator.of(context).popUntil((route) => route.isFirst);
          },
        ),
        bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: Colors.white24,
          ),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.06,
                child: Center(
                  child: Image.asset(
                    'assets/logo/flashquanta_logo.png',
                    width: 260,
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _GlassFilterChip(
                            label: 'All',
                            selected: provider.practiceShowAll,
                            onTap: () {
                              provider.setPracticeFilterAll();
                              setState(() {
                                _index = 0;
                                _showFront = true;
                              });
                            },
                          ),
                          const SizedBox(width: 8),
                          _GlassFilterChip(
                            label: 'Known',
                            selected: provider.practiceShowKnownOnly,
                            onTap: () {
                              provider.setPracticeFilterKnownOnly();
                              setState(() {
                                _index = 0;
                                _showFront = true;
                              });
                            },
                          ),
                          const SizedBox(width: 8),
                          _GlassFilterChip(
                            label: 'Unknown',
                            selected: provider.practiceShowUnknownOnly,
                            onTap: () {
                              provider.setPracticeFilterUnknownOnly();
                              setState(() {
                                _index = 0;
                                _showFront = true;
                              });
                            },
                          ),
                        ],
                      ),
                const SizedBox(height: 12),
                if (_cards.isEmpty)
                  const Expanded(
                    child: Center(child: Text('No flashcards to practice.')),
                  )
                else ...[
                  Text('${_index + 1}/${_cards.length}'),
                  const SizedBox(height: 16),
                  Expanded(
                    flex: 3,
                    child: Center(
                      child: FractionallySizedBox(
                        widthFactor: 0.95,
                        child: GestureDetector(
                          onHorizontalDragUpdate: (details) {
                            _dragDx += details.delta.dx;
                          },
                          onHorizontalDragEnd: (details) {
                            // Decide direction based on drag distance so animation always plays
                            if (_dragDx < -20) {
                              // dragged left -> next card (up-right)
                              _next();
                            } else if (_dragDx > 20) {
                              // dragged right -> previous card (up-left)
                              _prev();
                            }
                            _dragDx = 0;
                          },
                          child: Stack(
                            children: [
                              // current card (static)
                              Positioned.fill(
                                child: FlashcardWidget(
                                  front: _cards[_index].sideA,
                                  back: _cards[_index].sideB,
                                  height: double.infinity,
                                  onFlip: () {},
                                ),
                              ),
                              // outgoing animated card on top, if any
                              if (_outgoingIndex != null)
                                Positioned.fill(
                                  child: FadeTransition(
                                    opacity: _fadeAnimation,
                                    child: SlideTransition(
                                      position: _slideAnimation,
                                      child: FlashcardWidget(
                                        front: _cards[_outgoingIndex!].sideA,
                                        back: _cards[_outgoingIndex!].sideB,
                                        height: double.infinity,
                                        onFlip: () {},
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          // mark as unknown (known = false)
                          final card = _cards[_index];
                          card.known = false;
                          provider.updateFlashcard(card);
                          _next();
                        },
                        icon: const Icon(
                          Icons.close,
                          color: Colors.white,
                        ),
                        label: const Text(
                          'Unknown',
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: () {
                          // mark as known
                          final card = _cards[_index];
                          card.known = true;
                          provider.updateFlashcard(card);
                          _next();
                        },
                        icon: const Icon(
                          Icons.check,
                          color: Colors.white,
                        ),
                        label: const Text(
                          'Known',
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _GlassFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final baseColor = selected ? Colors.white.withOpacity(0.18) : Colors.white.withOpacity(0.06);
    final borderColor = selected ? Colors.white.withOpacity(0.5) : Colors.white.withOpacity(0.18);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors: [
              baseColor,
              Colors.white.withOpacity(selected ? 0.06 : 0.02),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}