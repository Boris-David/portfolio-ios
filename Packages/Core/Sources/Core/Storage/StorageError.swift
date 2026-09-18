public enum StorageError: Error, Sendable {
  case write(String)
  case read(String)
}
