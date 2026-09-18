/// Education, certifications and open projects.
public struct Background: Sendable, Hashable {
  public let education: [Education]
  public let certifications: [Certification]
  public let openProjects: [OpenProject]

  public init(education: [Education], certifications: [Certification], openProjects: [OpenProject]) {
    self.education = education
    self.certifications = certifications
    self.openProjects = openProjects
  }
}
