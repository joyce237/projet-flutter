import 'package:flutter_test/flutter_test.dart';
import 'package:homepharma/models/user_model.dart';

void main() {
  group('UserModel', () {
    test('should create user from map correctly', () {
      // Arrange
      final map = {
        'name': 'John Doe',
        'email': 'john.doe@example.com',
        'role': 'user',
        'phoneNumber': '+33123456789',
        'createdAt': DateTime(2024, 1, 1).millisecondsSinceEpoch,
        'lastLoginAt': DateTime(2024, 1, 2).millisecondsSinceEpoch,
      };
      
      // Act
      final user = UserModel.fromMap(map, 'user123');
      
      // Assert
      expect(user.id, 'user123');
      expect(user.name, 'John Doe');
      expect(user.email, 'john.doe@example.com');
      expect(user.role, 'user');
      expect(user.phoneNumber, '+33123456789');
      expect(user.isUser, true);
      expect(user.isPharmacist, false);
    });

    test('should convert user to map correctly', () {
      // Arrange
      final user = UserModel(
        id: 'user123',
        name: 'Jane Doe',
        email: 'jane.doe@example.com',
        role: 'pharmacist',
        pharmacyId: 'pharmacy123',
        createdAt: DateTime(2024, 1, 1),
      );
      
      // Act
      final map = user.toMap();
      
      // Assert
      expect(map['name'], 'Jane Doe');
      expect(map['email'], 'jane.doe@example.com');
      expect(map['role'], 'pharmacist');
      expect(map['pharmacyId'], 'pharmacy123');
      expect(map.containsKey('createdAt'), true);
    });

    test('should generate correct initials', () {
      // Test single name
      final user1 = UserModel(
        id: 'user1',
        name: 'John',
        email: 'john@example.com',
        role: 'user',
        createdAt: DateTime.now(),
      );
      expect(user1.initials, 'J');

      // Test full name
      final user2 = UserModel(
        id: 'user2',
        name: 'John Doe',
        email: 'john.doe@example.com',
        role: 'user',
        createdAt: DateTime.now(),
      );
      expect(user2.initials, 'JD');

      // Test empty name (should use email)
      final user3 = UserModel(
        id: 'user3',
        name: '',
        email: 'test@example.com',
        role: 'user',
        createdAt: DateTime.now(),
      );
      expect(user3.initials, 'T');
    });

    test('should identify pharmacist correctly', () {
      // Arrange
      final pharmacist = UserModel(
        id: 'pharm1',
        name: 'Dr. Smith',
        email: 'smith@pharmacy.com',
        role: 'pharmacist',
        pharmacyId: 'pharmacy123',
        createdAt: DateTime.now(),
      );
      
      // Act & Assert
      expect(pharmacist.isPharmacist, true);
      expect(pharmacist.isUser, false);
    });

    test('should copy with new values', () {
      // Arrange
      final originalUser = UserModel(
        id: 'user123',
        name: 'John Doe',
        email: 'john@example.com',
        role: 'user',
        createdAt: DateTime.now(),
      );
      
      // Act
      final updatedUser = originalUser.copyWith(
        name: 'Jane Doe',
        phoneNumber: '+33123456789',
      );
      
      // Assert
      expect(updatedUser.id, originalUser.id);
      expect(updatedUser.name, 'Jane Doe');
      expect(updatedUser.email, originalUser.email);
      expect(updatedUser.phoneNumber, '+33123456789');
    });

    test('should use display name correctly', () {
      // Test with name
      final user1 = UserModel(
        id: 'user1',
        name: 'John Doe',
        email: 'john@example.com',
        role: 'user',
        createdAt: DateTime.now(),
      );
      expect(user1.displayName, 'John Doe');

      // Test without name (should use email)
      final user2 = UserModel(
        id: 'user2',
        name: '',
        email: 'john@example.com',
        role: 'user',
        createdAt: DateTime.now(),
      );
      expect(user2.displayName, 'john@example.com');
    });
  });
}