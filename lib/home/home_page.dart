import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'game_registry.dart';
import 'game_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isGridMode = true;

  @override
  void initState() {
    super.initState();
    _loadViewMode();
  }

  Future<void> _loadViewMode() async {
    final prefs = await SharedPreferences.getInstance();
    final mode = prefs.getString('home_view_mode') ?? 'grid';
    setState(() {
      _isGridMode = mode == 'grid';
    });
  }

  Future<void> _setViewMode(bool gridMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('home_view_mode', gridMode ? 'grid' : 'list');
    setState(() {
      _isGridMode = gridMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mini Play'),
        actions: [
          IconButton(
            icon: Icon(
              Icons.grid_view,
              color: _isGridMode ? const Color(0xFF4ECCA3) : Colors.grey,
            ),
            onPressed: () => _setViewMode(true),
          ),
          IconButton(
            icon: Icon(
              Icons.list,
              color: !_isGridMode ? const Color(0xFF4ECCA3) : Colors.grey,
            ),
            onPressed: () => _setViewMode(false),
          ),
        ],
      ),
      body: _isGridMode ? _buildGridView() : _buildListView(),
    );
  }

  Widget _buildGridView() {
    final games = GameRegistry.games;
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth < 600
            ? 2
            : constraints.maxWidth < 900
                ? 3
                : 4;
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 1.0,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: games.length,
          itemBuilder: (context, index) {
            return GameCard(game: games[index], isGridMode: true);
          },
        );
      },
    );
  }

  Widget _buildListView() {
    final phases = GameRegistry.games.map((g) => g.phase).toSet().toList()
      ..sort();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final phase in phases) ...[
          Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 8),
            child: Text(
              'PHASE $phase',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.5,
              ),
            ),
          ),
          for (final game in GameRegistry.byPhase(phase))
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: GameCard(game: game, isGridMode: false),
            ),
        ],
      ],
    );
  }
}
