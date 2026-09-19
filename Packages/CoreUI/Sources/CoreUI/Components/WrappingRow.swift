import DesignSystem
import SwiftUI

/// A row of chips that wraps.
///
/// SwiftUI has no native `FlowLayout`, and a `LazyVGrid` does not fit: it
/// imposes equal-width columns, whereas these chips run from two to twenty
/// characters. Hence a hand-written layout — sixty lines that do exactly one
/// thing.
public struct WrappingRow: Layout {
  private let spacing: CGFloat
  private let lineSpacing: CGFloat

  public init(spacing: CGFloat = Tokens.Space.s2, lineSpacing: CGFloat = Tokens.Space.s2) {
    self.spacing = spacing
    self.lineSpacing = lineSpacing
  }

  public func sizeThatFits(
    proposal: ProposedViewSize,
    subviews: Subviews,
    cache: inout Void
  ) -> CGSize {
    let width = proposal.width ?? .infinity
    let rows = layout(subviews: subviews, in: width)
    let height = rows.reduce(0) { $0 + $1.height } + lineSpacing * CGFloat(max(0, rows.count - 1))
    return CGSize(width: proposal.width ?? rows.map(\.width).max() ?? 0, height: height)
  }

  public func placeSubviews(
    in bounds: CGRect,
    proposal: ProposedViewSize,
    subviews: Subviews,
    cache: inout Void
  ) {
    var y = bounds.minY
    for row in layout(subviews: subviews, in: bounds.width) {
      var x = bounds.minX
      for index in row.indices {
        let size = subviews[index].sizeThatFits(.unspecified)
        subviews[index].place(
          at: CGPoint(x: x, y: y + (row.height - size.height) / 2),
          proposal: ProposedViewSize(size)
        )
        x += size.width + spacing
      }
      y += row.height + lineSpacing
    }
  }

  private struct Row {
    var indices: [Int] = []
    var width: CGFloat = 0
    var height: CGFloat = 0
  }

  private func layout(subviews: Subviews, in width: CGFloat) -> [Row] {
    var rows: [Row] = []
    var current = Row()

    for index in subviews.indices {
      let size = subviews[index].sizeThatFits(.unspecified)
      let needed = current.indices.isEmpty ? size.width : current.width + spacing + size.width

      if needed > width, !current.indices.isEmpty {
        rows.append(current)
        current = Row()
      }
      current.width = current.indices.isEmpty ? size.width : current.width + spacing + size.width
      current.height = max(current.height, size.height)
      current.indices.append(index)
    }
    if !current.indices.isEmpty { rows.append(current) }
    return rows
  }
}
