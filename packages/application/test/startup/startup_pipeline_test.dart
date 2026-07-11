import 'package:application/application.dart';
import 'package:platform_core/config/app_config.dart';
import 'package:platform_core/environment/build_environment.dart';
import 'package:platform_runtime/registry/service_registry.dart';
import 'package:test/test.dart';

// ── Helpers ────────────────────────────────────────────────────────────────────

final class _RecordingStep implements StartupStep {
  _RecordingStep(this.name, this._log);

  @override
  final String name;
  final List<String> _log;

  @override
  Future<void> execute(StartupContext context) async {
    _log.add(name);
  }
}

final class _FailingStep implements StartupStep {
  const _FailingStep();

  @override
  String get name => 'failing-step';

  @override
  Future<void> execute(StartupContext context) async {
    throw StateError('step failed intentionally');
  }
}

StartupContext _makeContext() {
  const config = AppConfig(
    appName: 'Test',
    environment: BuildEnvironment.development,
    version: '0.0.1',
  );
  return StartupContext(locator: ServiceRegistry(), config: config);
}

// ── Tests ──────────────────────────────────────────────────────────────────────

void main() {
  group('StartupPipeline', () {
    test('executes no steps when empty', () async {
      final pipeline = StartupPipeline();
      await expectLater(pipeline.execute(_makeContext()), completes);
    });

    test('steps is empty initially', () {
      expect(StartupPipeline().steps, isEmpty);
    });

    test('addStep appends a step', () {
      final pipeline = StartupPipeline();
      final log = <String>[];
      pipeline.addStep(_RecordingStep('a', log));
      expect(pipeline.steps, hasLength(1));
      expect(pipeline.steps.first.name, 'a');
    });

    test('addSteps appends multiple steps in order', () {
      final pipeline = StartupPipeline();
      final log = <String>[];
      pipeline.addSteps([
        _RecordingStep('x', log),
        _RecordingStep('y', log),
        _RecordingStep('z', log),
      ]);
      expect(pipeline.steps.map((s) => s.name), ['x', 'y', 'z']);
    });

    test('executes a single step', () async {
      final pipeline = StartupPipeline();
      final log = <String>[];
      pipeline.addStep(_RecordingStep('only', log));
      await pipeline.execute(_makeContext());
      expect(log, ['only']);
    });

    test('executes steps in registration order', () async {
      final pipeline = StartupPipeline();
      final log = <String>[];
      pipeline
        ..addStep(_RecordingStep('first', log))
        ..addStep(_RecordingStep('second', log))
        ..addStep(_RecordingStep('third', log));
      await pipeline.execute(_makeContext());
      expect(log, ['first', 'second', 'third']);
    });

    test('passes the same context to every step', () async {
      final pipeline = StartupPipeline();
      final contexts = <StartupContext>[];
      final ctx = _makeContext();

      pipeline.addSteps([
        _CaptureContextStep(contexts),
        _CaptureContextStep(contexts),
      ]);
      await pipeline.execute(ctx);

      expect(contexts, hasLength(2));
      expect(contexts[0], same(ctx));
      expect(contexts[1], same(ctx));
    });

    test('context carries the provided config', () async {
      final pipeline = StartupPipeline();
      AppConfig? captured;
      pipeline.addStep(_CaptureConfigStep((c) => captured = c));
      final ctx = _makeContext();
      await pipeline.execute(ctx);
      expect(captured, ctx.config);
    });

    test('propagates exception from a failing step', () async {
      final pipeline = StartupPipeline()..addStep(const _FailingStep());
      await expectLater(
        pipeline.execute(_makeContext()),
        throwsA(isA<StateError>()),
      );
    });

    test('does not execute steps after a failing step', () async {
      final log = <String>[];
      final pipeline = StartupPipeline()
        ..addStep(const _FailingStep())
        ..addStep(_RecordingStep('should-not-run', log));
      try {
        await pipeline.execute(_makeContext());
      } catch (_) {}
      expect(log, isEmpty);
    });

    test('steps returns unmodifiable list', () {
      final pipeline = StartupPipeline();
      final log = <String>[];
      pipeline.addStep(_RecordingStep('a', log));
      expect(() => pipeline.steps.add(_RecordingStep('b', log)), throwsA(anything));
    });

    test('can execute pipeline multiple times', () async {
      final pipeline = StartupPipeline();
      final log = <String>[];
      pipeline.addStep(_RecordingStep('step', log));
      await pipeline.execute(_makeContext());
      await pipeline.execute(_makeContext());
      expect(log, ['step', 'step']);
    });
  });
}

// ── Additional helpers ─────────────────────────────────────────────────────────

final class _CaptureContextStep implements StartupStep {
  _CaptureContextStep(this._out);
  final List<StartupContext> _out;

  @override
  String get name => 'capture-context';

  @override
  Future<void> execute(StartupContext context) async {
    _out.add(context);
  }
}

final class _CaptureConfigStep implements StartupStep {
  _CaptureConfigStep(this._capture);
  final void Function(AppConfig) _capture;

  @override
  String get name => 'capture-config';

  @override
  Future<void> execute(StartupContext context) async {
    _capture(context.config);
  }
}
