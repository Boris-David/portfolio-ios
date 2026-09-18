import DesignSystem
import Domain
import SwiftUI
import Textual

/// L'explication d'un composant, en détail.
///
/// Elle répond dans l'ordre aux questions qu'un relecteur technique poserait :
/// *qu'est-ce que c'est*, *pourquoi celui-là*, *qu'est-ce qui a été écarté*,
/// *quand l'employer*, *qu'est-ce qui casse*.
///
/// L'ordre n'est pas neutre. « Ce qui a été écarté » vient **avant** « quand
/// l'employer » parce que c'est la partie qu'on saute quand on manque de place,
/// et c'est justement celle qui distingue une décision d'un réflexe.
public struct BackstageSheet: View {
  private let note: BackstageNote
  @Environment(\.dismiss) private var dismiss
  @Environment(\.contentLanguage) private var language

  public init(note: BackstageNote) {
    self.note = note
  }

  public var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: Tokens.Space.s5) {
          header

          section(BackstageLabels.why(language)) {
            markdown(note.rationale(language))
          }

          if !note.rejected.isEmpty {
            section(BackstageLabels.rejected(language)) {
              VStack(alignment: .leading, spacing: Tokens.Space.s3) {
                ForEach(note.rejected, id: \.name) { rejected in
                  rejectedRow(rejected)
                }
              }
            }
          }

          section(BackstageLabels.whenToUse(language)) {
            markdown(note.whenToUse(language))
          }

          if let pitfall = note.pitfall {
            section(BackstageLabels.pitfall(language)) {
              HStack(alignment: .top, spacing: Tokens.Space.s3) {
                Image(systemName: "exclamationmark.triangle.fill")
                  .foregroundStyle(Color.accent)
                  .font(.footnote)
                  .padding(.top, 3)
                markdown(pitfall(language))
              }
              .padding(Tokens.Space.s4)
              .frame(maxWidth: .infinity, alignment: .leading)
              .background(
                RoundedRectangle(cornerRadius: Tokens.Radius.sm, style: .continuous)
                  .fill(Color.accentWash)
              )
            }
          }

          if let documentation = note.documentation {
            Link(destination: documentation) {
              Label(BackstageLabels.documentation(language), systemImage: "arrow.up.right")
            }
            .buttonStyle(.adaptiveGlass)
            .padding(.top, Tokens.Space.s2)
          }
        }
        .padding(Tokens.Space.s5)
      }
      .background(Color.paper)
      .navigationTitle(note.component)
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .confirmationAction) {
          Button(BackstageLabels.close(language)) { dismiss() }
        }
      }
    }
    // Une explication se lit en diagonale d'abord : une feuille à mi-hauteur
    // laisse voir le composant qu'elle décrit, et se déploie si on veut tout.
    .presentationDetents([.medium, .large])
    .presentationDragIndicator(.visible)
  }

  // ───────────────────────────────────────────────────────────────────────

  private var header: some View {
    VStack(alignment: .leading, spacing: Tokens.Space.s2) {
      Text(note.component)
        .font(Typography.code)
        .foregroundStyle(Color.accent)
      Text(note.role(language))
        .font(Typography.heading)
        .foregroundStyle(Color.ink)
        .fixedSize(horizontal: false, vertical: true)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .accessibilityElement(children: .combine)
  }

  private func section(_ title: String, @ViewBuilder content: () -> some View) -> some View {
    VStack(alignment: .leading, spacing: Tokens.Space.s3) {
      Text(title).eyebrowStyle()
      content()
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  private func rejectedRow(_ rejected: BackstageNote.Rejected) -> some View {
    HStack(alignment: .top, spacing: Tokens.Space.s3) {
      // Une barre plutôt qu'une croix : « écarté » n'est pas « mauvais ». La
      // plupart de ces candidats sont de bons outils, au mauvais endroit.
      RoundedRectangle(cornerRadius: 1)
        .fill(Color.line2)
        .frame(width: 3)
      VStack(alignment: .leading, spacing: 2) {
        Text(rejected.name(language))
          .font(Typography.bodyStrong)
          .foregroundStyle(Color.ink)
        Text(rejected.because(language))
          .font(Typography.secondary)
          .foregroundStyle(Color.ink2)
          .fixedSize(horizontal: false, vertical: true)
      }
    }
    .fixedSize(horizontal: false, vertical: true)
  }

  /// Le Markdown rendu par **Textual**, en `AttributedString` native.
  ///
  /// Pourquoi une bibliothèque plutôt que `Text(.init(markdown))` : l'initialiseur
  /// de `AttributedString` ne gère que l'**inline** — gras, code, liens. Il ne
  /// sait rien des listes ni des blocs de code, qui sont précisément ce dont une
  /// explication technique a besoin.
  ///
  /// Pourquoi Textual et pas MarkdownUI, du même auteur : MarkdownUI est passé
  /// en mode maintenance et renvoie explicitement vers Textual, qui s'appuie sur
  /// `AttributedString` — donc sur le rendu de texte du système, avec Dynamic
  /// Type et la sélection qui vont avec, au lieu d'un arbre de vues reconstruit.
  private func markdown(_ source: String) -> some View {
    StructuredText(markdown: source)
      .font(Typography.body)
      .foregroundStyle(Color.ink2)
      .frame(maxWidth: .infinity, alignment: .leading)
  }
}
