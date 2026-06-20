import 'package:flutter_riverpod/flutter_riverpod.dart';

class TransitDateNotifier extends Notifier<DateTime> {
  @override
  DateTime build() => DateTime.now();

  void update(DateTime date) {
    state = date;
  }
}

final transitDateProvider = NotifierProvider<TransitDateNotifier, DateTime>(() {
  return TransitDateNotifier();
});
