# Inline snapshot

Support inline snapshot testing for Dart.

## Features

- Performs an inline snapshot testing
- Update expected results based on actual

## What is convenient?

Expected results are not output to an external file.
It is written to the same location as the input.
This makes it easy to verify the input and the expected result.
Since the test can be automatically updated, the only cost of modifying the test is to check the differences detected.

Ideal for tests where expected results are small and likely to change.
For example, the following cases

- Testing HTTP responses
- Testing parser results (e.g., ASTs) in programming languages
- Any other test that can be serialized into a string can be tested!

## Getting started

Add into your `pubspec.yaml` dependencies: section.

```yml
dependencies:
  inline_snapshot: ^1.0.0
```

## Usage

```dart
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
```

↓

```dart
import 'package:test/test.dart';
import 'package:inline_snapshot/inline_snapshot.dart';

void main() {
  tearDownAll(() async {
    await Expect.apply();
  });

  group('A group of tests', () {
    test('First Test', () {
      var e = Expect("actual string");
      //             ^replaced "actual string"!!
      e.eq("actual string");
    });
  });
}
```

## Contributors

- [ktanaka101](https://github.com/ktanaka101) - creator, maintainer

## License

MIT
