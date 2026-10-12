import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/high_score.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';
import '../widgets/game_card.dart';

/// Screen that displays all high scores across all levels.
///
/// Features:
/// - Displays scores sorted by highest score first
/// - Shows level, score, and timestamp for each entry
/// - Provides clear data functionality with confirmation dialog
/// - Shows empty state when no scores exist
class HighScoresScreen extends StatefulWidget {
  const HighScoresScreen({super.key});

  @override
  State<HighScoresScreen> createState() => _HighScoresScreenState();
}

class _HighScoresScreenState extends State<HighScoresScreen> {
  StorageService? _storageService;
  List<HighScore> _allScores = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    final storageService = Provider.of<StorageService?>(context, listen: false);
    if (storageService != null) {
      _storageService = storageService;
      _loadScores();
    } else {
      // Storage service not yet initialized
      setState(() {
        _loading = false;
      });
    }
  }

  /// Loads all high scores from all levels (1-20) and sorts them descending.
  Future<void> _loadScores() async {
    if (_storageService == null) {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
      return;
    }

    List<HighScore> scores = [];
    for (int level = 1; level <= 20; level++) {
      final levelScores = await _storageService!.getHighScores(level);
      scores.addAll(levelScores);
    }
    scores.sort((a, b) => b.score.compareTo(a.score)); // Sort descending

    if (mounted) {
      setState(() {
        _allScores = scores;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('High Scores'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _confirmClearData,
            tooltip: 'Clear all scores',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _allScores.isEmpty
              ? const Center(
                  child: Text(
                    'No high scores yet!\nPlay to set your first record.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: GameConstants.mutedColor),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _allScores.length,
                  itemBuilder: (context, index) => _scoreRow(context, index + 1, _allScores[index]),
                ),
    );
  }

  /// Shows confirmation dialog before clearing all high score data.
  /// One score in the shared card style: its rank, the score, and the level
  /// and date it was set on. The top three ranks are in gold.
  Widget _scoreRow(BuildContext context, int rank, HighScore score) {
    final text = Theme.of(context).textTheme;
    return GameCard(
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: SizedBox(
          width: 40,
          child: Text(
            '$rank',
            textAlign: TextAlign.center,
            style: text.titleLarge?.copyWith(
              color: rank <= 3 ? GameConstants.secondaryColor : GameConstants.mutedColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          '${groupedThousands(score.score)} points',
          style: text.titleMedium?.copyWith(color: GameConstants.inkColor, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${GameStrings.level} ${score.level} · ${_formatTimestamp(score.timestamp)}',
          style: text.bodySmall?.copyWith(color: GameConstants.mutedColor),
        ),
      ),
    );
  }

  void _confirmClearData() {
    if (_storageService == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Scores?'),
        content: const Text('This will delete all high score data permanently.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _storageService!.clearData();
              await _loadScores(); // Reload (will show empty)
            },
            child: Text('Clear', style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );
  }

  /// Formats timestamp as "MM/DD/YYYY HH:MM".
  String _formatTimestamp(DateTime timestamp) {
    final hour = timestamp.hour;
    final minute = timestamp.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);

    return '${timestamp.month}/${timestamp.day}/${timestamp.year} $displayHour:$minute $period';
  }
}
