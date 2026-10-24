import 'package:all_in_one_calculator/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('word counter counts whitespace-separated words and non-empty lines', () {
    const text = 'alpha  beta\n\ngamma\n   \ndelta\n';
    final counted = countWordCounterText(text);

    expect(counted.words, 4);
    expect(counted.lines, 3);
    expect(counted.characters, text.length);
  });

  test('word counter returns zero for empty or whitespace-only text', () {
    final empty = countWordCounterText('');
    expect(empty.words, 0);
    expect(empty.lines, 0);
    expect(empty.characters, 0);

    final spaces = countWordCounterText(' \n\t ');
    expect(spaces.words, 0);
    expect(spaces.lines, 0);
    expect(spaces.characters, 4);
  });

  test('blank lines between text are not counted', () {
    const text = 'one\ntwo\n\nthree';
    final counted = countWordCounterText(text);
    expect(counted.words, 3);
    expect(counted.lines, 3);
    expect(counted.characters, text.length);
  });
}
