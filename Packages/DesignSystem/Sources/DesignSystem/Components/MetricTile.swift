import SwiftUI

/// Un chiffre mis en avant, et ce qu'il signifie.
///
/// Le nombre **se compte** à l'arrivée à l'écran — quand la source le demande.
/// Ce n'est pas une déduction sur sa forme : « ~5 » pourrait s'animer, on
/// choisit que non parce qu'animer une approximation lui donne une précision
/// qu'elle n'a pas.
public struct MetricTile: View {
  private let value: String
  private let unit: String?
  private let caption: String
  private let countTo: Int?

  @State private var displayed: Double = 0
  @State private var hasAppeared = false
  @ReducedMotion private var reducedMotion

  public init(value: String, unit: String?, caption: String, countTo: Int? = nil) {
    self.value = value
    self.unit = unit
    self.caption = caption
    self.countTo = countTo
  }

  public var body: some View {
    VStack(alignment: .leading, spacing: Tokens.Space.s2) {
      HStack(alignment: .firstTextBaseline, spacing: Tokens.Space.s1) {
        Text(renderedValue)
          .font(Typography.metric)
          .foregroundStyle(Color.ink)
          // Les chiffres qui changent doivent occuper une largeur stable,
          // sinon la tuile tremble pendant tout le décompte.
          .monospacedDigit()
          .contentTransition(.numericText())
        if let unit {
          Text(unit)
            .font(Typography.heading)
            .foregroundStyle(Color.accent)
        }
      }
      Text(caption)
        .font(Typography.caption)
        .foregroundStyle(Color.ink3)
        .fixedSize(horizontal: false, vertical: true)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    // Un chiffre et sa légende sont **une** information. Séparés, VoiceOver
    // annonce « 6 » puis, plus loin, « d'ingénierie iOS » — deux fragments dont
    // aucun ne veut rien dire.
    .accessibilityElement(children: .combine)
    .accessibilityLabel("\(value) \(unit ?? "") \(caption)")
    .onAppear(perform: startCounting)
  }

  private var renderedValue: String {
    guard let countTo, hasAppeared, !reducedMotion else { return value }
    return displayed >= Double(countTo) ? value : String(Int(displayed))
  }

  private func startCounting() {
    guard let countTo, !hasAppeared, !reducedMotion else { return }
    hasAppeared = true
    withAnimation(Motion.animation(Tokens.Ease.out, duration: Tokens.Duration.counter)) {
      displayed = Double(countTo)
    }
  }
}
