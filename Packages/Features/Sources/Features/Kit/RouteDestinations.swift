import Backstage
import DesignSystem
import Presentation
import SwiftUI

/// Qui sait construire l'écran d'une route.
///
/// ## Le problème que ça résout
///
/// `FeatureProfile` doit pouvoir ouvrir l'étude de cas KCalories — la capture
/// de l'accueil y renvoie. Mais cette étude vit dans `FeatureWork`, et les deux
/// modules sont **sœurs** : aucune ne peut importer l'autre, et c'est
/// exactement ce qu'on veut. Deux fonctionnalités qui se connaissent finissent
/// par ne plus pouvoir être livrées séparément.
///
/// Trois façons de s'en sortir :
///
/// 1. *fusionner les deux modules* — on perd la frontière pour un seul lien ;
/// 2. *remonter les vues dans `FeatureKit`* — tout finit dans le module commun,
///    qui redevient le monolithe qu'on voulait éviter ;
/// 3. **injecter la résolution** — chaque fonctionnalité déclare une *valeur*
///    de route, et la racine de composition, qui est la seule à tout voir,
///    fournit de quoi la transformer en vue.
///
/// C'est la troisième. Le prix est un `AnyView` à la frontière de navigation :
/// une indirection par poussée, sur un chemin qui n'est ni chaud ni fréquent.
public struct RouteDestinations: Sendable {
  private let build: @MainActor @Sendable (Route) -> AnyView

  public init(build: @escaping @MainActor @Sendable (Route) -> AnyView) {
    self.build = build
  }

  @MainActor
  public func callAsFunction(_ route: Route) -> AnyView {
    build(route)
  }
}

/// Qui sait présenter une feuille.
public struct SheetDestinations: Sendable {
  private let build: @MainActor @Sendable (Sheet) -> AnyView

  public init(build: @escaping @MainActor @Sendable (Sheet) -> AnyView) {
    self.build = build
  }

  @MainActor
  public func callAsFunction(_ sheet: Sheet) -> AnyView {
    build(sheet)
  }
}

public extension EnvironmentValues {
  /// Par défaut, rien — une application qui oublierait de câbler la résolution
  /// montrerait des écrans vides, ce qui se voit immédiatement au premier essai.
  @Entry var routeDestinations = RouteDestinations { _ in AnyView(EmptyView()) }
  @Entry var sheetDestinations = SheetDestinations { _ in AnyView(EmptyView()) }
}

/// La coquille commune à chaque onglet : une pile, ses destinations, ses
/// feuilles, et la couche d'annotations.
///
/// Écrite une fois plutôt que recopiée dans les quatre onglets. Ce n'est pas
/// qu'une économie : `.navigationDestination(for:)` doit être déclaré **une
/// seule fois par pile et par type**, et le déclarer deux fois produit un
/// comportement que SwiftUI ne définit pas — il choisit, sans avertir.
public struct SectionShell<Content: View>: View {
  private let title: String
  private let content: Content

  @Environment(\.routeDestinations) private var routes
  @Environment(\.sheetDestinations) private var sheets
  @State private var router = Router()

  public init(title: String, @ViewBuilder content: () -> Content) {
    self.title = title
    self.content = content()
  }

  public var body: some View {
    @Bindable var router = router

    NavigationStack(path: $router.path) {
      content
        .background(Color.paper)
        .navigationTitle(title)
        // `.inline` partout, y compris à la racine : un grand titre qui se
        // réduit au défilement fait bouger la mise en page pendant qu'on lit,
        // et l'application a déjà ses propres en-têtes de section.
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: Route.self) { route in
          routes(route)
            // La barre d'onglets se masque sur les écrans poussés : ils sont
            // une lecture, pas une destination entre lesquelles on navigue.
            .toolbar(.hidden, for: .tabBar)
        }
    }
    .sheet(item: $router.sheet) { sheets($0) }
    .environment(router)
    .backstageOverlay()
  }
}
