import 'package:collection/collection.dart';
import 'package:flutter/services.dart';

enum BranchType {
  feature,
  fix,
  chore,
  release,
  tmp;

  static (BranchType?, String) from(String branchName) {
    final type = values.firstWhereOrNull((e) => branchName.startsWith('${e.name}/'));
    if (type == null) return (null, branchName);
    return (type, branchName.replaceFirst('${type.name}/', ''));
  }
}

extension BranchTypeExtenions on BranchType? {
  String toName(String name) {
    final prefixName = this?.name;
    return prefixName != null ? '$prefixName/$name' : name;
  }
}

abstract final class BranchUtils {
  static final TextInputFormatter textFormatter =
      FilteringTextInputFormatter.deny(' ', replacementString: '_');
}
