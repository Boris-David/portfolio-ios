struct AppCatalogueDTO: Decodable {
  struct Item: Decodable {
    let slug: String
    let name: String
    let territory: String
    let appStoreUrl: String
    let role: String
  }

  let verifiedAt: String
  let items: [Item]
}
