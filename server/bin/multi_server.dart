#!/usr/bin/env dart
library server.multi_server;

import 'dart:io';
import 'package:angel_compress/angel_compress.dart';
import 'package:angel_multiserver/angel_multiserver.dart';

final Uri cluster = Platform.script.resolve('cluster.dart');

/// The number of isolates to spawn. You might consider starting one instance
/// per processor core on your machine.
final int nInstances = Platform.numberOfProcessors;

main() async {
  var app = new LoadBalancer();
  // Or, for SSL: 
  // var app = new LoadBalancer.secure('<server-chain>', '<server-key>');

  // Response compression!
  app.responseFinalizers.add(gzip());
  
  // Cache static assets - just to lower response time
  await app.configure(cacheResponses(filters: [new RegExp(r'images/.*')]));

  // Start up multiple instances of our main application.
  await app.spawnIsolates(cluster, count: nInstances);

  app.onCrash.listen((_) async {
    // Boot up a new instance on crash
    await app.spawnIsolates(cluster);
  });

  var host = InternetAddress.ANY_IP_V4;
  var port = 3000;
  var server = await app.startServer(host, port);
  print('Listening at http://${server.address.address}:${server.port}');
  print('Load-balancing $nInstances instance(s)');
}
