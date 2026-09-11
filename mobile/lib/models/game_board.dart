import 'dart:math';

import 'game_element.dart';

/// A board cell's coordinates. `x` is the column, `y` is the row -- matches
/// screen axes (x horizontal, y vertical), not matrix (row, col) order,
/// since this ends up mapped straight to pixel `Offset`s in the screen.
class BoardPoint {
  const BoardPoint(this.x, this.y);

  final int x;
  final int y;

  bool isAdjacentTo(BoardPoint other) {
    final dx = (x - other.x).abs();
    final dy = (y - other.y).abs();
    return (dx == 1 && dy == 0) || (dx == 0 && dy == 1);
  }

  @override
  bool operator ==(Object other) => other is BoardPoint && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(x, y);
}

/// Aggregate result of resolving every match/cascade wave after one valid
/// swap (or one shuffle-triggered match, though a fresh shuffle is defined
/// to never start with a match already on the board). Only the totals
/// needed by the mission counter and the star-dust bar survive here --
/// per-wave/per-cell detail would matter for a richer cascade animation,
/// which is deferred (see 11-ecran-de-jeu.md's README section).
class CascadeResult {
  const CascadeResult({required this.clearedByElement, required this.waves});

  final Map<GameElement, int> clearedByElement;

  /// Number of clear-then-refill passes it took to settle -- 1 for a
  /// simple match, more for a cascade where falling pieces create a new
  /// match on their own.
  final int waves;

  int get totalCleared => clearedByElement.values.fold(0, (a, b) => a + b);
}

/// The match-3 grid itself: state, swap validation, match detection,
/// gravity/refill, and deadlock handling. Per 11-ecran-de-jeu.md; this is
/// the "cœur" pass only -- special pieces (05-mecaniques-de-jeu.md),
/// obstacles, and delivery objectives don't interact with the board yet,
/// so every cell is a plain `GameElement` and every match just clears
/// (see mobile/README.md for the full deferred list).
class GameBoard {
  GameBoard({required this.rows, required this.cols, int? seed})
      : _rng = Random(seed) {
    _grid = List.generate(rows, (_) => List.generate(cols, (_) => _randomElement()));
    _removeInitialMatches();
    // A freshly generated board that happens to have no legal move at all
    // is vanishingly rare but not impossible on a small grid -- reroll
    // rather than open on an already-blocked board.
    while (!hasAnyValidMove()) {
      _grid = List.generate(rows, (_) => List.generate(cols, (_) => _randomElement()));
      _removeInitialMatches();
    }
  }

  final int rows;
  final int cols;
  final Random _rng;
  late List<List<GameElement>> _grid;

  GameElement elementAt(BoardPoint p) => _grid[p.y][p.x];

  GameElement _randomElement() => GameElement.values[_rng.nextInt(GameElement.values.length)];

  bool _inBounds(int x, int y) => x >= 0 && x < cols && y >= 0 && y < rows;

  /// Replaces any cell that would already form a 3-match at generation
  /// time (checking only already-filled left/up neighbors, since the grid
  /// fills in row-major order) so the board never opens mid-match.
  void _removeInitialMatches() {
    for (var y = 0; y < rows; y++) {
      for (var x = 0; x < cols; x++) {
        while (_createsMatchIfPlaced(x, y, _grid[y][x])) {
          _grid[y][x] = _randomElement();
        }
      }
    }
  }

  bool _createsMatchIfPlaced(int x, int y, GameElement element) {
    if (x >= 2 && _grid[y][x - 1] == element && _grid[y][x - 2] == element) return true;
    if (y >= 2 && _grid[y - 1][x] == element && _grid[y - 2][x] == element) return true;
    return false;
  }

  void _swapCells(BoardPoint a, BoardPoint b) {
    final tmp = _grid[a.y][a.x];
    _grid[a.y][a.x] = _grid[b.y][b.x];
    _grid[b.y][b.x] = tmp;
  }

  /// Swaps [a] and [b] if adjacent and the swap creates at least one
  /// match; reverts and returns false otherwise (the caller plays the
  /// spec's "effet de rebond" for that case). On a true return, the board
  /// is left mid-match -- call [resolveCascade] next.
  bool trySwap(BoardPoint a, BoardPoint b) {
    if (!a.isAdjacentTo(b)) return false;
    _swapCells(a, b);
    if (_findAllMatchedCells().isEmpty) {
      _swapCells(a, b);
      return false;
    }
    return true;
  }

