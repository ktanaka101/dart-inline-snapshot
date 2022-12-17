import 'dart:io';

import 'package:inline_snapshot/inline_snapshot.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:uuid/uuid.dart';

Future<void> testReplacingFile(String actual, String expected,
    {required bool updateExpect}) async {
  const importContent =
      "import 'package:inline_snapshot/inline_snapshot.dart';\n"
      "import 'package:test/test.dart';";
  actual = "$importContent\n$actual";
  expected = "$importContent\n$expected";

  final uuid = Uuid();
  final testFilePath =
      path.join(Directory.current.path, "test", "tmp", uuid.v4());
  final testFile = File(testFilePath);
  try {
    await testFile.create();
    await testFile.writeAsString(actual);
    await Process.run("dart", ["test", testFile.path],
        environment: {"UPDATE_EXPECT": updateExpect.toString()});
    final resultContent = await testFile.readAsString();
    expect(resultContent, expected);
  } finally {
    if (await testFile.exists()) {
      await testFile.delete();
    }
  }
}

void main() {
  group('UPDATE_EXPECT=true', () {
    test('Replace expected with actual that no arg', () async {
      await testReplacingFile(
        '''
void main() {
  tearDownAll(() async {
    await Expect.apply();
  });
  test("testing", () {
    final e = Expect();
    e.eq("actual string");
  });
}
        ''',
        '''
void main() {
  tearDownAll(() async {
    await Expect.apply();
  });
  test("testing", () {
    final e = Expect("actual string");
    e.eq("actual string");
  });
}
        ''',
        updateExpect: true,
      );
    });

    test('Replace expected with actual that have an arg', () async {
      await testReplacingFile(
        '''
void main() {
  tearDownAll(() async {
    await Expect.apply();
  });
  test("testing", () {
    final e = Expect("failure");
    e.eq("actual string");
  });
}
        ''',
        '''
void main() {
  tearDownAll(() async {
    await Expect.apply();
  });
  test("testing", () {
    final e = Expect("actual string");
    e.eq("actual string");
  });
}
        ''',
        updateExpect: true,
      );
    });

    test('Replace expected with actual in group', () async {
      await testReplacingFile(
        '''
void main() {
  tearDownAll(() async {
    await Expect.apply();
  });
  group('group', () {
    test("testing", () {
      final e = Expect();
      e.eq("actual string");
    });
  });
}
        ''',
        '''
void main() {
  tearDownAll(() async {
    await Expect.apply();
  });
  group('group', () {
    test("testing", () {
      final e = Expect("actual string");
      e.eq("actual string");
    });
  });
}
        ''',
        updateExpect: true,
      );
    });

    test('multiple Expect', () async {
      await testReplacingFile(
        '''
void main() {
  tearDownAll(() async {
    await Expect.apply();
  });
  test('testing', () {
    final e = Expect();
    e.eq("actual string A");
  });
  group('group', () {
    test("testing", () {
      final e = Expect();
      e.eq("actual string B");
    });
  });
}
        ''',
        '''
void main() {
  tearDownAll(() async {
    await Expect.apply();
  });
  test('testing', () {
    final e = Expect("actual string A");
    e.eq("actual string A");
  });
  group('group', () {
    test("testing", () {
      final e = Expect("actual string B");
      e.eq("actual string B");
    });
  });
}
        ''',
        updateExpect: true,
      );
    });

    test('Replace expected with actual with newline.', () async {
      await testReplacingFile(
        '''
void main() {
  tearDownAll(() async {
    await Expect.apply();
  });
  test('testing', () {
    final e = Expect();
    e.eq("actual \\nstring A");
  });
  test("testing", () {
    final e = Expect();
    e.eq("actual \\n\\nstring B");
  });
  test("testing", () {
    final e = Expect();
    e.eq("actual \\n\\n\\nstring C");
  });
}
        ''',
        """
void main() {
  tearDownAll(() async {
    await Expect.apply();
  });
  test('testing', () {
    final e = Expect('''
actual 
string A''');
    e.eq("actual \\nstring A");
  });
  test("testing", () {
    final e = Expect('''
actual 

string B''');
    e.eq("actual \\n\\nstring B");
  });
  test("testing", () {
    final e = Expect('''
actual 


string C''');
    e.eq("actual \\n\\n\\nstring C");
  });
}
        """,
        updateExpect: true,
      );
    });
  });

  group('UPDATE_EXPECT=false', () {
    test('Do not Replace expected', () async {
      await testReplacingFile(
        '''
void main() {
  tearDownAll(() async {
    await Expect.apply();
  });
  test("testing", () {
    final e = Expect();
    e.eq("actual string");
  });
}
        ''',
        '''
void main() {
  tearDownAll(() async {
    await Expect.apply();
  });
  test("testing", () {
    final e = Expect();
    e.eq("actual string");
  });
}
        ''',
        updateExpect: false,
      );
    });

    test(
        'During comparison, leading newlines in the expected result are removed.',
        () async {
      final e = Expect('''
expected string''');
      await e.eq('expected string');
    });

    test('If no match is found, the test fails.', () async {
      final e = Expect('expected string');
      await expectLater(() async {
        await e.eq('no match string');
      }, throwsA(isA<TestFailure>()));
    });
  });
}
