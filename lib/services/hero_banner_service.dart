import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/painting.dart';
import 'package:path_provider/path_provider.dart';

class HeroBannerService {
  static const fileName = 'cn_hero_banner.jpg';

  Future<File> destFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$fileName');
  }

  Future<String> save(Uint8List bytes) async {
    final file = await destFile();
    await file.writeAsBytes(bytes, flush: true);
    await FileImage(file).evict();
    return file.path;
  }

  Future<void> clear() async {
    final file = await destFile();
    if (await file.exists()) {
      await FileImage(file).evict();
      await file.delete();
    }
  }
}
