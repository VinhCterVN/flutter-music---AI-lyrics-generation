import 'package:flutter_ai_music/data/models/lyric_line.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LyricsLine', () {
    test('uses music note placeholder for empty synced lyric text', () {
      final line = LyricsLine.fromString('[00:12.12]');

      expect(line.startTime, const Duration(milliseconds: 12120));
      expect(line.text, LyricsLine.emptyTextPlaceholder);
    });

    test('uses music note placeholder for empty database text', () {
      final line = LyricsLine.fromJson({
        'start_time': 12.12,
        'end_time': 13.13,
        'text': '',
      });

      expect(line.startTime, const Duration(milliseconds: 12120));
      expect(line.endTime, const Duration(milliseconds: 13130));
      expect(line.text, LyricsLine.emptyTextPlaceholder);
    });
  });
}
