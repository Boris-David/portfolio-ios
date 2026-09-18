import Domain
import Foundation

/// Part of the API payload, described exactly as it arrives.
///
/// These types live here and **never in `Domain`**. An entity carrying
/// `CodingKeys` is an entity that let the network dictate its shape: the day the
/// API renames a field, it is the core of the app that gets reopened. Here, only
/// the adapter moves.
///
/// They are `internal`: nothing outside `Data` has any reason to know a JSON
/// response exists.
struct PortfolioEnvelopeDTO: Decodable {
  struct Meta: Decodable {
    let locale: String
    let contentVersion: String
  }

  let meta: Meta
  let data: PortfolioDTO
}
