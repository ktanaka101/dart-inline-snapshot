import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:uuid/uuid.dart';

Future<void> testReplacingFile(String actual, String expected,
    {required bool updateExpect, String? containStdout}) async {
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
    final processResult = await Process.run("dart", ["test", testFile.path],
        environment: {"UPDATE_EXPECT": updateExpect.toString()});
    final resultContent = await testFile.readAsString();
    expect(resultContent, expected);

    if (containStdout != null) {
      expect(processResult.stdout, contains(containStdout));
    }
  } finally {
    if (await testFile.exists()) {
      await testFile.delete();
    }
  }
}

void main() {
  group('UPDATE_EXPECT=true', () {
    test('Replace expected with actual', () async {
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
    final e = Expect('''actual 
string A''');
    e.eq("actual \\nstring A");
  });
  test("testing", () {
    final e = Expect('''actual 

string B''');
    e.eq("actual \\n\\nstring B");
  });
  test("testing", () {
    final e = Expect('''actual 


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
        containStdout: '  Expected: <null>\n'
            '    Actual: \'actual string\'\n',
      );
    });
  });
}
