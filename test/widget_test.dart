import 'package:flutter_test/flutter_test.dart';

import 'package:dm_auto_os/core/permissions/app_permission.dart';
import 'package:dm_auto_os/core/permissions/user_role.dart';
import 'package:dm_auto_os/core/utils/currency_formatter.dart';

void main() {
  group('RolePermissions', () {
    test('administrator has all employee permissions plus admin-only', () {
      expect(
        RolePermissions.hasPermission(
          UserRole.administrator,
          AppPermission.deleteVehicle,
        ),
        isTrue,
      );
      expect(
        RolePermissions.hasPermission(
          UserRole.employee,
          AppPermission.deleteVehicle,
        ),
        isFalse,
      );
    });

    test('employee can view and create rentals', () {
      expect(
        RolePermissions.hasPermission(
          UserRole.employee,
          AppPermission.viewRentals,
        ),
        isTrue,
      );
      expect(
        RolePermissions.hasPermission(
          UserRole.employee,
          AppPermission.createRental,
        ),
        isTrue,
      );
    });

    test('only administrator can manage users', () {
      expect(
        RolePermissions.hasPermission(
          UserRole.administrator,
          AppPermission.manageUsers,
        ),
        isTrue,
      );
      expect(
        RolePermissions.hasPermission(
          UserRole.employee,
          AppPermission.manageUsers,
        ),
        isFalse,
      );
    });
  });

  group('CurrencyFormatter', () {
    test('formats XAF amounts without decimals', () {
      final formatted = CurrencyFormatter.format(150000);
      expect(formatted, contains('FCFA'));
    });

    test('parses numeric strings', () {
      expect(CurrencyFormatter.parse('150 000 FCFA'), 150000);
    });
  });
}
