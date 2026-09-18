import SwiftUI
import DesignSystem
import Domain

/// Les pastilles numérotées, posées au-dessus des composants annotés.
///
/// ## Pourquoi des ancres, et pas un `ZStack` par composant
///
/// Poser la pastille dans la vue annotée aurait obligé chaque composant à
/// prévoir une place pour elle — donc à changer de mise en page selon que le
/// mode est actif ou non. Les ancres laissent la vue **intacte** et dessinent
/// par-dessus, dans une couche qui connaît la géométrie de tout l'écran.
///
/// C'est aussi ce qui permet de numéroter **dans l'ordre de lecture** : les
/// pastilles sont triées par position verticale, pas par ordre de déclaration.
/// Sans ce tri, un composant déclaré plus bas mais affiché plus haut porterait
/// un numéro incohérent avec ce qu'on lit.
public struct BackstageOverlay: ViewModifier {
  @Environment(BackstageController.self) private var backstage
  @ReducedMotion private var reducedMotion
  @Environment(\.contentLanguage) private var language

  public init() {}

  public func body(content: Content) -> some View {
    content
      .overlayPreferenceValue(BackstagePinsKey.self) { pins in
        GeometryReader { proxy in
          let ordered = pins
            .map { (pin: $0, rect: proxy[$0.anchor]) }
            .sorted { ($0.rect.minY, $0.rect.minX) < ($1.rect.minY, $1.rect.minX) }

          ForEach(Array(ordered.enumerated()), id: \.element.pin.note.id) { index, entry in
            // Le **cadre** d'abord : il montre ce qui est annoté. Une pastille
            // seule laisse deviner à quoi elle se rapporte, et une pastille
            // mal placée ne se voit pas — c'est arrivé, et c'est ce qui a
            // motivé ce rendu.
            RoundedRectangle(cornerRadius: Tokens.Radius.sm, style: .continuous)
              .strokeBorder(Color.accent.opacity(Tokens.Opacity.annotation), style: StrokeStyle(lineWidth: Tokens.Stroke.regular, dash: [4, 3]))
              .frame(width: entry.rect.width, height: entry.rect.height)
              .position(x: entry.rect.midX, y: entry.rect.midY)
              .allowsHitTesting(false)

            badge(number: index + 1, note: entry.pin.note)
              .position(
                x: min(entry.rect.maxX - Tokens.Space.s2, proxy.size.width - Tokens.Space.s5),
                y: entry.rect.minY + Tokens.Space.s2
              )
          }
        }
        .allowsHitTesting(backstage.isEnabled)
        .opacity(backstage.isEnabled ? 1 : 0)
        .animation(reducedMotion ? nil : Motion.toggle, value: backstage.isEnabled)
      }
      .sheet(item: Binding(
        get: { backstage.presented },
        set: { backstage.presented = $0 }
      )) { note in
        BackstageSheet(note: note)
      }
  }

  private func badge(number: Int, note: BackstageNote) -> some View {
    Button {
      backstage.present(note)
    } label: {
      Text("\(number)")
        .font(.system(size: Tokens.Icon.caption, weight: .bold, design: .rounded))
        .monospacedDigit()
        .foregroundStyle(Color.onAccent)
        .frame(width: 26, height: 26)
        .background(Circle().fill(Color.accent))
        .overlay(Circle().strokeBorder(Color.paper, lineWidth: Tokens.Stroke.regular * 2))
    }
    // La pastille fait 26 points de côté, la cible tactile 44 : le reste est
    // une surface transparente. Une pastille qu'on doit viser est une pastille
    // sur laquelle personne n'appuie.
    .frame(
      width: Tokens.Accessibility.minimumTouchTarget,
      height: Tokens.Accessibility.minimumTouchTarget
    )
    .contentShape(Circle())
    .accessibilityLabel(BackstageLabels.annotation(number, note.component, language))
    .accessibilityHint(BackstageLabels.hint(language))
  }
}

public extension View {
  /// Active la couche d'annotations sur cet écran.
  ///
  /// À poser **une fois par écran**, au niveau le plus haut : c'est là que la
  /// géométrie de tout le contenu est connue.
  func backstageOverlay() -> some View {
    modifier(BackstageOverlay())
  }
}
