/// Heading updates are continuous (unlike the one-shot LocationManaging),
/// so this is modeled as an AsyncStream the Store consumes in a Task started
/// on `.screenAppeared` and torn down on `.screenDisappeared`.
@MainActor
protocol CompassManaging: AnyObject {
    func headingUpdates() -> AsyncStream<CompassHeading>
    func stopUpdatingHeading()
}
