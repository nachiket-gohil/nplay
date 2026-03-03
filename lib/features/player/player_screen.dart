import 'dart:io';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../../core/services/lyric_parser.dart';
import '../../core/services/player_controller.dart';
import 'lyrics_panel.dart';

class PlayerScreen extends StatefulWidget {
  final String audioPath;
  final String lyricsPath;

  const PlayerScreen({
    super.key,
    required this.audioPath,
    required this.lyricsPath,
  });

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen>
    with SingleTickerProviderStateMixin {
  final PlayerController controller = PlayerController();

  bool get lyricsSelected => widget.lyricsPath.trim().isNotEmpty;
  late final AnimationController _discController;

  bool _lyricsOpen = false;

  @override
  void initState() {
    super.initState();

    _discController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    );

    init();
  }

  Future<void> init() async {
    // Lyrics optional
    if (lyricsSelected) {
      final content = await File(widget.lyricsPath).readAsString();
      final parsed = LyricParser.parse(content);
      controller.setLyrics(parsed);
    } else {
      controller.setLyrics([]);
    }

    await controller.loadAudio(widget.audioPath);

    controller.player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        controller.player.seek(Duration.zero);
        controller.player.pause();

        _discController.stop();
        _discController.reset();

        if (mounted) setState(() {});
      }
    });

    // This is still useful for the main screen, panel handles its own updates.
    controller.listenToPosition((_) {
      if (mounted) setState(() {});
    });

    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    controller.dispose();
    _discController.dispose();
    super.dispose();
  }

  String get title => widget.audioPath.split(RegExp(r'[\/\\]')).last;

  void _toggleLyrics() {
    setState(() => _lyricsOpen = !_lyricsOpen);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("N Player"), centerTitle: true),
      body: SafeArea(
        child: Stack(
          children: [
            // Main player content
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
              child: Column(
                children: [
                  // Album art / disc
                  Container(
                    width: double.infinity,
                    height: MediaQuery.of(context).size.width - 36,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      color: Colors.white.withOpacity(0.06),
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                    ),
                    child: Center(
                      child: RotationTransition(
                        turns: _discController,
                        child: Container(
                          width: 220,
                          height: 220,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.08),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.10)),
                          ),
                          child: Image.asset("assets/disc.png"),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w800),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),

                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Local file playback",
                      style: TextStyle(color: Colors.white.withOpacity(0.65)),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // time --- seekbar --- total time row
                  StreamBuilder<Duration?>(
                    stream: controller.player.durationStream,
                    builder: (context, durSnap) {
                      final total = durSnap.data ??
                          controller.player.duration ??
                          Duration.zero;

                      return StreamBuilder<Duration>(
                        stream: controller.player.positionStream,
                        builder: (context, posSnap) {
                          final pos = posSnap.data ?? Duration.zero;
                          final maxMs = total.inMilliseconds == 0
                              ? 1
                              : total.inMilliseconds;
                          final value =
                              pos.inMilliseconds.clamp(0, maxMs).toDouble();

                          return Row(
                            children: [
                              SizedBox(
                                width: 52,
                                child: Text(
                                  _fmt(pos),
                                  style: const TextStyle(color: Colors.black),
                                ),
                              ),
                              Expanded(
                                child: Slider(
                                  value: value,
                                  min: 0,
                                  max: maxMs.toDouble(),
                                  onChanged: (v) => controller.player.seek(
                                    Duration(milliseconds: v.toInt()),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 52,
                                child: Text(
                                  _fmt(total),
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(color: Colors.black),
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),

                  const SizedBox(height: 18),

                  // Controls: restart, play/pause (clean), lyrics toggle
                  StreamBuilder<PlayerState>(
                    stream: controller.player.playerStateStream,
                    builder: (context, snapshot) {
                      final state = snapshot.data;
                      final playing = state?.playing ?? false;
                      final processing = state?.processingState;

                      final isLoading = processing == ProcessingState.loading ||
                          processing == ProcessingState.buffering;

                      // drive disc animation
                      if (playing) {
                        if (!_discController.isAnimating)
                          _discController.repeat();
                      } else {
                        if (_discController.isAnimating) _discController.stop();
                      }

                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: IconButton(
                              tooltip: "Restart",
                              onPressed: () {
                                controller.player.seek(Duration.zero);
                                if (!playing) _discController.reset();
                              },
                              icon: const Icon(
                                Icons.restart_alt,
                                size: 28,
                              ),
                            ),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              shape: const CircleBorder(),
                              fixedSize: const Size(65, 65),
                              padding: EdgeInsets.zero,
                              // important
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              alignment: Alignment.center, // important
                            ),
                            onPressed: isLoading
                                ? null
                                : () => playing
                                    ? controller.pause()
                                    : controller.play(),
                            child: Center(
                              // belt + suspenders
                              child: isLoading
                                  ? const SizedBox(
                                      width: 26,
                                      height: 26,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    )
                                  : Icon(
                                      playing ? Icons.pause : Icons.play_arrow,
                                      size: 40,
                                    ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: IconButton(
                              tooltip:
                                  _lyricsOpen ? "Hide lyrics" : "Show lyrics",
                              onPressed: _toggleLyrics,
                              icon: Icon(
                                Icons.lyrics,
                                size: 28,
                                color: _lyricsOpen ? Colors.greenAccent : null,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),

            // Lyrics panel overlay (almost full like Spotify)
            LyricsPanel(
              player: controller.player,
              lyrics: controller.lyrics,
              isOpen: _lyricsOpen,
              onClose: () => setState(() => _lyricsOpen = false),
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    final mm = two(d.inMinutes);
    final ss = two(d.inSeconds.remainder(60));
    return "$mm:$ss";
  }
}
