protocol QiblaCalculating: Sendable {
    func bearing(from origin: Coordinates) -> QiblaDirection
}
