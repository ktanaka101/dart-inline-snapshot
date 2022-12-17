import 'dart:convert';
import 'dart:io';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:codemod/codemod.dart';
import 'package:stack_trace/stack_trace.dart';
import 'package:test/expect.dart';

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
      offset += ls.convert(patch.actual).length - 1;
    }
    patches.clear();
  }
}

class Patch {
  String actual;
  Frame position;

  Patch(this.actual, this.position);
}

class Expect {
  static final Collector _collector = Collector();

  late final Frame _position;
  final String? expected;
  Expect([this.expected]) {
    _position = Trace.current(1).frames[0];
  }

  Future<void> eq(String actual) async {
    if (expected == actual) {
      return;
    }

    if (shouldUpdate()) {
      _collector.add(Patch(actual, _position));
    } else {
      expect(actual, expected);
    }
  }

  static const List<String> envTruthy = ["1", "true"];
  static bool shouldUpdate() {
    return envTruthy.contains(Platform.environment["UPDATE_EXPECT"]);
  }

  static Future<void> apply() async {
    await _collector.apply();
  }
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
      var argOffset = node.argumentList.offset + 1;
      yieldPatch(replaceString, argOffset, argOffset);
    } else {
      var target = node.argumentList.arguments.first;
      yieldPatch(replaceString, target.offset, target.end);
    }

    super.visitMethodInvocation(node);
  }

  String formatReplaceString(String actual) {
    if (actual.contains('\n')) {
      return "'''$_actual'''";
    } else {
      return "\"$_actual\"";
    }
  }

  bool hasArguments(MethodInvocation node) {
    try {
      // throw Exception If arugment is empty.
      node.argumentList;
      return true;
    } on Exception {
      return false;
    }
  }
}
