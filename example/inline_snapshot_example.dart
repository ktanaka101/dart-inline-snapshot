import 'package:test/test.dart';
import 'package:inline_snapshot/inline_snapshot.dart';

void main() {
  tearDownAll(() async {
    await Expect.apply();
  });

  group('A group of tests', () {
    test('First Test', () {
      var e = Expect();
      //             ^replace "actual string" when run `UPDATE_EXPECT dart test`
      e.eq("actual string");
    });
  });
}
