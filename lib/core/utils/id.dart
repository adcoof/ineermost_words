/// id 生成。
library;

import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// 生成随机 v4 id。
String newId() => _uuid.v4();