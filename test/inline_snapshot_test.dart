import 'package:inline_snapshot/inline_snapshot.dart';
import 'package:test/test.dart';

void main() {
  group('A group of tests', () {
    test('First Test', () {
      tryExpect("aa", "bb");
    });
  });
}
