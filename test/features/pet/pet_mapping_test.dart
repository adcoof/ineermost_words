import 'dart:async';

import 'package:ai_roleplay_chat/data/local/app_database.dart';
import 'package:ai_roleplay_chat/features/chat/application/emotion_tag_parser.dart';
import 'package:ai_roleplay_chat/features/pet/application/pet_orchestrator.dart';
import 'package:ai_roleplay_chat/features/pet/data/pet_controller_webview.dart';
import 'package:ai_roleplay_chat/features/pet/data/pet_model_repository.dart';
import 'package:ai_roleplay_chat/features/pet/domain/pet_command.dart';
import 'package:ai_roleplay_chat/features/pet/domain/pet_model.dart';
import 'package:drift/native.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

/// 记录指令的假桌宠控制器。
class _FakePetController implements PetController {
  final List<PetCommand> executed = [];
  final _events = StreamController<PetUserEvent>.broadcast();

  @override
  Stream<PetUserEvent> get events => _events.stream;

  @override
  Future<void> loadModel(String entryJsonPath) async {}

  @override
  Future<void> setExpression(String expressionId) async {
    executed.add(PetCommand.expression(expressionId));
  }

  @override
  Future<void> startMotion(String group,
      {int index = 0, int priority = 1}) async {
    executed.add(PetCommand.motion(group, index: index, priority: priority));
  }

  @override
  Future<void> setLipSync(double value) async {
    executed.add(PetCommand.lip(value));
  }

  @override
  Future<void> setPointer(double x, double y) async {}

  void dispose() => _events.close();
}

