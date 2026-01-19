import 'dart:async';
import '../../models/twizz/twizz_models.dart';

/// Event types for Twizz synchronization
enum TwizzSyncEventType { update, delete, create }

/// Event data for Twizz synchronization
class TwizzSyncEvent {
  final TwizzSyncEventType type;
  final String? twizzId;
  final Twizz? twizz;

  TwizzSyncEvent({required this.type, this.twizzId, this.twizz});

  factory TwizzSyncEvent.update(Twizz twizz) => TwizzSyncEvent(
    type: TwizzSyncEventType.update,
    twizzId: twizz.id,
    twizz: twizz,
  );

  factory TwizzSyncEvent.create(Twizz twizz) => TwizzSyncEvent(
    type: TwizzSyncEventType.create,
    twizzId: twizz.id,
    twizz: twizz,
  );

  factory TwizzSyncEvent.delete(String twizzId) =>
      TwizzSyncEvent(
        type: TwizzSyncEventType.delete,
        twizzId: twizzId,
      );
}

/// Twizz Sync Service
///
/// A central event bus to synchronize Twizz states across different ViewModels
class TwizzSyncService {
  final _eventController =
      StreamController<TwizzSyncEvent>.broadcast();

  /// Stream of Twizz sync events
  Stream<TwizzSyncEvent> get eventStream =>
      _eventController.stream;

  /// Emit an update event
  void emitUpdate(Twizz twizz) {
    _eventController.add(TwizzSyncEvent.update(twizz));
  }

  /// Emit a create event
  void emitCreate(Twizz twizz) {
    _eventController.add(TwizzSyncEvent.create(twizz));
  }

  /// Emit a delete event
  void emitDelete(String twizzId) {
    _eventController.add(TwizzSyncEvent.delete(twizzId));
  }

  /// Dispose the controller
  void dispose() {
    _eventController.close();
  }
}
