import Domain
import Foundation

/// Une annotation de coulisses : pourquoi **ce** composant, ici.
///
/// C'est le cœur de l'application. Un portfolio qui montre des écrans montre un
/// résultat ; celui-ci montre les **décisions** qui y mènent — et une décision
/// se juge à ce qu'elle a écarté autant qu'à ce qu'elle a retenu.
///
/// La structure n'est pas libre, et c'est voulu : chaque champ est une question
/// qu'un relecteur technique poserait de toute façon. Un champ vide se voit, ce
/// qui est exactement le but — une note qui ne sait pas dire ce qu'elle a
/// écarté n'est pas encore une décision, c'est un réflexe.
public struct BackstageNote: Identifiable, Sendable, Hashable {
  /// Ce qui a été envisagé, puis écarté.
  public struct Rejected: Sendable, Hashable {
    public let name: Bilingual
    /// La raison, en une phrase qui tient debout seule.
    public let because: Bilingual

    public init(_ name: Bilingual, because: Bilingual) {
      self.name = name
      self.because = because
    }
  }

  public let id: String
  /// Le composant employé, sous son nom exact : `NavigationStack`, `Layout`,
  /// `matchedGeometryEffect`.
  public let component: String
  /// Ce qu'il fait **ici**, en une phrase — pas ce qu'il fait en général.
  public let role: Bilingual
  /// Pourquoi celui-là. Du Markdown : la réponse mérite plus qu'une ligne.
  public let rationale: Bilingual
  /// Les candidats écartés. Vide seulement quand il n'y avait réellement pas
  /// d'alternative — ce qui est rare, et alors ça se dit.
  public let rejected: [Rejected]
  /// Dans quels cas l'employer, en général. C'est la partie qui sert à
  /// quelqu'un d'autre que moi.
  public let whenToUse: Bilingual
  /// Le piège : ce qui casse, et qu'on n'apprend qu'en se le prenant.
  public let pitfall: Bilingual?
  /// La documentation d'Apple, quand elle existe.
  public let documentation: URL?

  public init(
    id: String,
    component: String,
    role: Bilingual,
    rationale: Bilingual,
    rejected: [Rejected] = [],
    whenToUse: Bilingual,
    pitfall: Bilingual? = nil,
    documentation: URL? = nil
  ) {
    self.id = id
    self.component = component
    self.role = role
    self.rationale = rationale
    self.rejected = rejected
    self.whenToUse = whenToUse
    self.pitfall = pitfall
    self.documentation = documentation
  }
}
