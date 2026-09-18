import Backstage
import Data
import Foundation
import DesignSystem
import Domain
import FeatureBackstage
import FeatureJourney
import FeatureKit
import FeatureProfile
import FeatureResume
import FeatureWork
import Networking
import Persistence
import SwiftUI

/// La racine de l'application : quatre onglets, et tout ce qui les alimente.
///
/// C'est le **seul** module qui voit à la fois `Data` et les fonctionnalités.
/// C'est aussi le seul endroit où l'on décide quel objet concret répond à quel
/// protocole — et donc le seul qu'il faut rouvrir pour remplacer une
/// implémentation.
public struct AppRoot: View {
  @State private var store: PortfolioStore
  @State private var backstage = BackstageController(
    // Un argument de lancement, pour ouvrir directement en mode annotations.
    //
    // Il sert aux **captures automatisées** : une capture du mode coulisses ne
    // peut pas se prendre à la main sans que quelqu'un touche l'écran, et une
    // capture qu'on ne peut pas reproduire ne finit jamais dans une CI.
    //
    //   xcrun simctl launch <appareil> dev.amissan.portfolio -backstage
    isEnabled: ProcessInfo.processInfo.arguments.contains("-backstage")
  )
  @State private var selection: FeatureKit.Section = .profile

  /// Le chrome de la racine se **dérive** directement, sans passer par
  /// l'environnement.
  ///
  /// `AppRoot` est la vue qui *pose* `\.contentLanguage` : une vue ne relit pas
  /// une valeur qu'elle installe elle-même, `.environment()` ne s'appliquant
  /// qu'aux descendants. Le défaut se voyait à l'écran — contenu anglais,
  /// onglets français.
  private var chrome: AppChrome { .for(language) }

  private let resume: any ResumeReading
  private let language: Language
  private let portfolio: any PortfolioReading

  public init(environment: AppEnvironment = .live()) {
    _store = State(initialValue: PortfolioStore(
      reading: environment.portfolio,
      language: environment.language
    ))
    self.resume = environment.resume
    self.portfolio = environment.portfolio
    self.language = environment.language
  }

  public var body: some View {
    TabView(selection: $selection) {
      Tab(value: FeatureKit.Section.profile) {
        ProfileScreen()
      } label: {
        Label(chrome.tabProfile, systemImage: FeatureKit.Section.profile.symbol)
      }

      Tab(value: FeatureKit.Section.work) {
        WorkScreen()
      } label: {
        Label(chrome.tabWork, systemImage: FeatureKit.Section.work.symbol)
      }

      Tab(value: FeatureKit.Section.journey) {
        JourneyScreen()
      } label: {
        Label(chrome.tabJourney, systemImage: FeatureKit.Section.journey.symbol)
      }

      Tab(value: FeatureKit.Section.backstage) {
        BackstageScreen()
      } label: {
        Label(chrome.tabBackstage, systemImage: FeatureKit.Section.backstage.symbol)
      }
    }
    // La barre se réduit quand on descend : le contenu est ce qu'on vient lire,
    // la navigation peut s'effacer. iOS 26 seulement ; sur iOS 18 la barre
    // reste, ce qui est son comportement normal et n'a rien d'un défaut.
    .minimizingTabBarOnScroll()
    .backstageAccessory(controller: backstage, chrome: chrome)
    .environment(\.contentLanguage, language)
    .environment(store)
    .environment(backstage)
    .environment(\.routeDestinations, routes)
    .environment(\.sheetDestinations, sheets)
    .tint(Color.accent)
    .task { store.load() }
  }

  // ───────────────────────────────────────────────────────────────────────
  // La résolution des destinations — la seule chose que les fonctionnalités
  // ne peuvent pas faire elles-mêmes, puisqu'elles ne se connaissent pas.
  // ───────────────────────────────────────────────────────────────────────

  private var routes: RouteDestinations {
    RouteDestinations { [portfolio = self.portfolio] route in
      _ = portfolio
      return AnyView(RouteView(route: route))
    }
  }

