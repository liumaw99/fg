import 'dart:async';

class Debounce {
  final Duration delay;
  Timer? _timer;

  Debounce({this.delay = const Duration(milliseconds: 300)});

  void call(void Function() action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}

class DebounceValue<T> {
  final Duration delay;
  Timer? _timer;
  T? _lastValue;

  DebounceValue({this.delay = const Duration(milliseconds: 300)});

  void call(T value, void Function(T) action) {
    _lastValue = value;
    _timer?.cancel();
    _timer = Timer(delay, () {
      if (_lastValue != null) {
        action(_lastValue as T);
      }
    });
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}
