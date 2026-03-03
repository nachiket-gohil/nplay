import 'dart:async';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../../core/model/lyric_line.dart';

class LyricsPanel extends StatefulWidget {
  final AudioPlayer player;
  final List<LyricLine> lyrics;
  final bool isOpen;
  final VoidCallback onClose;

  const LyricsPanel({
    super.key,
    required this.player,
    required this.lyrics,
    required this.isOpen,
    required this.onClose,
  });

  @override
  State<LyricsPanel> createState() => _LyricsPanelState();
}

class _LyricsPanelState extends State<LyricsPanel>
    with SingleTickerProviderStateMixin {
  static const double _panelHeightFactor = 0.92; // almost full like Spotify
  static const double _itemExtent = 40;

  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  final ScrollController _scroll = ScrollController();

  StreamSubscription<Duration>? _posSub;
  StreamSubscription<PlayerState>? _stateSub;

  int _currentIndex = -1;

  // user scrolling detection to avoid fighting user
  bool _userInteracting = false;
  Timer? _idleTimer;

  @override
  void initState() {
    super.initState();

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);

    if (widget.isOpen) _ctrl.value = 1;

    _posSub = widget.player.positionStream.listen(_onPosition);
    _stateSub = widget.player.playerStateStream.listen((s) {
      if (s.processingState == ProcessingState.completed) {
        if (_currentIndex != -1) setState(() => _currentIndex = -1);
      }
    });
  }

  @override
  void didUpdateWidget(covariant LyricsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);

    // open/close animation
    if (widget.isOpen && !_ctrl.isCompleted) {
      _ctrl.forward();
    } else if (!widget.isOpen && !_ctrl.isDismissed) {
      _ctrl.reverse();
    }

    // lyrics list changed => reset index
    if (!identical(oldWidget.lyrics, widget.lyrics)) {
      setState(() => _currentIndex = -1);
      // and scroll back to top when reopened
      if (widget.isOpen) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scroll.hasClients) _scroll.jumpTo(0);
        });
      }
    }
  }

  @override
  void dispose() {
    _posSub?.cancel();
    _stateSub?.cancel();
    _idleTimer?.cancel();
    _scroll.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  void _onPosition(Duration pos) {
    if (!widget.isOpen) return; // only do work when panel is visible
    if (widget.lyrics.isEmpty) return;

    final idx = _findCurrentIndex(pos, widget.lyrics);
    if (idx != _currentIndex) {
      setState(() => _currentIndex = idx);
      if (!_userInteracting) _scrollToCenter(idx);
    }
  }

  int _findCurrentIndex(Duration pos, List<LyricLine> lyrics) {
    int lo = 0, hi = lyrics.length - 1, ans = -1;
    while (lo <= hi) {
      final mid = (lo + hi) >> 1;
      if (lyrics[mid].time <= pos) {
        ans = mid;
        lo = mid + 1;
      } else {
        hi = mid - 1;
      }
    }
    return ans;
  }

  void _markUserInteracting() {
    _userInteracting = true;
    _idleTimer?.cancel();
    _idleTimer = Timer(const Duration(milliseconds: 900), () {
      _userInteracting = false;
      if (_currentIndex != -1) _scrollToCenter(_currentIndex);
    });
  }

  void _scrollToCenter(int index) {
    if (!_scroll.hasClients) return;

    final viewport = _scroll.position.viewportDimension;
    final target = (index * _itemExtent) - (viewport / 2) + (_itemExtent / 2);

    final clamped = target.clamp(
      _scroll.position.minScrollExtent,
      _scroll.position.maxScrollExtent,
    );

    _scroll.animateTo(
      clamped.toDouble(),
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  // drag-to-close
  void _onDragUpdate(DragUpdateDetails d) {
    // user drags down => close; up => open
    final dy = d.primaryDelta ?? 0;
    final h = MediaQuery.of(context).size.height;
    // tweak sensitivity
    _ctrl.value -= dy / (h * 0.6);
  }

  void _onDragEnd(DragEndDetails d) {
    final v = d.primaryVelocity ?? 0;

    // fast downward swipe closes
    if (v > 900) {
      widget.onClose();
      return;
    }
    // fast upward swipe opens
    if (v < -900) {
      _ctrl.forward();
      return;
    }

    // settle based on current value
    if (_ctrl.value < 0.6) {
      widget.onClose();
    } else {
      _ctrl.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasLyrics = widget.lyrics.isNotEmpty;

    return IgnorePointer(
      ignoring: !widget.isOpen && _ctrl.value == 0,
      child: AnimatedBuilder(
        animation: _anim,
        builder: (context, _) {
          // Slide from bottom: 1 => fully visible, 0 => hidden
          final t = _anim.value;
          return Align(
            alignment: Alignment.bottomCenter,
            child: Transform.translate(
              offset: Offset(
                  0,
                  (1 - t) *
                      MediaQuery.of(context).size.height *
                      _panelHeightFactor),
              child: FractionallySizedBox(
                heightFactor: _panelHeightFactor,
                widthFactor: 1,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onVerticalDragUpdate: _onDragUpdate,
                  onVerticalDragEnd: _onDragEnd,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.94),
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(22)),
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 10),
                        Container(
                          width: 44,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Header
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              const Icon(Icons.lyrics, size: 18),
                              const SizedBox(width: 8),
                              const Text(
                                "Lyrics",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsetsGeometry.symmetric(
                                    horizontal: 8),
                                child: hasLyrics
                                    ? const Icon(
                                        Icons.sync,
                                        size: 18,
                                        color: Colors.greenAccent,
                                      )
                                    : const Icon(
                                        Icons.lyrics_outlined,
                                        size: 18,
                                        color: Colors.white,
                                      ),
                              ),
                              const Spacer(),
                              IconButton(
                                tooltip: "Close",
                                onPressed: widget.onClose,
                                icon: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Divider(
                          height: 1,
                          color: Colors.grey[700],
                        ),

                        // Body (scrollable)
                        Expanded(
                          child: hasLyrics
                              ? NotificationListener<ScrollNotification>(
                                  onNotification: (n) {
                                    if (n is UserScrollNotification ||
                                        n is ScrollStartNotification ||
                                        n is ScrollUpdateNotification) {
                                      _markUserInteracting();
                                    }
                                    return false;
                                  },
                                  child: ListView.builder(
                                    controller: _scroll,
                                    padding: const EdgeInsets.fromLTRB(
                                        16, 24, 16, 24),
                                    itemCount: widget.lyrics.length,
                                    itemExtent: _itemExtent,
                                    itemBuilder: (context, i) {
                                      final isCurrent = i == _currentIndex;
                                      final text = widget.lyrics[i].text.trim();

                                      return Center(
                                        child: AnimatedDefaultTextStyle(
                                          duration:
                                              const Duration(milliseconds: 160),
                                          curve: Curves.easeOut,
                                          style: TextStyle(
                                            fontSize: isCurrent ? 22 : 18,
                                            // fontWeight: isCurrent
                                            //     ? FontWeight.w800
                                            //     : FontWeight.w500,
                                            color: isCurrent
                                                ? Colors.greenAccent
                                                : Colors.white,
                                            // height: 1,
                                          ),
                                          child: Text(
                                            text,
                                            textAlign: TextAlign.center,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                )
                              : ListView(
                                  padding: const EdgeInsets.all(16),
                                  children: [
                                    Text(
                                      "No lyrics file provided.\n\nUpload an .lrc file to show synced lyrics.",
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.78),
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
