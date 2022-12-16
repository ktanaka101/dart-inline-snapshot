/// Support for doing something awesome.
///
/// More dartdocs go here.
library inline_snapshot;

import 'package:stack_trace/stack_trace.dart';

export 'src/inline_snapshot_base.dart';

void tryExpect(String actual, String expected) {
  print(Trace.current(1));
}