  private var sheets: SheetDestinations {
    SheetDestinations { [resume, language] sheet in
      switch sheet {
      case .resume:
        AnyView(ResumeScreen(reading: resume, language: language))
      case .contact:
        AnyView(ContactSheet())
      }
    }
  }
}

/// Résout une route en vue, en piochant dans le contenu déjà chargé.
struct RouteView: View {
  let route: Route
  @Environment(PortfolioStore.self) private var store
  @Environment(\.contentLanguage) private var language

  var body: some View {
    switch route {
    case .caseStudy(let slug):
      if let study = store.portfolio?.caseStudies.first(where: { $0.slug == slug }) {
        CaseStudyDetail(study: study)
      } else {
        // Une route vers un contenu absent : cela arrive avec un lien profond
        // reçu avant le premier chargement. On le dit, on ne montre pas un
        // écran blanc.
        ContentUnavailableView(
          language == .french ? "Contenu introuvable" : "Content not found",
          systemImage: "questionmark.folder",
          description: Text(
            language == .french
              ? "Ce projet n'existe pas dans le contenu chargé."
              : "This project is not in the loaded content."
          )
        )
      }
    default:
      EmptyView()
    }
  }
}

/// La feuille de contact.
struct ContactSheet: View {
  @Environment(PortfolioStore.self) private var store
  @Environment(\.dismiss) private var dismiss
  @Environment(\.openURL) private var openURL
  @Chrome private var chrome

  var body: some View {
    NavigationStack {
      Group {
        if let contact = store.portfolio?.profile.contact {
          ScrollView {
            VStack(alignment: .leading, spacing: Tokens.Space.s4) {
              Text(contact.title)
                .font(Typography.title)
                .foregroundStyle(Color.ink)
              Text(contact.body)
                .font(Typography.body)
                .foregroundStyle(Color.ink2)
                .fixedSize(horizontal: false, vertical: true)
              Button {
                if let url = URL(string: "mailto:\(contact.email)") { openURL(url) }
              } label: {
                Label(contact.email, systemImage: "envelope")
              }
              .buttonStyle(.adaptiveGlassProminent)
              ForEach(contact.links) { link in
                Button {
                  if let url = URL(string: link.url) { openURL(url) }
                } label: {
                  Label(link.label, systemImage: "link")
                }
                .buttonStyle(.adaptiveGlass)
              }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Tokens.Space.s5)
          }
        } else {
          LoadingSkeleton()
        }
      }
      .background(Color.paper)
      .navigationTitle(chrome.contactTitle)
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .confirmationAction) {
          Button(chrome.close) { dismiss() }
        }
      }
    }
    .presentationDetents([.medium])
  }
}

/// L'accessoire posé sous la barre d'onglets, sur iOS 26.
///
/// Il porte la bascule des annotations : c'est l'endroit que le système prévoit
/// pour un contrôle **persistant** qui accompagne toute la navigation — et
/// c'est exactement ce qu'est le mode coulisses.
private extension View {
  @ViewBuilder
  func backstageAccessory(controller: BackstageController, chrome: AppChrome) -> some View {
    if #available(iOS 26.0, *) {
      self.tabViewBottomAccessory {
        Button {
          controller.toggle()
        } label: {
          Label(
            controller.isEnabled ? chrome.backstageHide : chrome.backstageShow,
            systemImage: controller.isEnabled ? "number.circle.fill" : "number.circle"
          )
          .font(Typography.secondary)
          .frame(maxWidth: .infinity)
        }
        .tint(Color.accent)
      }
    } else {
      // Sur iOS 18 il n'y a pas d'accessoire de barre : la bascule vit dans
      // l'onglet Coulisses, où elle est de toute façon présentée et expliquée.
      // Un contrôle flottant fabriqué à la main aurait masqué du contenu et
      // dupliqué une commande qui existe déjà.
      self
    }
  }
}
