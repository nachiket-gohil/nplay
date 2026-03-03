import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../player/player_screen.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  String? audioPath;
  String? lyricsPath;

  bool get hasAudio => (audioPath ?? '').trim().isNotEmpty;

  bool get hasLyrics => (lyricsPath ?? '').trim().isNotEmpty;

  String _fileName(String? path) {
    final p = (path ?? '').trim();
    if (p.isEmpty) return '';
    final parts = p.split(RegExp(r'[\/\\]'));
    return parts.isNotEmpty ? parts.last : p;
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
    ));
  }

  Future<void> pickAudio() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['mp3', 'wav', 'm4a'],
    );
    if (!mounted) return;

    if (result?.files.single.path != null) {
      setState(() => audioPath = result!.files.single.path);
    }
  }

  Future<void> pickLyrics() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['lrc'],
    );
    if (!mounted) return;

    if (result?.files.single.path != null) {
      setState(() => lyricsPath = result!.files.single.path);
    }
  }

  void goNext() {
    // Your rule: navigation allowed only when audio exists.
    if (!hasAudio) {
      if (hasLyrics) {
        _snack("Lyrics selected, but you must select an audio file first.");
      } else {
        _snack("Please select an audio file to continue.");
      }
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlayerScreen(
          audioPath: audioPath!,
          lyricsPath: hasLyrics ? lyricsPath! : "",
        ),
      ),
    );
  }

  Widget _pickerCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String buttonText,
    required VoidCallback onPick,
    required bool selected,
    required String selectedName,
    required String? fullPath,
    required VoidCallback onClear,
  }) {
    return Card(
      elevation: 0,
      color: Colors.blueGrey[100],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(color: Colors.black),
                      ),
                    ],
                  ),
                ),
                if (selected)
                  IconButton(
                    tooltip: "Clear",
                    onPressed: onClear,
                    icon: const Icon(Icons.close),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onPick,
                  icon: const Icon(Icons.folder_open),
                  label: Text(buttonText),
                ),
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.black),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    selected ? selectedName : "No file selected",
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: selected ? Colors.black : Colors.black54,
                    ),
                  ),
                  if (selected && fullPath != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      fullPath,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final audioName = _fileName(audioPath);
    final lyricName = _fileName(lyricsPath);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Upload Files"),
        elevation: 8,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 14, 24, 16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Text(
                    "Step 1: Pick an audio file.\n\n"
                    "Step 2: Pick an .lrc lyrics file with timestamps as per preview image.\n",
                    style: TextStyle(
                      color: Colors.black,
                      height: 1.3,
                    ),
                  ),
                ),
                _pickerCard(
                  icon: Icons.music_note,
                  title: "Audio (required)",
                  subtitle: "Supported: .mp3, .wav, .m4a",
                  buttonText: hasAudio ? "Change audio" : "Pick audio",
                  onPick: pickAudio,
                  selected: hasAudio,
                  selectedName: audioName,
                  fullPath: audioPath,
                  onClear: () => setState(() => audioPath = null),
                ),
                _pickerCard(
                  icon: Icons.lyrics,
                  title: "Lyrics (optional)",
                  subtitle: "Use .lrc format like [00:10.50] line text",
                  buttonText: hasLyrics ? "Change lyrics" : "Pick lyrics",
                  onPick: pickLyrics,
                  selected: hasLyrics,
                  selectedName: lyricName,
                  fullPath: lyricsPath,
                  onClear: () => setState(() => lyricsPath = null),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Text(
                    hasAudio
                        ? (hasLyrics
                            ? "Ready: audio + lyrics selected."
                            : "Ready: audio selected (lyrics optional).")
                        : (hasLyrics
                            ? "Pick audio to continue (lyrics only is not allowed)."
                            : "Pick audio to continue."),
                    style: const TextStyle(
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          width: double.infinity,
          height: 52,
          margin: const EdgeInsets.only(bottom: 40),
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: ElevatedButton.icon(
            onPressed: goNext,
            label: const Text("Next"),
            icon: const Icon(Icons.arrow_forward),
            iconAlignment: IconAlignment.end,
          ),
        ),
      ),
    );
  }
}
