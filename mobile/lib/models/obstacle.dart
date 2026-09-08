/// The 4 difficulty obstacles, per 05-mecaniques-de-jeu.md. No tutorial is
/// planned for any of them -- players learn by playing.
///
/// This only models the static data (unlock level, hit counts, asset per
/// state) needed once the board engine exists; it doesn't implement board
/// placement or match detection, which depend on 11-ecran-de-jeu.md.
enum ObstacleKind {
  vitrineVerre,
  caramel,
  cookie,
  macaron;

  /// Level at which this obstacle starts appearing.
  int get minLevel {
    switch (this) {
      case ObstacleKind.vitrineVerre:
        return 3;
      case ObstacleKind.caramel:
        return 10;
      case ObstacleKind.cookie:
        return 30;
      case ObstacleKind.macaron:
        return 50;
    }
  }

  /// Hits needed to clear it, or null if it never breaks (macaron).
  int? get hitsToBreak {
    switch (this) {
      case ObstacleKind.vitrineVerre:
        return 1;
      case ObstacleKind.caramel:
        return 2;
      case ObstacleKind.cookie:
        return 3;
      case ObstacleKind.macaron:
        return null;
    }
  }

  /// Ignores gravity and can never be removed for the level's duration.
  bool get isPermanent => this == ObstacleKind.macaron;
}

/// Glass showcase (niveau 3+): encloses one board element. A single
/// adjacent match breaks it in one hit, freeing the element underneath.
class VitrineVerreObstacle {
  VitrineVerreObstacle._();
  static const String assetName = 'assets/obstacles/obstacle-vitrine-verre.png';
}

/// Caramel block (niveau 10+, 2 hits): 1st adjacent match turns it into a
/// melted splash (1s animation); 2nd match shrinks the splash away (1s),
/// after which the element underneath is usable and gravity applies.
enum CaramelState {
  intact,
  splash;

  String get assetName {
    switch (this) {
      case CaramelState.intact:
        return 'assets/obstacles/obstacle-caramel-intact.png';
      case CaramelState.splash:
        return 'assets/obstacles/obstacle-caramel-splash.png';
    }
  }
}

/// Chocolate chip cookie (niveau 30+, 3 hits): hides nothing, just blocks
/// the cell. Crumbles progressively over 3 hits until it disappears.
enum CookieState {
  intact,
  hit1,
  hit2,
  hit3;

  String get assetName {
    switch (this) {
      case CookieState.intact:
        return 'assets/obstacles/obstacle-cookie-etat1.png';
      case CookieState.hit1:
        return 'assets/obstacles/obstacle-cookie-etat2.png';
      case CookieState.hit2:
        return 'assets/obstacles/obstacle-cookie-etat3.png';
      case CookieState.hit3:
        return 'assets/obstacles/obstacle-cookie-etat4.png';
    }
  }
}

/// Macaron (niveau 50+): permanent for the whole level. Never moves
/// (ignores gravity), never breaks, never removable.
class MacaronObstacle {
  MacaronObstacle._();
  static const String assetName = 'assets/obstacles/obstacle-macaron.png';
}
