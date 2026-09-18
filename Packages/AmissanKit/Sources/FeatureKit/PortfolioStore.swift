import Domain
import Foundation
import Observation

/// L'état du contenu, pour tous les écrans.
///
/// ## Un seul magasin, pas un par écran
///
/// Quatre onglets affichent le même portfolio. Quatre magasins, ce seraient
/// quatre lectures, quatre instants possibles de rafraîchissement, et un onglet
/// qui montre une version pendant qu'un autre en montre une seconde. Personne ne
/// le verrait jamais — ce qui est précisément le problème.
///
/// ## `@MainActor` sur la classe entière
///
/// Elle n'existe que pour alimenter des vues. Isoler la classe au lieu de
/// marquer chaque propriété évite la question à chaque ajout, et le compilateur
/// refuse alors toute lecture depuis un autre contexte — ce qui est la garantie
/// qu'on cherche, pas un `DispatchQueue.main.async` posé par habitude.
@Observable
@MainActor
public final class PortfolioStore {
  public enum State {
    /// Premier chargement, rien à afficher encore.
    case loading
    /// Du contenu est là — de la source, du cache ou de la graine.
    case ready(PortfolioSnapshot)
    /// Rien du tout. Le seul cas qui mérite un écran d'erreur plein.
    case failed(ContentUnavailable)
  }

  public private(set) var state: State = .loading

  public let language: Language
  private let reading: any PortfolioReading
  private var loadTask: Task<Void, Never>?

  public init(reading: any PortfolioReading, language: Language) {
    self.reading = reading
    self.language = language
  }

  /// Le contenu actuellement affichable, s'il y en a un.
  public var snapshot: PortfolioSnapshot? {
    if case .ready(let snapshot) = state { snapshot } else { nil }
  }

  public var portfolio: Portfolio? { snapshot?.portfolio }

  /// Lance — ou relance — la lecture.
  ///
  /// Une tâche précédente encore en vol est **annulée** : deux lectures
  /// concurrentes pourraient livrer leurs instantanés dans le désordre, et le
  /// plus ancien écraserait le plus récent.
  public func load() {
    loadTask?.cancel()
    loadTask = Task { [reading, language] in
      do {
        for try await snapshot in reading.portfolio(in: language) {
          guard !Task.isCancelled else { return }
          state = .ready(snapshot)
        }
      } catch let unavailable as ContentUnavailable {
        // Un échec n'écrase jamais du contenu déjà affiché : mieux vaut du
        // contenu daté qu'un écran d'erreur à la place de quelque chose de
        // lisible.
        if snapshot == nil { state = .failed(unavailable) }
      } catch {
        if snapshot == nil { state = .failed(.unreachable) }
      }
    }
  }

  /// Relecture demandée par l'utilisateur — le geste « tirer pour rafraîchir ».
  ///
  /// Elle attend réellement la fin : sans ça, l'indicateur de rafraîchissement
  /// disparaîtrait avant que le contenu n'arrive, ce qui donne l'impression que
  /// le geste n'a rien fait.
  public func refresh() async {
    load()
    await loadTask?.value
  }
}
