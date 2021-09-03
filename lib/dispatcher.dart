import 'dart:async';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

class Dispatcher {
  static final shared = Dispatcher._internal();

  late StreamSubscription<html.MouseEvent> _onDragOverSubscription;
  late StreamSubscription<html.MouseEvent> _onDropSubscription;

  final _isWithinBoundsFunctions = <int, bool Function(html.MouseEvent)>{};
  final _dragFunctions = <int, Function(bool)>{};
  final _dropFunctions = <int, Function(html.MouseEvent)>{};

  var currentZoneId = 0;

  Dispatcher._internal() {
    _onDropSubscription = html.document.body!.onDrop.listen(_onDrop);
    _onDragOverSubscription =
        html.document.body!.onDragOver.listen(_onDragOver);
  }

  void cancel() {
    _onDropSubscription.cancel();
    _onDragOverSubscription.cancel();
  }

  int addZone(
      {bool Function(html.MouseEvent e)? getIsWithinBounds,
      Function(bool withinBounds)? onDragOver,
      Function(html.MouseEvent e)? onDrop}) {
    if (getIsWithinBounds != null) {
      _isWithinBoundsFunctions[currentZoneId] = getIsWithinBounds;
    }

    if (onDragOver != null) {
      _dragFunctions[currentZoneId] = onDragOver;
    }

    if (onDrop != null) {
      _dropFunctions[currentZoneId] = onDrop;
    }

    return currentZoneId++;
  }

  void removeZone(int id) {
    _dragFunctions.remove(id);
    _dropFunctions.remove(id);
  }

  void _stopEvent(html.MouseEvent e) => e
    ..stopPropagation()
    ..stopImmediatePropagation()
    ..preventDefault();

  void _onDrop(html.MouseEvent e) {
    _stopEvent(e);

    for (final entry in _dropFunctions.entries.toList().reversed) {
      if (_isWithinBoundsFunctions[entry.key]!(e)) {
        entry.value(e);
        return;
      }
    }
  }

  void _onDragOver(html.MouseEvent e) {
    _stopEvent(e);

    bool alreadyGivedEvent = false;

    for (final entry in _dragFunctions.entries.toList().reversed) {
      if (_isWithinBoundsFunctions[entry.key]!(e) && !alreadyGivedEvent) {
        entry.value(true);
        alreadyGivedEvent = true;
      } else {
        entry.value(false);
      }
    }
  }
}
