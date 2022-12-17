import 'dart:convert';
import 'dart:io';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:codemod/codemod.dart';
import 'package:stack_trace/stack_trace.dart';
import 'package:test/expect.dart';

class Expect {
  static final Collector _collector = Collector();

  late final Frame _position;

  /// The expected result.
  final String? _expected;

  /// Constructs an `Expect` object.
  Expect([this._expected]) {
    _position = Trace.current(1).frames[0];
  }

  /// Compares the [actual] result to the [_expected] result.
  ///
  /// If [actual] matches the [_expected] result, the test is considered a success.
  /// If they do not match, the expected result is marked for replacement if `UPDATE_EXPECT` is set to `true` or `1`.
  /// If it is not specified, the Expect object behaves similarly to `expect(actual, expected)`,
  /// with leading newlines in the expected result being removed before comparison.
  Future<void> eq(String actual) async {
    final expected = _trimmedExpected();
    if (expected == actual) {
      return;
    }

    if (_shouldUpdate()) {
      _collector.add(Patch(actual, _position));
    } else {
      expect(actual, expected);
    }
  }

  /// Trims from the expected result.
  String? _trimmedExpected() {
    final expected = _expected;
    if (expected == null) {
      return null;
    }
    if (expected.contains("\n")) {
      return expected;
    }
    if (expected.startsWith('\n')) {
      return expected.substring(1);
    } else {
      return expected;
    }
  }

  static const List<String> _envTruthy = ["1", "true"];
  static bool _shouldUpdate() {
    return _envTruthy.contains(Platform.environment["UPDATE_EXPECT"]);
  }

  /// Replaces the expected results marked for replacement.
  static Future<void> apply() async {
    await _collector.apply();
  }
}

class PositionWithOffset {
  final Frame _position;
  final int _offset;
  PositionWithOffset(this._position, this._offset);

  int line() {
    return _position.line! + _offset;
  }

  int column() {
    return _position.column!;
  }
}

class Collector {
  List<Patch> patches = [];

  void add(Patch patch) {
    patches.add(patch);
  }

  Future<void> apply() async {
    var offset = 0;
    for (var patch in patches) {
      final content = await File.fromUri(patch.position.uri).readAsString();
      final lineInfo = LineInfo.fromContent(content);
      final position = PositionWithOffset(patch.position, offset);
      await runInteractiveCodemod(
        [patch.position.uri.path],
        Replacer(patch.actual, position, lineInfo),
        args: ['--yes-to-all'],
      );
      final ls = LineSplitter();
      final len = ls.convert(patch.actual).length;
      // If len equal 1, single line string.
      // If len greater than equal 2, multi line string.
      if (len > 1) {
        // count new line in multi line string.(len - 1)
        // In addition, one line break is added at the beginning.(+1)
        offset += len;
      }
    }
    patches.clear();
  }
}

class Patch {
  String actual;
  Frame position;

  Patch(this.actual, this.position);
}

class Replacer extends RecursiveAstVisitor<void> with AstVisitingSuggestor {
  final String _actual;
  final PositionWithOffset _callingPosition;
  final LineInfo _lineInfo;
  Replacer(this._actual, this._callingPosition, this._lineInfo);

  @override
  void visitMethodInvocation(MethodInvocation node) {
    var nodeLocation = _lineInfo.getLocation(node.offset);
    if (nodeLocation.lineNumber != _callingPosition.line()) {
      super.visitMethodInvocation(node);
      return;
    }
    if (nodeLocation.columnNumber != _callingPosition.column()) {
      super.visitMethodInvocation(node);
      return;
    }

    var replaceString = formatReplaceString(_actual);
    if (hasArguments(node)) {
      var target = node.argumentList.arguments.first;
      yieldPatch(replaceString, target.offset, target.end);
    } else {
      var argOffset = node.argumentList.offset + 1;
      yieldPatch(replaceString, argOffset, argOffset);
    }

    super.visitMethodInvocation(node);
  }

  String formatReplaceString(String actual) {
    if (actual.contains('\n')) {
      return """'''
$_actual'''""";
    } else {
      return "\"$_actual\"";
    }
  }

  bool hasArguments(MethodInvocation node) {
    return node.argumentList.arguments.isNotEmpty;
  }
}