  Set<BoardPoint> _findAllMatchedCells() {
    final matched = <BoardPoint>{};

    for (var y = 0; y < rows; y++) {
      var runStart = 0;
      for (var x = 1; x <= cols; x++) {
        final broke = x == cols || _grid[y][x] != _grid[y][runStart];
        if (broke) {
          if (x - runStart >= 3) {
            for (var i = runStart; i < x; i++) matched.add(BoardPoint(i, y));
          }
          runStart = x;
        }
      }
    }

    for (var x = 0; x < cols; x++) {
      var runStart = 0;
      for (var y = 1; y <= rows; y++) {
        final broke = y == rows || _grid[y][x] != _grid[runStart][x];
        if (broke) {
          if (y - runStart >= 3) {
            for (var i = runStart; i < y; i++) matched.add(BoardPoint(x, i));
          }
          runStart = y;
        }
      }
    }

    return matched;
  }

  /// Clears every matched cell, drops survivors down within their column,
  /// and refills the vacated top with new random elements -- repeating
  /// while the settled board still has matches (a real cascade, e.g. a
  /// falling piece landing on two of its own kind). Returns the aggregate
  /// counts the mission tracker and star-dust bar need.
  CascadeResult resolveCascade() {
    final clearedByElement = <GameElement, int>{};
    var waves = 0;

    while (true) {
      final matched = _findAllMatchedCells();
      if (matched.isEmpty) break;
      waves++;
      for (final p in matched) {
        final element = _grid[p.y][p.x];
        clearedByElement.update(element, (v) => v + 1, ifAbsent: () => 1);
      }
      _collapseColumns(matched);
    }

    return CascadeResult(clearedByElement: clearedByElement, waves: waves);
  }

  void _collapseColumns(Set<BoardPoint> matched) {
    for (var x = 0; x < cols; x++) {
      final survivors = <GameElement>[];
      for (var y = rows - 1; y >= 0; y--) {
        if (!matched.contains(BoardPoint(x, y))) survivors.add(_grid[y][x]);
      }
      for (var y = rows - 1; y >= 0; y--) {
        final survivorIndex = (rows - 1) - y;
        _grid[y][x] = survivorIndex < survivors.length ? survivors[survivorIndex] : _randomElement();
      }
    }
  }

  /// True if at least one adjacent swap anywhere on the board would
  /// create a match -- checked by actually trying every pair and
  /// reverting, which is cheap enough at these board sizes (at most a few
  /// hundred candidate pairs, each an O(rows·cols) match scan).
  bool hasAnyValidMove() {
    for (var y = 0; y < rows; y++) {
      for (var x = 0; x < cols; x++) {
        final a = BoardPoint(x, y);
        if (x + 1 < cols) {
          final b = BoardPoint(x + 1, y);
          _swapCells(a, b);
          final matches = _findAllMatchedCells().isNotEmpty;
          _swapCells(a, b);
          if (matches) return true;
        }
        if (y + 1 < rows) {
          final b = BoardPoint(x, y + 1);
          _swapCells(a, b);
          final matches = _findAllMatchedCells().isNotEmpty;
          _swapCells(a, b);
          if (matches) return true;
        }
      }
    }
    return false;
  }

  /// "Plateau bloqué": reshuffles every element currently on the board
  /// (not fresh random ones -- a real shuffle of the existing pieces) into
  /// a new arrangement that has no pre-existing match and does have at
  /// least one legal move, per "tous les éléments se mélangent puis se
  /// replacent (nouvelle disposition jouable)."
  void shuffleUntilPlayable() {
    final flat = <GameElement>[for (final row in _grid) ...row];
    do {
      flat.shuffle(_rng);
      var i = 0;
      for (var y = 0; y < rows; y++) {
        for (var x = 0; x < cols; x++) {
          _grid[y][x] = flat[i++];
        }
      }
    } while (_findAllMatchedCells().isNotEmpty || !hasAnyValidMove());
  }
}
