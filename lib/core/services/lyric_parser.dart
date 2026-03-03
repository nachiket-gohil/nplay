import "../model/lyric_line.dart";

class LyricParser {
  static final _timeTag = RegExp(r'\[(\d{1,3}):(\d{2})(?:\.(\d{1,3}))?\]');
  static final _metaTag = RegExp(r'^\[[a-zA-Z]{1,3}:.+\]$');

  static List<LyricLine> parse(String content) {
    final rawLines = content.split(RegExp(r'\r?\n'));
    final List<LyricLine> out = [];

    for (final raw in rawLines) {
      final line = raw.trim();
      if (line.isEmpty) continue;
      if (_metaTag.hasMatch(line)) continue;

      final matches = _timeTag.allMatches(line).toList();
      if (matches.isEmpty) continue;

      final text = line.replaceAll(_timeTag, '').trim();
      if (text.isEmpty) continue;

      for (final m in matches) {
        final mm = int.parse(m.group(1)!);
        final ss = int.parse(m.group(2)!);
        final frac = m.group(3);

        final ms = frac == null
            ? 0
            : (frac.length == 1)
                ? int.parse(frac) * 100
                : (frac.length == 2)
                    ? int.parse(frac) * 10
                    : int.parse(frac.substring(0, 3));

        out.add(
          LyricLine(
            time: Duration(minutes: mm, seconds: ss, milliseconds: ms),
            text: text,
          ),
        );
      }
    }

    out.sort((a, b) => a.time.compareTo(b.time));
    return out;
  }
}

/*
class LyricParser {
  static List<LyricLine> parse(String content) {
    final lines = content.split(RegExp(r'\r?\n'));
    final regex = RegExp(r'^\[(\d+):(\d+(?:\.\d+)?)\]\s*(.*)$');
    final List<LyricLine> lyrics = [];

    for (final line in lines) {
      final match = regex.firstMatch(line.trim());
      if (match == null) continue;

      final minutes = int.tryParse(match.group(1) ?? '') ?? 0;
      final seconds = double.tryParse(match.group(2) ?? '') ?? 0.0;
      final text = (match.group(3) ?? '').trim();

      // Optional: ignore empty lyric lines
      if (text.isEmpty) continue;

      lyrics.add(
        LyricLine(
          time: Duration(
            minutes: minutes,
            milliseconds: (seconds * 1000).round(),
          ),
          text: text,
        ),
      );
    }

    lyrics.sort((a, b) => a.time.compareTo(b.time));
    return lyrics;
  }

/*
  static List<LyricLine> parse(String content) {
    final lines = content.split('\n');
    final regex = RegExp(r'\[(\d+):(\d+\.\d+)\] (.+)');
    final List<LyricLine> lyrics = [];

    for (var line in lines) {
      final match = regex.firstMatch(line);
      if (match != null) {
        final minutes = int.parse(match.group(1)!);
        final seconds = double.parse(match.group(2)!);
        final text = match.group(3)!;

        lyrics.add(
          LyricLine(
            time: Duration(
              minutes: minutes,
              milliseconds: (seconds * 1000).toInt(),
            ),
            text: text,
          ),
        );
      }
    }

    return lyrics;
  }
  */
}
*/
