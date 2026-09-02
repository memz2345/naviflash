import 'package:flutter_test/flutter_test.dart';
import 'package:naviflash/services/sponsor_block_service.dart';

void main() {
  group('SponsorSegment.fromJson', () {
    test('parses intro segment seconds to ms', () {
      final seg = SponsorSegment.fromJson({
        'category': 'intro',
        'segment': [12.5, 42.0],
        'UUID': 'abc-123',
      });
      expect(seg.category, 'intro');
      expect(seg.startMs, 12500);
      expect(seg.endMs, 42000);
      expect(seg.uuid, 'abc-123');
      expect(seg.skipped, isFalse);
      expect(seg.isSkipableCategory, isTrue);
    });

    test('parses outro segment', () {
      final seg = SponsorSegment.fromJson({
        'category': 'outro',
        'segment': [300, 315],
        'UUID': 'x',
      });
      expect(seg.category, 'outro');
      expect(seg.startMs, 300000);
      expect(seg.endMs, 315000);
      expect(seg.isSkipableCategory, isTrue);
    });

    test('non intro/outro categories are not skipable', () {
      final seg = SponsorSegment.fromJson({
        'category': 'sponsor',
        'segment': [1, 2],
        'UUID': 'y',
      });
      expect(seg.isSkipableCategory, isFalse);
    });

    test('handles missing/invalid segment', () {
      final seg = SponsorSegment.fromJson({'category': 'intro'});
      expect(seg.startMs, 0);
      expect(seg.endMs, 0);
    });
  });
}
