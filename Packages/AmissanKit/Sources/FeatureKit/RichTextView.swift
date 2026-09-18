import DesignSystem
import Domain
import SwiftUI

/// Le texte riche du domaine, rendu.
///
/// ## Pourquoi un seul `Text`, et pas un `HStack` de fragments
///
/// Concaténer des `Text` avec `+` produit **un** run de texte : il se justifie,
/// se coupe et s'aligne comme un paragraphe normal. Un `HStack` de fragments
/// aurait cassé la ligne entre les emphases — un mot en gras aurait sauté à la
/// ligne suivante tout seul — et rendu la sélection impossible.
///
/// C'est aussi ce qui garde VoiceOver correct : un paragraphe se lit d'un
/// souffle, pas en huit annonces séparées.
///
/// Ce composant vit dans `FeatureKit` et non dans `DesignSystem` : il connaît
/// `RichText`, qui est un type du **domaine**. Un design system qui connaît le
/// domaine de son application cesse d'être réutilisable ailleurs.
public struct RichTextView: View {
  private let value: RichText
  private let font: Font
  private let color: Color

  public init(_ value: RichText, font: Font = Typography.body, color: Color = .ink2) {
    self.value = value
    self.font = font
    self.color = color
  }

  public var body: some View {
    value.spans.reduce(Text("")) { accumulated, span in
      accumulated + styled(span)
    }
    .font(font)
    .foregroundStyle(color)
    .fixedSize(horizontal: false, vertical: true)
  }

  private func styled(_ span: RichText.Span) -> Text {
    switch span.emphasis {
    case .plain:
      Text(span.text)
    case .strong:
      // La graisse **et** l'encre principale : le gras seul ne suffit pas à
      // détacher un fragment d'un paragraphe en encre secondaire.
      Text(span.text).fontWeight(.semibold).foregroundColor(.ink)
    case .code:
      Text(span.text).font(Typography.code).foregroundColor(.accent)
    }
  }
}