void main() {
  late AppDatabase db;
  late PetModelRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = PetModelRepository(db);
  });

  tearDown(() => db.close());

  Future<void> addMapping({
    required String tag,
    required String type,
    required String target,
    int priority = 1,
    String? modelId,
    bool enabled = true,
  }) =>
      repo.saveMapping(EmotionMapping(
        id: '$modelId|$tag|$type|$target',
        petModelId: modelId,
        tag: tag,
        actionType: type,
        targetId: target,
        priority: priority,
        enabled: enabled,
      ));

  group('映射解析', () {
    test('全局映射生效', () async {
      await addMapping(tag: 'happy', type: 'expression', target: 'f01');
      final cmd = await repo.resolve(
          const EmotionEvent('emotion', 'happy'), 'm1');
      expect(cmd?.type, PetCommandType.setExpression);
      expect(cmd?.expressionId, 'f01');
    });

    test('模型级覆盖同 tag 全局', () async {
      await addMapping(tag: 'happy', type: 'expression', target: 'global');
      await addMapping(
          tag: 'happy', type: 'expression', target: 'model', modelId: 'm1');
      final cmd = await repo.resolve(
          const EmotionEvent('emotion', 'happy'), 'm1');
      expect(cmd?.expressionId, 'model');
      // 其他模型仍走全局。
      final other = await repo.resolve(
          const EmotionEvent('emotion', 'happy'), 'm2');
      expect(other?.expressionId, 'global');
    });

    test('motion 目标解析 组名 与 组名:序号', () async {
      await addMapping(tag: 'wave', type: 'motion', target: 'TapBody:2',
          priority: 3);
      final cmd =
          await repo.resolve(const EmotionEvent('action', 'wave'), 'm1');
      expect(cmd?.type, PetCommandType.startMotion);
      expect(cmd?.motionGroup, 'TapBody');
      expect(cmd?.motionIndex, 2);
      expect(cmd?.priority, 3);
    });

    test('disabled 映射不参与解析', () async {
      await addMapping(
          tag: 'sad', type: 'expression', target: 'f02', enabled: false);
      expect(await repo.resolve(const EmotionEvent('emotion', 'sad'), 'm1'),
          isNull);
    });

    test('seedDefaultMappings 幂等', () async {
      await repo.seedDefaultMappings();
      await repo.seedDefaultMappings();
      final all = await repo.watchMappings('any').first;
      expect(all.where((m) => m.petModelId == null).length, 8);
    });
  });

  group('解析目标适配（对照真实模型）', () {
    late PetModel haru;

    setUp(() {
      final now = DateTime(2026);
      haru = PetModel(
        id: 'm1',
        name: 'haru',
        dirPath: '/x',
        entryJsonPath: '/x/m.model3.json',
        expressions: const ['f00', 'f01', 'f02', 'f03'],
        motionGroups: const {'Idle': 3, 'Tap': 2},
        createdAt: now,
        updatedAt: now,
      );
      return repo.saveModel(haru);
    });

    test('目标大小写容错：映射写 F03 匹配模型 f03', () async {
      await addMapping(tag: 'happy', type: 'expression', target: 'F03');
      final cmd = await repo.resolve(
          const EmotionEvent('emotion', 'happy'), 'm1');
      expect(cmd?.expressionId, 'f03');
    });

    test('目标不存在时兜底到模型表情库内（且稳定）', () async {
      await addMapping(tag: 'happy', type: 'expression', target: 'nonexistent');
      final cmd1 = await repo.resolve(
          const EmotionEvent('emotion', 'happy'), 'm1');
      final cmd2 = await repo.resolve(
          const EmotionEvent('emotion', 'happy'), 'm1');
      expect(haru.expressions, contains(cmd1?.expressionId));
      expect(cmd1?.expressionId, cmd2?.expressionId);
    });

    test('完全没有映射的情绪事件也兜底到表情（开箱即用）', () async {
      final cmd = await repo.resolve(
          const EmotionEvent('emotion', 'angry'), 'm1');
      expect(haru.expressions, contains(cmd?.expressionId));
    });

    test('显式禁用的映射静音该 tag（不被哈希兜底复活）', () async {
      await addMapping(
          tag: 'angry', type: 'expression', target: 'f03', enabled: false);
      expect(
          await repo.resolve(const EmotionEvent('emotion', 'angry'), 'm1'),
          isNull);
    });

    test('无映射的动作事件不兜底（返回 null）', () async {
      expect(
          await repo.resolve(const EmotionEvent('action', 'wave'), 'm1'),
          isNull);
    });

    test('motion 组不存在时静默跳过', () async {
      await addMapping(tag: 'wave', type: 'motion', target: 'TapBody:0');
      expect(
          await repo.resolve(const EmotionEvent('action', 'wave'), 'm1'),
          isNull);
    });

    test('motion 序号越界回退到 0', () async {
      await addMapping(tag: 'wave', type: 'motion', target: 'Tap:9');
      final cmd =
          await repo.resolve(const EmotionEvent('action', 'wave'), 'm1');
      expect(cmd?.motionGroup, 'Tap');
      expect(cmd?.motionIndex, 0);
    });

    test('motion 组名大小写容错（tap → Tap）', () async {
      await addMapping(tag: 'wave', type: 'motion', target: 'tap:1');
      final cmd =
          await repo.resolve(const EmotionEvent('action', 'wave'), 'm1');
      expect(cmd?.motionGroup, 'Tap');
      expect(cmd?.motionIndex, 1);
    });

    test('resolveForMapping 与真实事件链行为一致', () async {
      final m = EmotionMapping(
        id: 'rt1',
        petModelId: haru.id,
        tag: 'happy',
        actionType: 'expression',
        targetId: 'F02',
      );
      final cmd = await repo.resolveForMapping(m, 'm1');
      expect(cmd?.expressionId, 'f02'); // 大小写容错同样生效
    });
  });

  group('PetOrchestrator', () {
    test('表情 8 秒后自动复位', () {
      fakeAsync((async) {
        final controller = _FakePetController();
        final orch = PetOrchestrator(
            controller: controller, repo: repo, petModelId: 'm1');

        orch.execute(const PetCommand.expression('happy'));
        async.flushMicrotasks();
        expect(controller.executed.last.expressionId, 'happy');

        async.elapse(const Duration(seconds: 7));
        expect(controller.executed.last.expressionId, 'happy'); // 未到 8s

        async.elapse(const Duration(seconds: 2));
        expect(controller.executed.last.expressionId, ''); // 已复位

        orch.dispose();
        controller.dispose();
      });
    });

    test('高优先级动作窗口内低优先级被掩蔽', () {
      fakeAsync((async) {
        final controller = _FakePetController();
        final orch = PetOrchestrator(
            controller: controller, repo: repo, petModelId: 'm1');

        orch.execute(const PetCommand.motion('TapBody', priority: 3));
        orch.execute(const PetCommand.motion('Idle', priority: 1));
        async.flushMicrotasks();
        final motions = controller.executed
            .where((c) => c.type == PetCommandType.startMotion)
            .toList();
        expect(motions, hasLength(1));
        expect(motions.single.motionGroup, 'TapBody');

        // 3s 窗口过后低优先级可以播放。
        async.elapse(const Duration(seconds: 4));
        orch.execute(const PetCommand.motion('Idle', priority: 1));
        async.flushMicrotasks();
        expect(
            controller.executed
                .where((c) => c.type == PetCommandType.startMotion)
                .length,
            2);

        orch.dispose();
        controller.dispose();
      });
    });

    test('情绪事件流经映射驱动控制器', () async {
      await addMapping(tag: 'shy', type: 'expression', target: 'f03');
      final controller = _FakePetController();
      final orch = PetOrchestrator(
          controller: controller, repo: repo, petModelId: 'm1');
      final stream = StreamController<EmotionEvent>();
      orch.bindEmotionStream(stream.stream);

      stream.add(const EmotionEvent('emotion', 'shy'));
      await pumpEventQueue();
      expect(controller.executed.last.type, PetCommandType.setExpression);
      expect(controller.executed.last.expressionId, 'f03');

      stream.add(const EmotionEvent('emotion', 'unknown-tag'));
      await pumpEventQueue();
      // 无映射：不产生指令（最后一条仍是 shy）。
      expect(controller.executed.last.expressionId, 'f03');

      orch.dispose();
      stream.close();
      controller.dispose();
    });
  });
}
