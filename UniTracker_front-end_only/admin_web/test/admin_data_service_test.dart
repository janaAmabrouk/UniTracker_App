import 'package:flutter_test/flutter_test.dart';
import 'package:admin_web/admin/services/admin_data_service.dart';
import 'package:admin_web/admin/services/email_service.dart';

void main() {
  group('AdminDataService Driver Management Tests', () {
    late AdminDataService adminDataService;

    setUp(() {
      adminDataService = AdminDataService();
    });

    test('should create AdminDataService instance', () {
      expect(adminDataService, isNotNull);
      expect(adminDataService, isA<AdminDataService>());
    });

    test('should have getAllDrivers method', () {
      expect(adminDataService.getAllDrivers, isA<Function>());
    });

    test('should have createDriver method', () {
      expect(adminDataService.createDriver, isA<Function>());
    });

    test('should have updateDriver method', () {
      expect(adminDataService.updateDriver, isA<Function>());
    });

    test('should have deleteDriver method', () {
      expect(adminDataService.deleteDriver, isA<Function>());
    });
  });

  group('Email Service Tests', () {
    test('should create EmailService instance', () {
      final emailService = EmailService();
      expect(emailService, isNotNull);
      expect(emailService, isA<EmailService>());
    });

    test('should have sendWelcomeEmail method', () {
      final emailService = EmailService();
      expect(emailService.sendWelcomeEmail, isA<Function>());
    });
  });
}
