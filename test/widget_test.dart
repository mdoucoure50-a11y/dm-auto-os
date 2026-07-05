import 'package:flutter_test/flutter_test.dart';

import 'package:dm_auto_os/core/constants/app_modules.dart';
import 'package:dm_auto_os/core/permissions/app_permission.dart';
import 'package:dm_auto_os/core/permissions/user_role.dart';
import 'package:dm_auto_os/core/routing/app_routes.dart';
import 'package:dm_auto_os/core/utils/currency_formatter.dart';

void main() {
  group('Module priorities', () {
    test('Phase 1 has 7 primary modules in correct order', () {
      expect(AppModule.phase1Modules.length, 7);
      expect(AppModule.phase1Modules.first.id, AppModuleId.rentals);
      expect(AppModule.phase1Modules[1].id, AppModuleId.cashbook);
      expect(AppModule.phase1Modules.last.id, AppModuleId.documents);
    });

    test('Workshop is secondary module', () {
      expect(AppModule.workshopModule.tier, ModuleTier.secondary);
      expect(AppModule.workshopModule.developmentPriority, greaterThan(10));
    });

    test('Workshop is not in compact mobile navigation', () {
      final workshop = AppNavigation.destinations
          .where((d) => d.moduleId == AppModuleId.workshop)
          .first;
      expect(workshop.showInCompactNav, isFalse);
      expect(workshop.tier, ModuleTier.secondary);
    });
  });

  group('RolePermissions', () {
    test('employee has cashbook and rental period permissions', () {
      expect(
        RolePermissions.hasPermission(
          UserRole.employee,
          AppPermission.viewCashbook,
        ),
        isTrue,
      );
      expect(
        RolePermissions.hasPermission(
          UserRole.employee,
          AppPermission.viewRentalPeriods,
        ),
        isTrue,
      );
    });

    test('only administrator can close rental periods', () {
      expect(
        RolePermissions.hasPermission(
          UserRole.administrator,
          AppPermission.closeRentalPeriod,
        ),
        isTrue,
      );
      expect(
        RolePermissions.hasPermission(
          UserRole.employee,
          AppPermission.closeRentalPeriod,
        ),
        isFalse,
      );
    });

    test('employee retains optional workshop access', () {
      expect(
        RolePermissions.hasPermission(
          UserRole.employee,
          AppPermission.viewServices,
        ),
        isTrue,
      );
    });
  });

  group('CurrencyFormatter', () {
    test('formats XAF amounts without decimals', () {
      final formatted = CurrencyFormatter.format(150000);
      expect(formatted, contains('FCFA'));
    });
  });
}
