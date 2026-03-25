// lib/flappybird/flappybird_colors.dart
import 'package:flutter/material.dart';

class FlappybirdColors {
  // Sky gradient
  static const Color skyTop = Color(0xFF87CEEB);    // light blue
  static const Color skyBottom = Color(0xFF4A90D9);  // deeper blue

  // Bird
  static const Color birdBody = Color(0xFFF0C040);   // yellow
  static const Color birdWing = Color(0xFFE8A020);    // darker yellow/orange
  static const Color birdEye = Colors.white;
  static const Color birdPupil = Colors.black;

  // Pipes
  static const Color pipeBody = Color(0xFF4CAF50);       // green
  static const Color pipeBodyDark = Color(0xFF388E3C);    // darker green for gradient
  static const Color pipeCap = Color(0xFF2E7D32);         // cap green
  static const Color pipeCapDark = Color(0xFF1B5E20);     // cap dark

  // Ground
  static const Color groundTop = Color(0xFF8BC34A);    // grass green
  static const Color groundBottom = Color(0xFF795548);  // brown earth

  // Cloud
  static const Color cloud = Color(0x66FFFFFF);  // semi-transparent white

  // HUD / overlay
  static const Color overlayText = Colors.white;
  static const Color overlayTextShadow = Color(0x88000000);
}
