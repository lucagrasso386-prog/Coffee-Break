import Foundation

/// The 4 difficulty obstacles, per 05-mecaniques-de-jeu.md. No tutorial is
/// planned for any of them -- players learn by playing.
///
/// This only models the static data (unlock level, hit counts, asset per
/// state) needed once the board engine exists; it doesn't implement board
/// placement or match detection, which depend on 11-ecran-de-jeu.md.
enum ObstacleKind: CaseIterable {
    case vitrineVerre
    case caramel
    case cookie
    case macaron

    /// Level at which this obstacle starts appearing.
    var minLevel: Int {
        switch self {
        case .vitrineVerre: return 3
        case .caramel: return 10
        case .cookie: return 30
        case .macaron: return 50
        }
    }

    /// Hits needed to clear it, or nil if it never breaks (macaron).
    var hitsToBreak: Int? {
        switch self {
        case .vitrineVerre: return 1
        case .caramel: return 2
        case .cookie: return 3
        case .macaron: return nil
        }
    }

    /// Ignores gravity and can never be removed for the level's duration.
    var isPermanent: Bool { self == .macaron }
}

/// Glass showcase (niveau 3+): encloses one board element. A single
/// adjacent match breaks it in one hit, freeing the element underneath.
enum VitrineVerreObstacle {
    static let assetName = "obstacle-vitrine-verre"
}

/// Caramel block (niveau 10+, 2 hits): 1st adjacent match turns it into a
/// melted splash (1s animation); 2nd match shrinks the splash away (1s),
/// after which the element underneath is usable and gravity applies.
enum CaramelObstacle {
    enum State: Int, CaseIterable {
        case intact = 0
        case splash = 1
    }

    static func assetName(for state: State) -> String {
        switch state {
        case .intact: return "obstacle-caramel-intact"
        case .splash: return "obstacle-caramel-splash"
        }
    }
}

/// Chocolate chip cookie (niveau 30+, 3 hits): hides nothing, just blocks
/// the cell. Crumbles progressively over 3 hits until it disappears.
enum CookieObstacle {
    enum State: Int, CaseIterable {
        case intact = 0
        case hit1 = 1
        case hit2 = 2
        case hit3 = 3
    }

    static func assetName(for state: State) -> String {
        switch state {
        case .intact: return "obstacle-cookie-etat1"
        case .hit1: return "obstacle-cookie-etat2"
        case .hit2: return "obstacle-cookie-etat3"
        case .hit3: return "obstacle-cookie-etat4"
        }
    }
}

/// Macaron (niveau 50+): permanent for the whole level. Never moves
/// (ignores gravity), never breaks, never removable.
enum MacaronObstacle {
    static let assetName = "obstacle-macaron"
}
