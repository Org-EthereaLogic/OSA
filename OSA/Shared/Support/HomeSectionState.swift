import Foundation

/// Unified loading state for dashboard sections and feature screens.
enum HomeSectionState<Value> {
    case loading
    case loaded(Value)
    case empty
    case failed(String)
}
