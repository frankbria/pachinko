/// Platform calls that have started and not finished, so that a service can
/// wait for them before it disposes its players.
///
/// A player disposed in the middle of a platform call goes on receiving
/// platform events on streams that are closed, which the audio plugin
/// reports as an error no caller can catch. `AudioService` and
/// `MusicService` run every call to a player through [track] and await
/// [settled] in their `dispose`.
class PlatformCalls {
  final Set<Future<void>> _inFlight = {};

  /// Runs [calls] and keeps it in flight until it ends, whether it succeeds
  /// or fails. Its error, if any, reaches the caller.
  Future<void> track(Future<void> calls) async {
    final settled = calls.then<void>((_) {}, onError: (Object _) {});
    _inFlight.add(settled);
    try {
      await calls;
    } finally {
      _inFlight.remove(settled);
    }
  }

  /// Completes when every call in flight now has ended. Never throws.
  Future<void> settled() => Future.wait(_inFlight.toList());
}
