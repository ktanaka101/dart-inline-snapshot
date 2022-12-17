# Inline snapshot

Support inline snapshot testing for Dart.

https://user-images.githubusercontent.com/10344925/208234218-a1629767-4dc6-4455-9407-c99ea86f2265.mov

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
      //             ^replace "actual string" when run `UPDATE_EXPECT=true dart test`
      e.eq("actual string");
    });
  });
}
```

In the above example, Expect is empty.
You can update the Expect result in the source code by executing the following command.
`UPDATE_EXPECT=true dart test`.

When executed, it will update the expected result in the source code as shown in the example below.

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

`UPDATE_EXPECT` can be `1` or `true`.

If `UPDATE_EXPECT=true` is not specified,<br>
it behaves as `expect(actual, expected);`.<br>
The following has the same meaning.

- `Expect("expected").eq("actual");`
- `expect("actual", "expected");`

## How it works

When you call `Expect("expect string")`, it stores the expected result and the location of the caller.
When `Expect#eq(actual: String)` is called, it compares the `actual` with the expected result.
If they match, it is treated as success and nothing is done, but if they do not match, it is kept as a replacement target.
Then, when `Expect.apply();` is executed, it replaces each `actual` with the expected result to be replaced.

## Contributors

- [ktanaka101](https://github.com/ktanaka101) - creator, maintainer

## License

MIT
