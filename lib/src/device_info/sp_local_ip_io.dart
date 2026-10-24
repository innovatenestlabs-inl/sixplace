import 'dart:io';

/// Enumerates interface-assigned private/local IPv4 addresses, without
/// requesting location/Wi-Fi permissions or contacting a remote server.
/// A device may have multiple addresses (Wi-Fi, cellular, VPN, loopback).
Future<List<String>> spLocalIpAddresses() async {
  final addresses = <String>{};
  final interfaces = await NetworkInterface.list(
    type: InternetAddressType.IPv4,
    includeLoopback: false,
    includeLinkLocal: false,
  );
  for (final interface in interfaces) {
    for (final address in interface.addresses) {
      if (address.type == InternetAddressType.IPv4 && !address.isLoopback) {
        addresses.add(address.address);
      }
    }
  }
  return addresses.toList(growable: false);
}
