import 'package:inline_snapshot/inline_snapshot.dart';
import 'package:test/test.dart';

void main() {
  group('A group of tests', () {
    test('First Test', () async {
      var e = Expect("expecting string");
      await e.eq("actual string");
    });
  });
}
