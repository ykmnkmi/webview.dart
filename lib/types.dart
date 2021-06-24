import 'dart:ffi';

import 'package:ffi/ffi.dart';

typedef CBindCallback = Void Function(
    Pointer<Utf8> seq, Pointer<Utf8> req, Pointer arg);
