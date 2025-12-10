class LyricsLine {
  final Duration startTime;
  final Duration endTime;
  final String text;

  LyricsLine({required this.startTime, required this.endTime, required this.text});

  // Parse format: [00:00.000 --> 00:16.800] Lyrics text
  factory LyricsLine.fromString(String line) {
    final regex = RegExp(r'\[(\d{2}):(\d{2}\.\d{3}) --> (\d{2}):(\d{2}\.\d{3})\]\s*(.*)');
    final match = regex.firstMatch(line);

    if (match == null) {
      throw FormatException('Invalid lyrics format');
    }

    final startMin = int.parse(match.group(1)!);
    final startSec = double.parse(match.group(2)!);
    final endMin = int.parse(match.group(3)!);
    final endSec = double.parse(match.group(4)!);
    final text = match.group(5)!;

    return LyricsLine(
      startTime: Duration(minutes: startMin, milliseconds: (startSec * 1000).toInt()),
      endTime: Duration(minutes: endMin, milliseconds: (endSec * 1000).toInt()),
      text: text,
    );
  }

  factory LyricsLine.fromJson(Map<String, dynamic> json) {
    double start = (json['start_time'] as num).toDouble();
    double end = (json['end_time'] as num).toDouble();

    return LyricsLine(
      startTime: Duration(milliseconds: (start * 1000).toInt()),
      endTime: Duration(milliseconds: (end * 1000).toInt()),
      text: json['text'] as String,
    );
  }
}
