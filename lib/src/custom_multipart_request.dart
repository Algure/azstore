
import 'dart:async';

import 'package:http/http.dart' as http;

class CustomMultipartRequest extends http.MultipartRequest {
  /// Creates a new [MultipartRequest].
  CustomMultipartRequest(
      String method,
      Uri url, {
        this.onProgress,
      }) : super(method, url);

  final void Function(int bytes, int totalBytes)? onProgress;

  /// Freezes all mutable fields and returns a single-subscription [ByteStream]
  /// that will emit the request body.
  http.ByteStream finalize() {
    final byteStream = super.finalize();
    if (onProgress == null) return byteStream;

    final total = this.contentLength;
    int bytes = 0;

    final t = StreamTransformer.fromHandlers(
      handleData: (List<int> data, EventSink<List<int>> sink) {
        bytes += data.length;
        print('$bytes ; $total ');
        if(onProgress != null) {
          onProgress!(bytes, total);
        }
        sink.add(data);
      },
    );
    final stream = byteStream.transform(t);
    return http.ByteStream(stream);
  }
}