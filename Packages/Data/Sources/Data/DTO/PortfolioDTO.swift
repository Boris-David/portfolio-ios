struct PortfolioDTO: Decodable {
  let profile: ProfileDTO
  let metrics: [MetricDTO]
  let sections: [SectionDTO]
  let caseStudies: [CaseStudyDTO]
  let apps: AppCatalogueDTO
  let expertise: [ExpertiseDTO]
  let architectures: ArchitectureStudyDTO
  let experience: [ExperienceDTO]
  let background: BackgroundDTO
  let skills: [SkillGroupDTO]
}
