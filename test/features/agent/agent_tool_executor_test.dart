import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

import 'package:ai_roleplay_chat/features/agent/application/agent_tools.dart';
import 'package:ai_roleplay_chat/features/agent/data/device_gateway.dart';
import 'package:ai_roleplay_chat/features/agent/data/saf_gateway.dart';
import 'package:ai_roleplay_chat/features/agent/domain/agent_approval.dart';
import 'package:ai_roleplay_chat/features/chat/data/chat_api_client.dart';
import 'package:path/path.dart' as p;

class _FakeSaf implements SafGateway {
  final List<String> calls = [];
  final Map<String, String> files = {'hello.txt': '你好'};

  @override
  Future<AgentGrantedFolder?> pickDirectory() async =>
      const AgentGrantedFolder(uri: 'tree://docs', name: '文档');

  @override
  Future<List<SafEntry>> list(String uri, String path) async {
    calls.add('list:$path');
    return const [
      SafEntry(
        name: 'hello.txt',
        path: 'hello.txt',
        isDir: false,
        size: 2,
        modified: null,
      ),
    ];
  }

  @override
  Future<Uint8List> read(String uri, String path) async {
    calls.add('read:$path');
    return Uint8List.fromList(utf8.encode(files[path] ?? ''));
  }

  @override
  Future<void> write(String uri, String path, String content) async {
    calls.add('write:$path');
    files[path] = content;
  }

  @override
  Future<void> writeBytes(String uri, String path, Uint8List bytes) async {
    calls.add('writeBytes:$path');
    files[path] = utf8.decode(bytes, allowMalformed: true);
  }

  @override
  Future<void> delete(String uri, String path) async {
    calls.add('delete:$path');
    files.remove(path);
  }

  @override
  Future<void> rename(String uri, String path, String newName) async {
    calls.add('rename:$path->$newName');
  }

  @override
  Future<void> move(String uri, String from, String to) async {
    calls.add('move:$from->$to');
  }

  @override
  Future<bool> exists(String uri, String path) async => files.containsKey(path);
}

class _FakeDevice implements DeviceGateway {
  _FakeDevice({
    this.shizukuGranted = true,
    this.accessibilityEnabled = true,
  });

  bool shizukuGranted;
  bool accessibilityEnabled;
  final List<String> commands = [];
  final List<String> clicks = [];

  @override
  Future<DeviceStatus> status() async => DeviceStatus(
        shizukuAvailable: true,
        shizukuGranted: shizukuGranted,
        accessibilityEnabled: accessibilityEnabled,
      );

  @override
  Future<void> requestShizuku() async {}

  @override
  Future<DeviceShellResult> shell(String command) async {
    commands.add(command);
    return const DeviceShellResult(code: 0, stdout: 'hi\n', stderr: '');
  }

  @override
  Future<String> uiText() async => '设置\n保存';

  @override
  Future<bool> clickText(String text) async {
    clicks.add(text);
    return true;
  }

  @override
  Future<void> openAccessibilitySettings() async {}
}

