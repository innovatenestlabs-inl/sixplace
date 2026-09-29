import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

/// A byte-backed multipart file that also works on Flutter Web.
///
/// No dart:io File is required. Pick/read the bytes in application code.
/// Large streaming uploads are intentionally outside this initial API.
class SPUploadFile {
  /// Copies the supplied bytes so a request cannot observe later mutations.
  SPUploadFile({
    required this.field,
    required this.filename,
    required List<int> bytes,
    String? contentType,
  }) : bytes = Uint8List.fromList(bytes).asUnmodifiableView(),
       _contentType = contentType == null
           ? null
           : MediaType.parse(contentType) {
    if (field.isEmpty || filename.isEmpty) {
      throw ArgumentError('field and filename must not be empty.');
    }
  }

  /// Form field name, for example `attachment`.
  final String field;

  /// Filename sent to the server, not a device path.
  final String filename;

  /// Immutable file contents.
  final Uint8List bytes;
  final MediaType? _contentType;

  /// Creates a fresh multipart part for each request.
  http.MultipartFile toMultipartFile() => http.MultipartFile.fromBytes(
    field,
    bytes,
    filename: filename,
    contentType: _contentType,
  );
}
