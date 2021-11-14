import 'dart:convert';

import 'package:github/github.dart';

Future<void> main(List<String> arguments) async {
  await dispatchWorkflow(workflowId: 'deploy-dev-android.yaml');
}

final github = GitHub(auth: findAuthenticationFromEnvironment());

Future<void> dispatchWorkflow({
  required String workflowId,
  String ref = 'main',
  Map<String, dynamic>? inputs,
}) async {
  final Map<String, dynamic> body = {'ref': ref};
  if (inputs != null) body['inputs'] = inputs;
  await github.request('POST',
      '/repos/cjiis/sabaq-actions/actions/workflows/$workflowId/dispatches',
      body: jsonEncode(body), statusCode: 204);
}
