import 'package:flutter_test/flutter_test.dart';

void main() {
  test('should correctly add two numbers', () {
    // Arrange
    const a = 5;
    const b = 3;

    // Act
    const result = a + b;

    // Assert
    expect(result, equals(8));
  });
}
