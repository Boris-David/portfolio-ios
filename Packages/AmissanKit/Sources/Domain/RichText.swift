import Foundation

/// Du texte porteur d'emphases, indépendant de la façon dont on le rendra.
///
/// La source sert des **segments typés** plutôt qu'une chaîne balisée. C'est un
/// choix qui se paie une fois et se rembourse partout : il n'y a pas de
/// grammaire à analyser, donc pas d'échappement à prévoir, donc pas de texte
/// déformé par un `**` qui traînerait dans une phrase.
///
/// Le domaine ne connaît ni `AttributedString`, ni SwiftUI, ni HTML. Il dit
/// *« ce fragment est important »*, pas *« ce fragment est en gras »* — la
/// différence compte le jour où « important » veut dire une couleur sur un
/// écran, une graisse dans un PDF, et une annonce VoiceOver.
public struct RichText: Sendable, Hashable {
  public struct Span: Sendable, Hashable {
    public enum Emphasis: Sendable, Hashable {
      /// Le fil du texte.
      case plain
      /// Ce qu'un lecteur pressé doit voir sans lire le reste.
      case strong
      /// Un terme technique cité comme tel : `actor`, `async/await`.
      case code
    }

    public let text: String
    public let emphasis: Emphasis

    public init(text: String, emphasis: Emphasis) {
      self.text = text
      self.emphasis = emphasis
    }
  }

  public let spans: [Span]

  public init(spans: [Span]) {
    self.spans = spans
  }

  /// Le texte nu — pour les `accessibilityLabel`, les titres et tout ce qui ne
  /// sait pas porter d'emphase.
  public var plain: String {
    spans.map(\.text).joined()
  }

  public var isEmpty: Bool {
    plain.isEmpty
  }
}

extension RichText: ExpressibleByStringLiteral {
  /// Confort d'écriture pour les tests et les aperçus — jamais pour du contenu
  /// publié, qui vient toujours de la source.
  public init(stringLiteral value: String) {
    self.init(spans: [Span(text: value, emphasis: .plain)])
  }
}


/// Un texte dans les deux langues servies, gardées **côte à côte**.
///
/// Deux tableaux parallèles — un français, un anglais — auraient laissé dériver
/// l'un sans l'autre : on corrige une phrase, on oublie sa traduction, et rien
/// ne le signale. Ici les deux versions sont dans la même déclaration, à deux
/// lignes d'écart, et un test vérifie qu'aucune n'est vide.
///
/// Ça ne remplace pas un catalogue de chaînes pour une application ordinaire.
/// Ça le remplace **ici**, parce que la langue affichée est celle du contenu
/// servi par la source, pas celle de l'appareil — et que les deux doivent être
/// incapables de diverger.
public struct Bilingual: Sendable, Hashable, ExpressibleByStringLiteral {
  public let fr: String
  public let en: String

  public init(fr: String, en: String) {
    self.fr = fr
    self.en = en
  }

  /// Une chaîne identique dans les deux langues — un nom de composant, un
  /// identifiant. Pas une traduction oubliée : une chaîne qui n'en a pas besoin.
  public init(stringLiteral value: String) {
    self.fr = value
    self.en = value
  }

  public func callAsFunction(_ language: Language) -> String {
    switch language {
    case .french: fr
    case .english: en
    }
  }

  public var isComplete: Bool {
    !fr.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
      && !en.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
  }
}
