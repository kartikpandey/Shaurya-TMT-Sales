import 'package:flutter_test/flutter_test.dart';
import 'package:sales_app/core/domain/user_role.dart';
import 'package:sales_app/core/permissions/permission_service.dart';

void main() {
  group('team visibility', () {
    test('only non-executive roles get the Team Activity tab', () {
      expect(PermissionService.canViewTeam(InternalRole.salesManager), isTrue);
      expect(PermissionService.canViewTeam(InternalRole.teamLead), isTrue);
      expect(
        PermissionService.canViewTeam(InternalRole.seniorSalesExecutive),
        isTrue,
      );
      expect(
        PermissionService.canViewTeam(InternalRole.salesExecutive),
        isFalse,
      );
    });

    test('a head observes strictly lower ranks', () {
      expect(
        PermissionService.canObserve(
          InternalRole.salesManager,
          InternalRole.salesExecutive,
        ),
        isTrue,
      );
      expect(
        PermissionService.canObserve(InternalRole.teamLead, InternalRole.teamLead),
        isFalse,
      );
      expect(
        PermissionService.canObserve(
          InternalRole.salesExecutive,
          InternalRole.salesManager,
        ),
        isFalse,
      );
    });
  });

  group('internal user creation', () {
    test('only strictly subordinate roles can be created', () {
      expect(
        PermissionService.canCreateInternalRole(
          InternalRole.salesManager,
          InternalRole.teamLead,
        ),
        isTrue,
      );
      expect(
        PermissionService.canCreateInternalRole(
          InternalRole.teamLead,
          InternalRole.seniorSalesExecutive,
        ),
        isTrue,
      );
      expect(
        PermissionService.canCreateInternalRole(
          InternalRole.teamLead,
          InternalRole.teamLead,
        ),
        isFalse,
      );
      expect(
        PermissionService.canCreateInternalRole(
          InternalRole.salesExecutive,
          InternalRole.salesExecutive,
        ),
        isFalse,
      );
      expect(
        PermissionService.canCreateInternalRole(
          InternalRole.seniorSalesExecutive,
          InternalRole.teamLead,
        ),
        isFalse,
      );
    });
  });

  group('external customer creation', () {
    test('distributors are restricted to manager / team lead', () {
      expect(
        PermissionService.canCreateExternalEntity(
          InternalRole.salesManager,
          ExternalEntityType.distributor,
        ),
        isTrue,
      );
      expect(
        PermissionService.canCreateExternalEntity(
          InternalRole.teamLead,
          ExternalEntityType.distributor,
        ),
        isTrue,
      );
      expect(
        PermissionService.canCreateExternalEntity(
          InternalRole.seniorSalesExecutive,
          ExternalEntityType.distributor,
        ),
        isFalse,
      );
    });

    test('dealers and sub-dealers are open to every internal role', () {
      for (final role in InternalRole.values) {
        expect(
          PermissionService.canCreateExternalEntity(
            role,
            ExternalEntityType.dealer,
          ),
          isTrue,
        );
        expect(
          PermissionService.canCreateExternalEntity(
            role,
            ExternalEntityType.subDealer,
          ),
          isTrue,
        );
      }
    });
  });

  group('order editing', () {
    test('owners always edit their own orders', () {
      expect(
        PermissionService.canEditOrder(
          targetIsSelf: true,
          targetInDownline: false,
          actor: InternalRole.salesExecutive,
        ),
        isTrue,
      );
    });

    test('heads edit downline orders but never stranger orders', () {
      expect(
        PermissionService.canEditOrder(
          targetIsSelf: false,
          targetInDownline: true,
          actor: InternalRole.teamLead,
        ),
        isTrue,
      );
      expect(
        PermissionService.canEditOrder(
          targetIsSelf: false,
          targetInDownline: false,
          actor: InternalRole.salesManager,
        ),
        isFalse,
      );
      expect(
        PermissionService.canEditOrder(
          targetIsSelf: false,
          targetInDownline: true,
          actor: InternalRole.salesExecutive,
        ),
        isFalse,
      );
    });
  });
}
