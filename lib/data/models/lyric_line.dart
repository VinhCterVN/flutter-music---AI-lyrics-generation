class LyricsLine {
  final Duration startTime;
  final Duration endTime;
  final String text;

  LyricsLine({required this.startTime, required this.endTime, required this.text});

  factory LyricsLine.fromString(String line, {Duration? endTime}) {
    final regex = RegExp(r'^\[(\d{2}):(\d{2}(?:\.\d{1,3})?)\]\s*(.*)$');
    final match = regex.firstMatch(line);

    if (match == null) {
      throw FormatException('Invalid lyrics format');
    }

    final startMin = int.parse(match.group(1)!);
    final startSec = double.parse(match.group(2)!);
    final text = match.group(3) ?? '';
    final startTime = Duration(minutes: startMin) + Duration(milliseconds: (startSec * 1000).round());
    final resolvedEndTime = endTime != null && endTime > startTime ? endTime : startTime + const Duration(seconds: 5);

    final cleaned = text.replaceAll(RegExp(r'[\r\n]+'), '').trim();
    return LyricsLine(startTime: startTime, endTime: resolvedEndTime, text: cleaned);
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