void main() {
  late Directory dir;
  late AgentWorkspace workspace;
  late AgentToolExecutor executor;

  ApiToolCall call(String name, [Map<String, dynamic> args = const {}]) =>
      ApiToolCall(id: 'call-1', name: name, arguments: jsonEncode(args));

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('agent_ws_test_');
    workspace = AgentWorkspace(dir);
    executor = AgentToolExecutor(workspace: workspace);
  });

  tearDown(() async {
    // Windows 上被杀掉的 shell 子进程可能短暂占用目录，重试几次。
    for (var i = 0; i < 20; i++) {
      try {
        if (await dir.exists()) await dir.delete(recursive: true);
        return;
      } on FileSystemException {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
    }
  });

  test('write_file 建父目录，read_file 读回，list_files 列出', () async {
    final write = jsonDecode(
      await executor.execute(
        call('write_file', {'path': 'notes/a.txt', 'content': '你好，世界'}),
      ),
    ) as Map<String, dynamic>;
    expect(write['ok'], isTrue);
    expect(write['path'], 'notes/a.txt');
    expect(write['chars'], 5);

    final read = jsonDecode(
      await executor.execute(call('read_file', {'path': 'notes/a.txt'})),
    ) as Map<String, dynamic>;
    expect(read['ok'], isTrue);
    expect(read['content'], '你好，世界');
    expect(read['total'], 5);
    expect(read['nextOffset'], isNull);

    final root = jsonDecode(
      await executor.execute(call('list_files')),
    ) as Map<String, dynamic>;
    expect(root['ok'], isTrue);
    final items = root['items'] as List;
    expect(items.single['name'], 'notes');
    expect(items.single['type'], 'dir');

    final sub = jsonDecode(
      await executor.execute(call('list_files', {'path': 'notes'})),
    ) as Map<String, dynamic>;
    expect((sub['items'] as List).single['name'], 'a.txt');
  });

  test('read_file 分页：offset/limit 与 nextOffset', () async {
    await workspace.writeFile('n.txt', 'abcdefghij');
    final read = jsonDecode(
      await executor.execute(
        call('read_file', {'path': 'n.txt', 'offset': 2, 'limit': 3}),
      ),
    ) as Map<String, dynamic>;
    expect(read['content'], 'cde');
    expect(read['nextOffset'], 5);

    final tail = jsonDecode(
      await executor.execute(
        call('read_file', {'path': 'n.txt', 'offset': 8, 'limit': 100}),
      ),
    ) as Map<String, dynamic>;
    expect(tail['content'], 'ij');
    expect(tail['nextOffset'], isNull);
  });

  test('路径安全：绝对路径、盘符、.. 全部拒绝', () async {
    for (final path in ['/etc/passwd', r'C:\Windows\win.ini', '../x.txt']) {
      final result = jsonDecode(
        await executor.execute(call('write_file', {
          'path': path,
          'content': 'x',
        })),
      ) as Map<String, dynamic>;
      expect(result['ok'], isFalse, reason: path);
      expect(result['error'], isNotEmpty, reason: path);
    }
    final read = jsonDecode(
      await executor.execute(call('read_file', {'path': '../x.txt'})),
    ) as Map<String, dynamic>;
    expect(read['ok'], isFalse);
  });

  test('写入上限 64,000 字符', () async {
    final result = jsonDecode(
      await executor.execute(
        call('write_file', {'path': 'big.txt', 'content': 'a' * 64001}),
      ),
    ) as Map<String, dynamic>;
    expect(result['ok'], isFalse);
    expect(result['error'].toString(), contains('64,000'));
  });

  test('非 UTF-8 与不存在的文件返回业务错误', () async {
    final bytes = File(p.join(dir.path, 'bin.dat'));
    await bytes.writeAsBytes([0xFF, 0xFE, 0x00]);

    final bad = jsonDecode(
      await executor.execute(call('read_file', {'path': 'bin.dat'})),
    ) as Map<String, dynamic>;
    expect(bad['ok'], isFalse);
    expect(bad['error'].toString(), contains('UTF-8'));

    final missing = jsonDecode(
      await executor.execute(call('read_file', {'path': 'missing.txt'})),
    ) as Map<String, dynamic>;
    expect(missing['ok'], isFalse);
    expect(missing['error'].toString(), contains('不存在'));
  });

  test('参数非法/未知工具都返回 JSON 错误，不抛出', () async {
    final badJson = jsonDecode(
      await executor.execute(
        const ApiToolCall(id: 'x', name: 'read_file', arguments: '{oops'),
      ),
    ) as Map<String, dynamic>;
    expect(badJson['ok'], isFalse);

    final nonObject = jsonDecode(
      await executor.execute(
        const ApiToolCall(id: 'x', name: 'read_file', arguments: '[]'),
      ),
    ) as Map<String, dynamic>;
    expect(nonObject['ok'], isFalse);

    final unknown = jsonDecode(
      await executor.execute(call('delete_all', {})),
    ) as Map<String, dynamic>;
    expect(unknown['ok'], isFalse);
    expect(unknown['error'].toString(), contains('未知工具'));
  });

  test('clear 会清空工作区但保留根目录', () async {
    await workspace.writeFile('a.txt', 'x');
    await workspace.clear();
    expect(await dir.exists(), isTrue);
    expect(await dir.list().toList(), isEmpty);
  });

  group('文件变更（v1.5 扩权）', () {
    test('rename → move → delete 全链路', () async {
      await workspace.writeFile('a.txt', 'hello');

      final renamed = jsonDecode(
        await executor.execute(
          call('rename', {'path': 'a.txt', 'new_name': 'b.txt'}),
        ),
      ) as Map<String, dynamic>;
      expect(renamed['ok'], isTrue);
      expect(await File(p.join(dir.path, 'b.txt')).readAsString(), 'hello');

      final moved = jsonDecode(
        await executor.execute(
          call('move_file', {'from': 'b.txt', 'to': 'sub/c.txt'}),
        ),
      ) as Map<String, dynamic>;
      expect(moved['ok'], isTrue);
      expect(await File(p.join(dir.path, 'sub', 'c.txt')).exists(), isTrue);
      expect(await File(p.join(dir.path, 'b.txt')).exists(), isFalse);

      final deleted = jsonDecode(
        await executor.execute(call('delete_file', {'path': 'sub/c.txt'})),
      ) as Map<String, dynamic>;
      expect(deleted['ok'], isTrue);
      expect(deleted['deleted'], isTrue);
      expect(await File(p.join(dir.path, 'sub', 'c.txt')).exists(), isFalse);
    });

    test('delete 非空目录被业务拒绝', () async {
      await workspace.writeFile('d/x.txt', 'x');
      final result = jsonDecode(
        await executor.execute(call('delete_file', {'path': 'd'})),
      ) as Map<String, dynamic>;
      expect(result['ok'], isFalse);
      expect(result['error'].toString(), contains('目录不为空'));
    });
  });

  group('run_command', () {
    test('执行命令并返回 stdout/exitCode', () async {
      final result = jsonDecode(
        await executor.execute(
          call('run_command', {'command': 'echo hello'}),
        ),
      ) as Map<String, dynamic>;
      expect(result['ok'], isTrue);
      expect(result['exitCode'], 0);
      expect(result['stdout'].toString(), contains('hello'));
    });

    test('拒绝 su', () async {
      final result = jsonDecode(
        await executor.execute(
          call('run_command', {'command': 'su -c id'}),
        ),
      ) as Map<String, dynamic>;
      expect(result['ok'], isFalse);
      expect(result['error'].toString(), contains('su'));
    });

    test('超时会 kill 并标记 timedOut', () async {
      final command =
          Platform.isWindows ? 'ping -n 4 127.0.0.1 >nul' : 'sleep 3';
      final result = jsonDecode(
        await executor.execute(
          call('run_command', {'command': command, 'timeout_ms': 1000}),
        ),
      ) as Map<String, dynamic>;
      expect(result['ok'], isTrue);
      expect(result['timedOut'], isTrue);
    }, timeout: const Timeout(Duration(seconds: 15)));
  });

  group('http_request 安全边界', () {
    test('拒绝本机与内网地址', () async {
      for (final url in [
        'http://localhost:8080/x',
        'http://127.0.0.1/x',
        'http://10.1.2.3/x',
        'http://192.168.1.2/x',
        'http://172.20.1.1/x',
        'http://[::1]/x',
        'ftp://example.com/x',
      ]) {
        final result = jsonDecode(
          await executor.execute(call('http_request', {'url': url})),
        ) as Map<String, dynamic>;
        expect(result['ok'], isFalse, reason: url);
      }
    });

    test('域名白名单不匹配时拒绝', () async {
      final scoped = AgentToolExecutor(
        workspace: workspace,
        httpDomains: () async => ['example.com'],
      );
      final result = jsonDecode(
        await scoped.execute(
          call('http_request', {'url': 'https://blocked.org/api'}),
        ),
      ) as Map<String, dynamic>;
      expect(result['ok'], isFalse);
      expect(result['error'].toString(), contains('允许列表'));
    });
  });

  group('SAF 授权文件夹', () {
    test('list_roots 包含授权文件夹，list/read/write 走 SAF', () async {
      final saf = _FakeSaf();
      final scoped = AgentToolExecutor(
        workspace: workspace,
        saf: saf,
        grantedFolders: () async => const [
          AgentGrantedFolder(uri: 'tree://docs', name: '文档'),
        ],
      );

      final roots = jsonDecode(
        await scoped.execute(call('list_roots', {})),
      ) as Map<String, dynamic>;
      expect(
        (roots['roots'] as List).map((r) => r['name']),
        containsAll(['工作区', '文档']),
      );

      final list = jsonDecode(
        await scoped.execute(call('list_files', {'root': '文档'})),
      ) as Map<String, dynamic>;
      expect(list['ok'], isTrue);
      expect((list['items'] as List).first['name'], 'hello.txt');

      final read = jsonDecode(
        await scoped.execute(
          call('read_file', {'root': '文档', 'path': 'hello.txt'}),
        ),
      ) as Map<String, dynamic>;
      expect(read['content'], '你好');

      final write = jsonDecode(
        await scoped.execute(
          call('write_file', {
            'root': '文档',
            'path': 'new.txt',
            'content': 'abc',
          }),
        ),
      ) as Map<String, dynamic>;
      expect(write['ok'], isTrue);
      expect(saf.files['new.txt'], 'abc');
    });

    test('未知根返回业务错误', () async {
      final result = jsonDecode(
        await executor.execute(call('list_files', {'root': '不存在'})),
      ) as Map<String, dynamic>;
      expect(result['ok'], isFalse);
      expect(result['error'].toString(), contains('未知根'));
    });
  });

  group('web_search', () {
    test('优先解析 360 结果并解码跳转链接', () async {
      final searchExecutor = AgentToolExecutor(
        workspace: workspace,
        webSearchHtml: (uri) async {
          expect(uri.host, 'm.so.com');
          expect(uri.queryParameters['q'], 'flutter');
          return '''
<a href="https://m.so.com/jump?u=https%3A%2F%2Fflutter.dev&m=1" class="title"><h3 class="res-title"><span>Flutter 官网</span></h3></a>
<a href="https://m.so.com/jump?u=https%3A%2F%2Fdart.dev" class="title"><h3 class="res-title">Dart</h3></a>
''';
        },
      );
      final result = jsonDecode(
        await searchExecutor.execute(
          call('web_search', {'query': 'flutter', 'max_results': 2}),
        ),
      ) as Map<String, dynamic>;
      expect(result['ok'], isTrue);
      expect(result['source'], '360');
      expect(result['count'], 2);
      final results = result['results'] as List;
      expect(results[0]['url'], 'https://flutter.dev');
      expect(results[0]['title'], 'Flutter 官网');
      expect(results[1]['url'], 'https://dart.dev');
      expect(searchExecutor.riskFor('web_search'), AgentToolRisk.network);
    });

    test('360/百度无结果时回退 Bing RSS', () async {
      final searchExecutor = AgentToolExecutor(
        workspace: workspace,
        webSearchHtml: (uri) async {
          if (uri.host == 'www.so.com' || uri.host == 'm.baidu.com') {
            return '<html><body>no results</body></html>';
          }
          expect(uri.host, 'cn.bing.com');
          expect(uri.queryParameters['format'], 'rss');
          return '''
<rss><channel>
<item><title>Flutter 官网</title><link>https://flutter.dev</link>
<description>构建 多端 应用 的框架</description></item>
</channel></rss>
''';
        },
      );
      final result = jsonDecode(
        await searchExecutor.execute(
          call('web_search', {'query': 'flutter', 'max_results': 2}),
        ),
      ) as Map<String, dynamic>;
      expect(result['ok'], isTrue);
      expect(result['source'], 'bing');
      expect((result['results'] as List).single['title'], 'Flutter 官网');
    });

    test('Bing 失败时回退 DuckDuckGo 并解码跳转链接', () async {
      final searchExecutor = AgentToolExecutor(
        workspace: workspace,
        webSearchHtml: (uri) async {
          if (uri.host == 'www.so.com' || uri.host == 'm.baidu.com') {
            return '<html><body>no results</body></html>';
          }
          if (uri.host == 'cn.bing.com') {
            throw const SocketException('blocked');
          }
          expect(uri.host, 'html.duckduckgo.com');
          return '''
<a class="result__a" href="//duckduckgo.com/l/?uddg=https%3A%2F%2Fflutter.dev&amp;rut=abc">Flutter</a>
<a class="result__snippet">多端框架</a>
''';
        },
      );
      final result = jsonDecode(
        await searchExecutor.execute(
          call('web_search', {'query': 'flutter'}),
        ),
      ) as Map<String, dynamic>;
      expect(result['ok'], isTrue);
      expect(result['source'], 'duckduckgo');
      expect((result['results'] as List).single['url'], 'https://flutter.dev');
    });

    test('全部搜索源失败时返回包含各源错误的业务错误', () async {
      final searchExecutor = AgentToolExecutor(
        workspace: workspace,
        webSearchHtml: (uri) async {
          throw const SocketException('blocked');
        },
      );
      final result = jsonDecode(
        await searchExecutor.execute(call('web_search', {'query': 'flutter'})),
      ) as Map<String, dynamic>;
      expect(result['ok'], isFalse);
      expect(result['error'].toString(), contains('联网搜索失败'));
      expect(result['error'].toString(), contains('360'));
    });

    test('空搜索词返回业务错误', () async {
      final result = jsonDecode(
        await executor.execute(call('web_search', {'query': '  '})),
      ) as Map<String, dynamic>;
      expect(result['ok'], isFalse);
      expect(result['error'].toString(), contains('搜索词'));
    });
  });

  group('convert_file', () {
    test('Markdown 转 HTML', () async {
      await workspace.writeFile('docs/a.md', '# 标题\n\n- 一\n- 二');
      final result = jsonDecode(
        await executor.execute(
          call('convert_file', {'path': 'docs/a.md', 'format': 'html'}),
        ),
      ) as Map<String, dynamic>;
      expect(result['ok'], isTrue);
      expect(result['path'], 'docs/a.html');
      final content = (await workspace.readEntry('docs/a.html')).content;
      expect(content, contains('<h1>标题</h1>'));
      expect(content, contains('<li>一</li>'));
    });

    test('CSV 转 JSON 保留引号内逗号', () async {
      await workspace.writeFile('data/a.csv', 'name,note\nA,"x,y"\nB,hello');
      final result = jsonDecode(
        await executor.execute(
          call('convert_file', {'path': 'data/a.csv', 'format': 'json'}),
        ),
      ) as Map<String, dynamic>;
      expect(result['ok'], isTrue);
      final list = jsonDecode(
        (await workspace.readEntry('data/a.json')).content,
      ) as List;
      expect(list, hasLength(2));
      expect(list.first['name'], 'A');
      expect(list.first['note'], 'x,y');
    });

    test('JSON 数组转 CSV', () async {
      await workspace.writeFile(
        'data/b.json',
        '[{"name":"A","v":1},{"name":"B","v":2}]',
      );
      final result = jsonDecode(
        await executor.execute(
          call('convert_file', {'path': 'data/b.json', 'format': 'csv'}),
        ),
      ) as Map<String, dynamic>;
      expect(result['ok'], isTrue);
      final csv = (await workspace.readEntry('data/b.csv')).content;
      expect(csv.split('\n').first, 'name,v');
      expect(csv, contains('A,1'));
    });

    test('图片转 PNG', () async {
      final image = img.Image(width: 3, height: 2);
      img.fill(image, color: img.ColorRgb8(200, 30, 40));
      final jpg = Uint8List.fromList(img.encodeJpg(image));
      await workspace.writeEntryBytes('pics/photo.jpg', jpg);
      final result = jsonDecode(
        await executor.execute(
          call('convert_file', {'path': 'pics/photo.jpg', 'format': 'png'}),
        ),
      ) as Map<String, dynamic>;
      expect(result['ok'], isTrue);
      expect(result['path'], 'pics/photo.png');
      final png = await workspace.readEntryBytes('pics/photo.png');
      final decoded = img.decodePng(png)!;
      expect(decoded.width, 3);
      expect(decoded.height, 2);
    });

    test('不支持的格式返回业务错误', () async {
      await workspace.writeFile('a.txt', 'hello');
      final result = jsonDecode(
        await executor.execute(
          call('convert_file', {'path': 'a.txt', 'format': 'pdf'}),
        ),
      ) as Map<String, dynamic>;
      expect(result['ok'], isFalse);
      expect(result['error'].toString(), contains('不支持'));
    });
  });

  group('device 工具（Shizuku/无障碍）', () {
    test('device_status 返回三项状态', () async {
      final device = _FakeDevice();
      final exec = AgentToolExecutor(workspace: workspace, device: device);
      final result = jsonDecode(
        await exec.execute(call('device_status')),
      ) as Map<String, dynamic>;
      expect(result['ok'], isTrue);
      expect(result['shizukuGranted'], isTrue);
      expect(result['accessibilityEnabled'], isTrue);
    });

    test('device_shell 已授权时执行命令并记录', () async {
      final device = _FakeDevice();
      final exec = AgentToolExecutor(workspace: workspace, device: device);
      final result = jsonDecode(
        await exec.execute(call('device_shell', {'command': 'echo hi'})),
      ) as Map<String, dynamic>;
      expect(result['ok'], isTrue);
      expect(result['stdout'], 'hi\n');
      expect(device.commands, ['echo hi']);
    });

    test('device_shell 未授权时拒绝执行', () async {
      final device = _FakeDevice(shizukuGranted: false);
      final exec = AgentToolExecutor(workspace: workspace, device: device);
      final result = jsonDecode(
        await exec.execute(call('device_shell', {'command': 'echo hi'})),
      ) as Map<String, dynamic>;
      expect(result['ok'], isFalse);
      expect(result['error'].toString(), contains('未授权'));
      expect(device.commands, isEmpty);
    });

    test('device_click_text / device_ui_text 正常返回', () async {
      final device = _FakeDevice();
      final exec = AgentToolExecutor(workspace: workspace, device: device);
      final click = jsonDecode(
        await exec.execute(call('device_click_text', {'text': '保存'})),
      ) as Map<String, dynamic>;
      expect(click['ok'], isTrue);
      expect(click['clicked'], isTrue);
      expect(device.clicks, ['保存']);

      final text = jsonDecode(
        await exec.execute(call('device_ui_text')),
      ) as Map<String, dynamic>;
      expect(text['ok'], isTrue);
      expect(text['text'], contains('保存'));
    });

    test('无障碍未开启时拒绝读屏/点击', () async {
      final device = _FakeDevice(accessibilityEnabled: false);
      final exec = AgentToolExecutor(workspace: workspace, device: device);
      final result = jsonDecode(
        await exec.execute(call('device_ui_text')),
      ) as Map<String, dynamic>;
      expect(result['ok'], isFalse);
      expect(result['error'].toString(), contains('无障碍'));
    });
  });
}