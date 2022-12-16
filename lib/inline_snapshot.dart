/// Support for doing something awesome.
///
/// More dartdocs go here.
library inline_snapshot;

import 'dart:io';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:codemod/codemod.dart';
import 'package:stack_trace/stack_trace.dart';

export 'src/inline_snapshot_base.dart';

class Expect {
  late final Frame _position;
  final String expected;
  Expect(this.expected) {
    _position = Trace.current(1).frames[0];
  }

  Future<void> eq(String actual) async {
    if (expected == actual) {
      return;
    }

    var fileUri = _position.uri;
    var content = await File.fromUri(fileUri).readAsString();
    var lineInfo = LineInfo.fromContent(content);
    await runInteractiveCodemod([fileUri.path], Replacer(_position, lineInfo));
  }
}

class Replacer extends RecursiveAstVisitor<void> with AstVisitingSuggestor {
  final Frame _callingPosition;
  final LineInfo _lineInfo;
  Replacer(this._callingPosition, this._lineInfo);

  @override
  void visitMethodInvocation(MethodInvocation node) {
    var nodeLocation = _lineInfo.getLocation(node.offset);
    if (nodeLocation.lineNumber != _callingPosition.line) {
      print("no line");
      super.visitMethodInvocation(node);
      return;
    }
    if (nodeLocation.columnNumber != _callingPosition.column!) {
      print("no column");
      super.visitMethodInvocation(node);
      return;
    }

    super.visitMethodInvocation(node);
  }
}
