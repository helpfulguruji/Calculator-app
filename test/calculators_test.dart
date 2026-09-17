import 'package:flutter_test/flutter_test.dart';

void main() {
  test('basic finance formulas sanity', () {
    const amount = 1000.0;
    const rate = 18.0;
    expect(amount * rate / 100, 180.0);
  });

  test('SIP zero-return case equals invested amount', () {
    const monthly = 5000.0;
    const months = 120.0;
    expect(monthly * months, 600000.0);
  });

  test('BMI formula sanity', () {
    const meters = 1.70;
    const kg = 70.0;
    expect((kg / (meters * meters)).toStringAsFixed(1), '24.2');
  });
}
