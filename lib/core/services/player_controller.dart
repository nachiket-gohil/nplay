import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

import "../model/lyric_line.dart";

class PlayerController {
  final AudioPlayer _player = AudioPlayer();

  List<LyricLine> lyrics = [];
  int currentIndex = -1;

  AudioPlayer get player => _player;

  Future<void> loadAudio(String path) async {
    final file = File(path);

    // Optional: validate early so you get a clear error.
    if (!await file.exists()) {
      throw Exception("Audio file not found at path: $path");
    }

    final fileName = path.split(RegExp(r'[\/\\]')).last;

    final source = AudioSource.uri(
      Uri.file(path),
      tag: MediaItem(
        id: path, // unique ID; local path is fine for POC
        title: fileName,
        artist: 'Local file',
        album: 'Uploads',
        // You can add artUri later if you want album art in notification/lockscreen
        // artUri: Uri.parse("https://..."),
      ),
    );

    await _player.setAudioSource(source);
  }

  void setLyrics(List<LyricLine> parsedLyrics) {
    lyrics = parsedLyrics;
    currentIndex = -1;
  }

  void listenToPosition(void Function(int) onLyricChanged) {
    _player.positionStream.listen((position) {
      if (lyrics.isEmpty) return;

      int newIndex = -1;
      for (int i = 0; i < lyrics.length; i++) {
        if (position >= lyrics[i].time &&
            (i == lyrics.length - 1 || position < lyrics[i + 1].time)) {
          newIndex = i;
          break;
        }
      }

      if (newIndex != currentIndex) {
        currentIndex = newIndex;
        onLyricChanged(newIndex);
      }
    });

    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        if (currentIndex != -1) {
          currentIndex = -1;
          onLyricChanged(-1);
        }
      }
    });
  }

  void play() => _player.play();

  void pause() => _player.pause();

  void dispose() => _player.dispose();
}
