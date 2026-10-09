import 'package:flutter_test/flutter_test.dart';
import 'package:sales_app/core/domain/user_role.dart';
import 'package:sales_app/features/users/domain/entities/app_user.dart';
import 'package:sales_app/features/users/domain/user_hierarchy.dart';

AppUser _internal({
  required String id,
  required InternalRole role,
  String? reportsToId,
}) => AppUser(
  id: id,
  kind: UserKind.internal,
  name: 'User $id',
  email: '$id@example.com',
  phone: '9000000000',
  role: role,
  reportsToId: reportsToId,
  createdAt: DateTime(2026, 1, 1),
);

void main() {
  final manager = _internal(id: 'm', role: InternalRole.salesManager);
  final leadA = _internal(
    id: 'la',
    role: InternalRole.teamLead,
    reportsToId: 'm',
  );
  final leadB = _internal(
    id: 'lb',
    role: InternalRole.teamLead,
    reportsToId: 'm',
  );
  final srA = _internal(
    id: 'sa',
    role: InternalRole.seniorSalesExecutive,
    reportsToId: 'la',
  );
  final seA1 = _internal(
    id: 'ea1',
    role: InternalRole.salesExecutive,
    reportsToId: 'la',
  );
  final seA2 = _internal(
    id: 'ea2',
    role: InternalRole.salesExecutive,
    reportsToId: 'sa',
  );
  final seB = _internal(
    id: 'eb',
    role: InternalRole.salesExecutive,
    reportsToId: 'lb',
  );

  final all = [manager, leadA, leadB, srA, seA1, seA2, seB];

  group('UserHierarchy.downlineOf', () {
    test('manager sees the whole organisation but not themselves', () {
      final downline = UserHierarchy.downlineOf(all, 'm');
      expect(
        downline.map((u) => u.id).toSet(),
        {'la', 'lb', 'sa', 'ea1', 'ea2', 'eb'},
      );
      expect(downline.map((u) => u.id), isNot(contains('m')));
    });

    test('a team lead only sees their own branch', () {
      final downline = UserHierarchy.downlineOf(all, 'la');
      expect(downline.map((u) => u.id).toSet(), {'sa', 'ea1', 'ea2'});
      expect(downline.map((u) => u.id), isNot(contains('eb')));
      expect(downline.map((u) => u.id), isNot(contains('lb')));
    });

    test('a sales executive has no downline', () {
      expect(UserHierarchy.downlineOf(all, 'ea1'), isEmpty);
    });

    test('downline is transitive through intermediate ranks', () {
      final ids = UserHierarchy.downlineOf(all, 'sa').map((u) => u.id);
      expect(ids, contains('ea2'));
    });
  });

  group('UserHierarchy.scopeIds / isInDownline', () {
    test('scope includes self, downline does not', () {
      expect(UserHierarchy.scopeIds(all, 'la').toSet(), {'la', 'sa', 'ea1', 'ea2'});
      expect(
        UserHierarchy.downlineOf(all, 'la').map((u) => u.id).toSet(),
        {'sa', 'ea1', 'ea2'},
      );
    });

    test('isInDownline rejects siblings and superiors', () {
      expect(UserHierarchy.isInDownline(all, 'la', 'ea2'), isTrue);
      expect(UserHierarchy.isInDownline(all, 'la', 'eb'), isFalse);
      expect(UserHierarchy.isInDownline(all, 'la', 'm'), isFalse);
      expect(UserHierarchy.isInDownline(all, 'm', 'm'), isFalse);
    });
  });
}
