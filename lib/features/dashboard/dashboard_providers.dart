import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gitle/common/instances.dart';
import 'package:gitle/features/repositories/repository_dto.dart';
import 'package:mekart/mekart.dart';

abstract final class DashboardProviders {
  static final config = StreamProvider((ref) {
    return Instances.bin.dashboard.stream;
  });

  static Future<void> upsertGroup(String uid, {required String? oldUid}) async {
    await Instances.bin.runTransaction((tx) async {
      var dashboard = await tx.dashboard.requireRead();

      IList<GroupDto> groups;
      if (oldUid != null) {
        final group = dashboard.groups.firstWhere((e) => e.uid == oldUid);
        groups = dashboard.groups.replaceFirst(
          from: group,
          to: group.copyWith(uid: uid),
        );
      } else {
        final group = GroupDto(uid: uid, itemUid: null, items: const IList.empty());
        groups = dashboard.groups.add(group);
      }

      dashboard = dashboard.copyWith(groupUid: uid, groups: groups);
      await tx.dashboard.write(dashboard);
    });
  }

  static Future<void> selectGroup(String? uid) async {
    await Instances.bin.runTransaction((tx) async {
      final dashboard = await tx.dashboard.requireRead();
      await tx.dashboard.write(dashboard.copyWith(groupUid: uid));
    });
  }

  static Future<void> selectItem(String uid) async {
    await Instances.bin.runTransaction((tx) async {
      var dashboard = await tx.dashboard.requireRead();

      dashboard = dashboard.copyWith(
        groups: dashboard.groups.replaceFirst(
          from: dashboard.group,
          to: dashboard.group.copyWith(itemUid: uid),
        ),
      );
      await tx.dashboard.write(dashboard);
    });
  }

  static Future<void> moveGroup(
    String targetUid,
    String destinationUid, {
    required bool after,
  }) async {
    await Instances.bin.runTransaction((tx) async {
      var dashboard = await tx.dashboard.requireRead();
      final targetGroup = dashboard.groups.firstWhere((e) => e.uid == targetUid);
      final destinationGroup = dashboard.groups.firstWhere((e) => e.uid == destinationUid);

      dashboard = dashboard.copyWith(
        groups: dashboard.groups.move(targetGroup, destinationGroup, after: after),
      );
      await tx.dashboard.write(dashboard);
    });
  }

  static Future<void> moveItem(
    String targetUid,
    String destinationUid, {
    required bool after,
  }) async {
    await Instances.bin.runTransaction((tx) async {
      var dashboard = await tx.dashboard.requireRead();

      dashboard = dashboard.copyWith(
        groups: dashboard.groups.replaceFirst(
          from: dashboard.group,
          to: dashboard.group.copyWith(
            items: dashboard.group.items.move(targetUid, destinationUid, after: after),
          ),
        ),
      );
      await tx.dashboard.write(dashboard);
    });
  }

  static Future<void> deleteGroup(String uid) async {
    await Instances.bin.runTransaction((tx) async {
      var dashboard = await tx.dashboard.requireRead();

      dashboard = dashboard.copyWith(
        groupUid: dashboard.groupUid == uid
            ? _findHereditary(dashboard.groups, (e) => e.uid == uid)?.uid
            : dashboard.groupUid,
        groups: dashboard.groups.removeWhere((e) => e.uid == uid).toIList(),
      );
      await tx.dashboard.write(dashboard);
    });
  }

  static Future<void> deleteItem(String uid) async {
    await Instances.bin.runTransaction((tx) async {
      var dashboard = await tx.dashboard.requireRead();

      dashboard = dashboard.copyWith(
        groups: dashboard.groups.replaceFirst(
          from: dashboard.group,
          to: dashboard.group.copyWith(
            itemUid: dashboard.group.itemUid == uid
                ? _findHereditary(dashboard.group.items, (e) => e == uid)
                : dashboard.group.itemUid,
            items: dashboard.group.items.remove(uid),
          ),
        ),
      );
      await tx.dashboard.write(dashboard);
    });
  }

  static T? _findHereditary<T>(IList<T> elements, bool Function(T element) test) {
    final index = elements.indexWhere(test);
    if (index == -1) return null;

    if (index + 1 case final nextIndex when nextIndex <= elements.length) {
      return elements[nextIndex];
    }
    if (index - 1 case final previousIndex when previousIndex >= 0) {
      return elements[previousIndex];
    }
    return null;
  }
}

extension DashboardBin on BinSession {
  BinStore<DashboardConfigDto> get dashboard => BinStore(
    session: this,
    name: Instances.resolveBinName('last_repositories_v8'),
    deserializer: (data) => DashboardConfigDto.fromJson(data as Map<String, dynamic>),
    serializer: (data) => data,
    fallbackData: const DashboardConfigDto(
      groupUid: null,
      groups: IListConst([GroupDto(uid: null, itemUid: null, items: IList.empty())]),
    ),
  );
}
