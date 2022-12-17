# Inline snapshot

A library that supports inline snapshot testing for Dart, inspired by [expect-test](https://github.com/rust-analyzer/expect-test), [rspec-inline-snapshot](https://github.com/Hummingbird-RegTech/rspec-inline-snapshot), [Jest](https://jestjs.io/), and others!

https://user-images.githubusercontent.com/10344925/208234218-a1629767-4dc6-4455-9407-c99ea86f2265.mov

## Features

- Performs inline snapshot testing
- Allows updating expected results based on actual results

## What is convenient?

Expected results are not output to an external file, but rather written to the same location as the input. This makes it easy to verify the input and expected result together. Since the test can be automatically updated, the only cost of modifying the test is checking the differences detected.

This type of testing is ideal for cases where expected results are small and likely to change, such as:

- Testing parser results (e.g., ASTs) in programming languages
- Any other test that can be serialized into a string

## Getting started

Add the following dependency to your `pubspec.yaml` file:

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
      //             ^Replace "actual string" with `UPDATE_EXPECT=1 dart test`
      e.eq("actual string");
    });
  });
}
```

In the above example, the `Expect` object is empty. You can update the expected result in the source code by running the following command: `UPDATE_EXPECT=true dart test`.
This will update the expected result in the source code, as shown below:

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

You can set `UPDATE_EXPECT` to either `1` or `true`.
If it is not specified, the Expect object behaves similarly to `expect(actual, expected)`, with leading newlines in the expected result being removed before comparison.

## How it works

When you call `Expect("expect string")`, the expected result and the location of the caller are stored. When `Expect#eq(actual: String)` is called, actual is compared to the expected result. If they match, the test is considered a success and no further action is taken. If they do not match, the expected result is marked for replacement. When `Expect.apply()` is executed, the actual values marked for replacement are replaced with the expected results.

## Contributors

- [ktanaka101](https://github.com/ktanaka101) - creator, maintainer

## License

MIT
