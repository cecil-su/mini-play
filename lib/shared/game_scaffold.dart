import 'package:flutter/material.dart';

class GameScaffold extends StatefulWidget {
  final String title;
  final ValueNotifier<int> scoreNotifier;
  final int bestScore;
  final Widget child;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final String scoreLabel;
  final String bestLabel;
  final String Function(int)? scoreFormatter;
  final String Function(int)? bestFormatter;
  final bool Function()? canPause;
  final Color Function(int score)? scoreColorBuilder;

  const GameScaffold({
    super.key,
    required this.title,
    required this.scoreNotifier,
    required this.bestScore,
    required this.child,
    required this.onPause,
    required this.onResume,
    this.scoreLabel = 'Score',
    this.bestLabel = 'Best',
    this.scoreFormatter,
    this.bestFormatter,
    this.canPause,
    this.scoreColorBuilder,
  });

  @override
  State<GameScaffold> createState() => _GameScaffoldState();
}

class _GameScaffoldState extends State<GameScaffold>
    with WidgetsBindingObserver {
  bool _isPaused = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.hidden ||
        state == AppLifecycleState.paused) {
      _pause(fromLifecycle: true);
    }
  }

  void _pause({bool fromLifecycle = false}) {
    if (!fromLifecycle && widget.canPause != null && !widget.canPause!()) {
      _quit();
      return;
    }
    if (!_isPaused) {
      final showOverlay = widget.canPause?.call() ?? true;
      if (showOverlay) {
        setState(() => _isPaused = true);
      }
      widget.onPause();
    }
  }

  void _resume() {
    if (_isPaused) {
      setState(() => _isPaused = false);
      widget.onResume();
    }
  }

  void _quit() {
    Navigator.popUntil(context, ModalRoute.withName('/'));
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _pause();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF1A1A2E),
        body: SafeArea(
          child: Column(
            children: [
              // Top bar
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: _pause,
                    ),
                    Expanded(
                      child: Text(
                        widget.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.pause, color: Colors.white),
                      onPressed: _pause,
                    ),
                  ],
                ),
              ),

              // Score bar
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ValueListenableBuilder<int>(
                  valueListenable: widget.scoreNotifier,
                  builder: (context, score, _) {
                    final scoreColor = widget.scoreColorBuilder?.call(score)
                        ?? const Color(0xFF4ECCA3);
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${widget.scoreLabel}: ${widget.scoreFormatter?.call(score) ?? '$score'}',
                          style: TextStyle(
                            color: scoreColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${widget.bestLabel}: ${widget.bestFormatter?.call(widget.bestScore) ?? '${widget.bestScore}'}',
                          style: const TextStyle(
                            color: Color(0xFFF0C040),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

              // Game area with optional pause overlay
              Expanded(
                child: Stack(
                  children: [
                    widget.child,
                    if (_isPaused)
                      Container(
                        color: const Color(0xAA000000),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'Paused',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF4ECCA3),
                                  foregroundColor: const Color(0xFF1A1A2E),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 32,
                                    vertical: 12,
                                  ),
                                ),
                                onPressed: _resume,
                                child: const Text(
                                  'Resume',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextButton(
                                onPressed: _quit,
                                child: const Text(
                                  'Quit',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
