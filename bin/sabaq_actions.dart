import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:github/github.dart';

Future<void> main(List<String> arguments) async {
  final runner =
      CommandRunner('sabaq-actions', 'actions for the sabaq application')
        ..addCommand(DeployCommand());
  try {
    await runner.run(arguments);
  } on UsageException catch (e) {
    print(e);
    exit(64);
  } finally {
    github.dispose();
  }
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

String getWorkflowId({required String env, required String platform}) {
  return 'deploy-$env-$platform.yaml';
}

class DeployCommand extends Command {
  DeployCommand() {
    argParser.addOption('ref',
        abbr: 'r',
        help: 'sabaq repository ref to deploy. can be a branch name, tag, etc.',
        mandatory: true);
    argParser.addMultiOption('environments',
        abbr: 'e',
        help: 'the environments to deploy to',
        allowed: ['dev', 'prod'],
        defaultsTo: ['dev']);
    argParser.addMultiOption('platforms',
        abbr: 'p',
        help: 'platforms to deploy for',
        allowed: ['android', 'ios', 'web'],
        defaultsTo: ['android', 'ios', 'web']);
  }

  @override
  String get description => 'deploy the sabaq flutter app';

  @override
  String get name => 'deploy';

  @override
  void run() async {
    final argResults = this.argResults!;
    final String ref = argResults['ref'];
    final List<String> environments = argResults['environments'];
    final List<String> platforms = argResults['platforms'];
    final List<Future<void>> dispatches = [];
    final Map<String, dynamic> results = {};
    for (final environment in environments) {
      for (final platform in platforms) {
        final resultKey = '$environment $platform';
        dispatches.add(dispatchWorkflow(
          workflowId: getWorkflowId(env: environment, platform: platform),
          inputs: {'ref': ref},
        ).then((value) {
          results[resultKey] = 'success';
        }).catchError((error) {
          results[resultKey] = error;
        }));
      }
    }
    await Future.wait(dispatches);
    for (final result in results.entries) {
      print('${result.key}: ${result.value}');
    }
  }
}
