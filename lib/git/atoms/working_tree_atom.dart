import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gitle/git/dto/git_dto.dart';
import 'package:gitle/git/models/repository_model.dart';
import 'package:path/path.dart' as path_;

class WorkingTreeAtom extends StatefulWidget {
  final RepositoryModel repository;

  const WorkingTreeAtom({
    super.key,
    required this.repository,
  });

  static Color? resolveFileColor(List<FileStatus> status) {
    if (status.contains(FileStatus.deleted)) {
      return Colors.grey;
    } else if (status.contains(FileStatus.added)) {
      return Colors.green;
    } else if (status.contains(FileStatus.modified)) {
      return Colors.blue;
    } else if (status.contains(FileStatus.untracked)) {
      return Colors.red;
    } else {
      return null;
    }
  }

  Set<FileDto> get _elements => repository.workingTree.toSet();

  @override
  State<WorkingTreeAtom> createState() => WorkingTreeAtomState();
}

class WorkingTreeAtomState extends State<WorkingTreeAtom> {
  var _originalSelection = <FileDto>{};
  var _isPendingSelection = false;
  var _pendingOperation = true;
  var _pendingSelection = <FileDto>{};
  FileDto? _lastSelected;

  Set<FileDto> get _selection => _pendingOperation
      ? ({..._originalSelection}..addAll(_pendingSelection))
      : ({..._originalSelection}..removeAll(_pendingSelection));

  final _focusNode = FocusNode();

  Set<FileDto> get selection => _selection;

  @override
  void didUpdateWidget(covariant WorkingTreeAtom oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldElements = oldWidget._elements.whereNot(widget._elements.contains);
    _originalSelection = {..._originalSelection}..removeAll(oldElements);
    _pendingSelection = {..._pendingSelection}..removeAll(oldElements);
  }

  void _toggle(bool isSelected, FileDto file) {
    if (_isPendingSelection && _lastSelected != null) {
      final pendingSelection = _resolve(widget._elements, [_lastSelected!, file]);
      setState(() {
        _pendingSelection = pendingSelection.toSet();
      });
      return;
    }

    final selection = {..._selection};
    if (isSelected) {
      selection.remove(file);
    } else {
      selection.add(file);
    }
    setState(() {
      _originalSelection = selection;
      _pendingOperation = !isSelected;
      _lastSelected = file;
    });
  }

  Iterable<T> _resolve<T>(Iterable<T> values, Iterable<T> keywords) sync* {
    final x = keywords.toList();
    var picking = false;

    for (final value in values) {
      var wasPicking = picking;
      do {
        wasPicking = picking;
        picking = x.remove(value) ? !picking : picking;
        if (picking || wasPicking) yield value;
      } while (picking != wasPicking);
    }
  }

  void _selectAll() => setState(() => _originalSelection = widget._elements);

  void _deselectAll() => setState(() => _originalSelection = {});

  @override
  Widget build(BuildContext context) {
    final selection = _selection;

    final isAllSelected = widget.repository.workingTree.every(selection.contains);
    Widget child = CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: CheckboxListTile(
            value: isAllSelected,
            onChanged: (isAllSelected) => isAllSelected! ? _selectAll() : _deselectAll(),
            title: isAllSelected ? const Text('Deselect All') : const Text('Select All'),
          ),
        ),
        SliverList.list(
          children: widget.repository.workingTree.map((file) {
            return CheckboxListTile(
              controlAffinity: ListTileControlAffinity.leading,
              value: selection.contains(file),
              tileColor: WorkingTreeAtom.resolveFileColor(file.status)?.withValues(alpha: 0.2),
              selectedTileColor: Colors.white.withValues(alpha: 0.2),
              onChanged: (isSelected) => _toggle(!isSelected!, file),
              title: Text(path_.basename(file.paths.last)),
              subtitle: Text(file.paths.join(' -> ')),
            );
          }).toList(),
        ),
      ],
    );

    child = KeyboardListener(
      autofocus: true,
      focusNode: _focusNode,
      onKeyEvent: (event) {
        if (event is KeyDownEvent) {
          _isPendingSelection = true;
        } else if (event is KeyUpEvent) {
          _isPendingSelection = false;
          _originalSelection = _selection;
          _pendingSelection = {};
        }
      },
      child: child,
    );
    child = FocusableActionDetector(
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.keyA, meta: true): SelectAllIntent(),
      },
      actions: {
        SelectAllIntent: CallbackAction<SelectAllIntent>(onInvoke: (_) => _selectAll()),
      },
      child: child,
    );
    child = SelectionArea(child: child);

    return child;
  }
}

class SelectAllIntent extends Intent {
  const SelectAllIntent();
}
