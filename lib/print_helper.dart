import 'package:stack_trace/stack_trace.dart';

class PrintHelper {
    static void debugPrintWithLocation(String message) {
    final frames = Trace.current().frames;
    if (frames.length > 1) {
      final callerFrame = frames[1];
      print(
        '[${callerFrame.uri.pathSegments.last}:${callerFrame.line}]\n $message',
      );
    } else {
      print(message);
    }
  }
}
