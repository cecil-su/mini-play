// lib/match3/match3_gem.dart

enum GemType { red, orange, yellow, green, blue, purple }

enum Match3GameMode { classic, timed, moves }

class Gem {
  GemType type;

  /// Unique id for animation tracking.
  final int id;

  Gem({required this.type, required this.id});
}
