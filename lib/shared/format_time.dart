String formatTime(int seconds) {
  if (seconds < 60) return '$seconds s';
  return '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
}
