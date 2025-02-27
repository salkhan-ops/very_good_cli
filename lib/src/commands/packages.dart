import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:io/io.dart';
import 'package:mason/mason.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;
import 'package:universal_io/io.dart';
import 'package:very_good_cli/src/cli/cli.dart';

/// {@template packages_command}
/// `very_good packages` command for managing packages.
/// {@endtemplate}
class PackagesCommand extends Command<int> {
  /// {@macro packages_command}
  PackagesCommand({Logger? logger}) {
    addSubcommand(PackagesGetCommand(logger: logger));
  }

  @override
  String get description => 'Command for managing packages.';

  @override
  String get name => 'packages';
}

/// {@template packages_get_command}
/// `very_good packages get` command for installing packages.
/// {@endtemplate}
class PackagesGetCommand extends Command<int> {
  /// {@macro packages_get_command}
  PackagesGetCommand({Logger? logger}) : _logger = logger ?? Logger() {
    argParser.addFlag(
      'recursive',
      abbr: 'r',
      help: 'Install dependencies recursively for all nested packages.',
      negatable: false,
    );
  }

  final Logger _logger;

  @override
  String get description => 'Get packages in a Dart or Flutter project.';

  @override
  String get name => 'get';

  /// [ArgResults] which can be overridden for testing.
  @visibleForTesting
  ArgResults? argResultOverrides;

  ArgResults get _argResults => argResultOverrides ?? argResults!;

  @override
  Future<int> run() async {
    if (_argResults.rest.length > 1) {
      throw UsageException('Too many arguments', usage);
    }

    final recursive = _argResults['recursive'] as bool;
    final target = _argResults.rest.length == 1 ? _argResults.rest[0] : '.';
    final targetPath = path.normalize(Directory(target).absolute.path);
    final isFlutterInstalled = await Flutter.installed();
    if (isFlutterInstalled) {
      try {
        await Flutter.packagesGet(
          cwd: targetPath,
          recursive: recursive,
          progress: _logger.progress,
        );
      } on PubspecNotFound catch (_) {
        _logger.err('Could not find a pubspec.yaml in $targetPath');
        return ExitCode.noInput.code;
      } catch (error) {
        _logger.err('$error');
        return ExitCode.unavailable.code;
      }
    }
    return ExitCode.success.code;
  }
}
