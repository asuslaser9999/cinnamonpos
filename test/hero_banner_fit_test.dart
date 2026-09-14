import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cinnamonpos/models/hero_banner_fit.dart';

void main() {
  test('hero banner fit maps to box fit and storage key', () {
    expect(HeroBannerFit.contain.boxFit, BoxFit.contain);
    expect(HeroBannerFit.fill.boxFit, BoxFit.fill);
    expect(HeroBannerFit.fromStorageKey('fill'), HeroBannerFit.fill);
    expect(HeroBannerFit.fromStorageKey(null), HeroBannerFit.cover);
  });
}
