import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Content Gate Tests', () {
    const bannedWords = [
      'forgot',
      'missed',
      'should',
      'must',
      'sad',
      'wrong',
      'risk',
      'danger',
      'kick',
      'kicked',
      'blood',
      'potion',
    ];

    bool passesGate(String text, String status) {
      if (status != 'approved') return false;
      final lower = text.toLowerCase();
      for (final word in bannedWords) {
        if (lower.contains(word)) return false;
      }
      return true;
    }

    test('Valid approved line passes gate', () {
      const line = 'Iron snack? Lentils or beans, your pick.';
      expect(passesGate(line, 'approved'), isTrue);
    });

    test('Planted bad record with banned guilt word is rejected', () {
      const line = 'You missed your vitamin yesterday!';
      expect(passesGate(line, 'approved'), isFalse);
    });

    test('Planted bad record with draft status is rejected', () {
      const line = 'Cape on. Thank you!';
      expect(passesGate(line, 'draft'), isFalse);
    });
  });
}
