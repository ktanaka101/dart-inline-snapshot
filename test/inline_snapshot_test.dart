import 'package:inline_snapshot/inline_snapshot.dart';
import 'package:test/test.dart';

void main() {
  tearDownAll(() async {
    await Expect.apply();
  });

  group('A group of tests', () {
    test('First Test', () {
      var e = Expect();
      e.eq("actual \n\nstring 1");
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
          expect("aaaa", "bbb");
          var e = Expect();
          e.eq("actual string 3");
        });
      });
    });
  });

  test('First Test', () {
    var e = Expect();
    e.eq("actual string 4");
  });
}
