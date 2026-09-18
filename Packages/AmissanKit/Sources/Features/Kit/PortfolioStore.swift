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
  /// La phase de l'écran. Quatre cas, et pas un de plus.
  public private(set) var phase: ViewPhase<PortfolioSnapshot> = .initial

  /// Orthogonal à la phase : on rafraîchit depuis `loaded` comme depuis
  /// `failed`. En faire un cinquième cas produirait des combinaisons qu'on ne
  /// saurait pas nommer.
  public private(set) var isRefreshing = false

  public private(set) var language: Language

  private let reading: any PortfolioReading
  private let chrome: () -> AppChrome
  private var loadTask: Task<Void, Never>?

  public init(
    reading: any PortfolioReading,
    language: Language,
    chrome: @escaping () -> AppChrome
  ) {
    self.reading = reading
    self.language = language
    self.chrome = chrome
  }

  public var snapshot: PortfolioSnapshot? { phase.value }
  public var portfolio: Portfolio? { snapshot?.portfolio }

  /// Le premier chargement, ou un rechargement après changement de langue.
  ///
  /// La phase passe par `loading` **seulement s'il n'y a rien à montrer**. Un
  /// rechargement avec du contenu déjà à l'écran ne le remplace pas par un
  /// squelette : ce serait perdre ce qu'on a pour afficher une attente.
  public func load(policy: FreshnessPolicy = .networkFirst) {
    loadTask?.cancel()
    if !phase.isLoaded { phase = .loading }
    isRefreshing = phase.isLoaded

    loadTask = Task { [reading, language] in
      defer { isRefreshing = false }
      do {
        let snapshot = try await reading.portfolio(in: language, policy: policy)
        guard !Task.isCancelled else { return }
        phase = .loaded(snapshot)
      } catch let unavailable as ContentUnavailable {
        guard !Task.isCancelled else { return }
        // Un échec n'écrase jamais du contenu déjà affiché : mieux vaut du
        // contenu daté qu'un écran d'erreur à la place de quelque chose de
        // lisible.
        if !phase.isLoaded { phase = .failed(describe(unavailable)) }
      } catch {
        guard !Task.isCancelled else { return }
        if !phase.isLoaded { phase = .failed(describe(.unreachable)) }
      }
    }
  }

  /// Relecture demandée par l'utilisateur — le geste « tirer pour rafraîchir ».
  ///
  /// Elle attend réellement la fin : sans ça, l'indicateur disparaîtrait avant
  /// que le contenu n'arrive, ce qui donne l'impression que le geste n'a rien
  /// fait.
  public func refresh() async {
    load()
    await loadTask?.value
  }

  /// Change la langue affichée, et recharge dans la foulée.
  public func setLanguage(_ language: Language) {
    guard language != self.language else { return }
    self.language = language
    // Le contenu de l'autre langue n'est pas celui-ci : on repart d'une phase
    // vide plutôt que d'afficher du français en attendant l'anglais.
    phase = .loading
    load()
  }

  /// Traduit une erreur du domaine en quelque chose qu'une vue sait afficher.
  ///
  /// C'est **ici** que ça se fait, pas dans la vue : décider comment une erreur
  /// se dit est un travail de présentation, et une vue qui ferait un `switch`
  /// sur des cas du domaine serait une vue qui connaît le domaine.
  private func describe(_ failure: ContentUnavailable) -> PhaseFailure {
    let chrome = chrome()
    switch failure {
    case .unreachable:
      return PhaseFailure(
        title: chrome.unavailableTitle,
        message: chrome.unreachableMessage,
        symbol: "wifi.slash",
        isRetryable: true
      )
    case .nothingAvailable:
      return PhaseFailure(
        title: chrome.unavailableTitle,
        message: chrome.nothingAvailableMessage,
        symbol: "tray",
        isRetryable: true
      )
    case .malformed(let path, let reason):
      // Réessayer ne changerait rien : la source répondrait la même chose. Le
      // bouton est donc absent, et le message porte le diagnostic réel — c'est
      // une application de portfolio, quelqu'un qui la regarde a tout intérêt à
      // le voir.
      return PhaseFailure(
        title: chrome.unreadableTitle,
        message: chrome.malformedMessage(path: path, reason: reason),
        symbol: "exclamationmark.triangle",
        isRetryable: false
      )
    }
  }
}
