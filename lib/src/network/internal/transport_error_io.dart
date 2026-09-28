import 'dart:io';

// Some native clients expose raw socket/TLS/stream errors. This file must never
// be imported unconditionally because the public API also targets web.
bool isPlatformTransportError(Object error) =>
    error is SocketException || error is HttpException || error is TlsException;
