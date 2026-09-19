/// A URL, kept as a string inside the domain.
///
/// `Foundation.URL` is a platform type: the domain has no business depending on
/// it, and even less business deciding that a malformed URL is impossible.
/// Validation is an adapter's job, and it happens in `Data`.
public typealias URLString = String
