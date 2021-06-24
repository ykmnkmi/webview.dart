import 'dart:async';
import 'dart:ffi';

import 'package:ffi/ffi.dart';

import 'types.dart';

late final listenerRef = Pointer.fromFunction<CBindCallback>(listener);

late final events = StreamController<Event>.broadcast();

void listener(Pointer<Utf8> seq, Pointer<Utf8> req, Pointer arg) {
  print(seq.toDartString());
  print(req.toDartString());
}

class Event {
  const Event(this.pointer, this.name, this.value);

  final Pointer pointer;

  final String name;

  final String value;
}
