import 'package:inline_snapshot/inline_snapshot.dart';
import 'package:test/test.dart';

void main() {
  tearDownAll(() async {
    await Expect.apply();
  });

  group('A group of tests', () {
    test('First Test', () {
      var e = Expect();
      e.eq("actual string 1");
    });
  });

  group('A group of tests', () {
    test('First Test', () {
      var e = Expect();
      e.eq("actual string 2");
    });

    group('A group of tests', () {
      group('A group of tests', () {
        test('test', () {
          var e = Expect();
          e.eq("actual \nstring 3");
        });
      });
    });
  });

  test('First Test', () {
    var e = Expect();
    e.eq("actual string 4");
  });
}
