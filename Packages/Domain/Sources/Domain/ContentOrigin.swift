import Foundation

/// Where the content on screen came from.
///
/// This is not logging data: it is **information for the reader**. An app that
/// is offline and does not admit it shows old content with the confidence of new
/// content, which is precisely what we do not want while a recruiter is reading
/// over someone's shoulder.
public enum ContentOrigin: Sendable, Hashable {
  /// Freshly obtained from the source.
  case network
  /// Read back from disk, with the date it was written.
  case cache(storedAt: Date)
  /// The seed bundled in the app — the very first launch, with no network. It
  /// is **produced at build time from the source**, never written by hand:
  /// that would be a second truth.
  case bundledSeed(builtAt: Date)
}
