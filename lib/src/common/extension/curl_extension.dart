import 'package:http/http.dart';

import 'middleware_extensions.dart';
import 'object_extension.dart';

/// Extension on [ApiClientRequest] to convert to a curl command string.
///
/// Example:
/// ```shell
/// curl -X 'GET' \
/// 	 'https://jsonplaceholder.typicode.com/posts?test=1'
// ```
extension CurlExtension on ApiClientRequest {
  /// Convert the request options to a complete curl command string
  String toCurlString({required final bool addBacktick}) {
    final curl = StringBuffer("curl -X '$method'")
      ..write(" \\\n\t '${url.toString()}'");

    // Add all headers
    headers.forEach((k, v) {
      if (k != 'Cookie') {
        curl.write(" \\\n\t  -H '$k: $v'");
      }
    });

    final request = this as Request;

    // check have data
    if (request.bodyBytes.isEmpty) {
      return addBacktick ? '```shell\n$curl\n```' : curl.toString();
    }

    // TODO: (Miracle) handle multipart/form-data
    // FormData can't be JSON-serialized, so keep only their fields attributes
    // if (request.bodyBytes.isNotEmpty) {
    //   curl.write(" \\\n\t  -d '${jsonEncode(request.bodyBytes)}'");
    // }

    curl.write(" \\\n\t  -d '${request.body.prettyJsonEncodedBody}'");

    return addBacktick ? '```shell\n$curl\n```' : curl.toString();
  }

  /// Convert to a single line curl command (for logging/copying)
  // String toCompactCurlString() => toCurlString().replaceAll(' \\\n\t  ', ' ');
}
