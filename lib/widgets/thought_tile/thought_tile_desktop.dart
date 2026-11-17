/*
    Amethoughts
    Copyright (C) 2026 Lymesque

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU Affero General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Affero General Public License for more details.

    You should have received a copy of the GNU Affero General Public License
    along with this program.  If not, see <https://www.gnu.org/licenses/>.
*/

import 'package:amethoughts/entity/thought.dart';
import 'package:amethoughts/global.dart';
import 'package:bloc_signals_flutter/bloc_signals_flutter.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

class ThoughtTileDesktop extends StatefulWidget {
  const ThoughtTileDesktop({
    super.key,
    required this.uuid,
    required this.updateList,
    required this.remove,
    this.persistent = false,
    this.showDate = false,
  });
  final String uuid;
  final void Function() updateList;
  final void Function(String) remove;
  final bool persistent;
  final bool showDate;

  @override
  State<ThoughtTileDesktop> createState() => _ThoughtTileDesktopState();
}

class _ThoughtTileDesktopState extends State<ThoughtTileDesktop> {
  bool _isHovered = false;
  bool _copiedFeedback = false;
  late TextEditingController _controller;
  final FocusNode _moreButtonFocusNode = FocusNode();

  void startEdit(IsBeingEdited semaphore, ThoughtList thoughts) {
    semaphore.start(widget.uuid);
    setState(() {
      _controller.text = thoughts.findByUuid(widget.uuid).thought;
    });
  }

  void finishEdit(IsBeingEdited semaphore, String text, ThoughtList thoughts) {
    if (text != "") {
      setState(() {
        Thought oldThought = thoughts.findByUuid(widget.uuid);
        thoughts.edit(Thought.edit(oldThought, _controller.text));
        semaphore.clear();
        widget.updateList();
        if(widget.persistent) {
          GlobalData.savePersistentThoughts(context.read<PersistentThoughts>().toList());
        }
      });
    }
  }

  void copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    setState(() {
      _copiedFeedback = true;
    });
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() {
        _copiedFeedback = false;
      });
    });
  }

  void addToLibrary(BuildContext context) async {
    if (context.read<PersistentThoughts>().toList().length >= 99999) {
      const snackBar = SnackBar(
        content: Text(
          'Error : You have too many persistent thoughts! Remove some before trying to add new ones.',
        ),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    } else {
      context.read<PersistentThoughts>().insert(
        context.read<Thoughts>().findByUuid(widget.uuid),
      );
      widget.remove(widget.uuid);
      await GlobalData.savePersistentThoughts(context.read<PersistentThoughts>().toList());
    }
  }

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    _moreButtonFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = context.select<IsBeingEdited, bool>(
      (signal) => signal.value == widget.uuid,
    );
    return MouseRegion(
      onEnter: (_) {
        if (!mounted) return;
        setState(() {
          _isHovered = true;
        });
      },
      onExit: (_) {
        if (!mounted) return;
        setState(() {
          _isHovered = false;
        });
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.persistent)
            if (widget.showDate)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Opacity(
                      opacity: 0.5,
                      child: Text(
                        context
                            .read<PersistentThoughts>()
                            .findByUuid(widget.uuid)
                            .formattedDate(),
                      ),
                    ),
                  ),
                  Expanded(child: Divider()),
                ],
              ),
          ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            title: isEditing
                ? SizedBox(
                    height: 37.0,
                    child: TextField(
                      controller: _controller,
                      onSubmitted: (text) => finishEdit(
                        context.read<IsBeingEdited>(),
                        text,
                        widget.persistent
                            ? context.read<PersistentThoughts>()
                            : context.read<Thoughts>(),
                      ),
                      decoration: InputDecoration(
                        contentPadding: EdgeInsets.symmetric(
                          vertical: 3.0,
                          horizontal: 8.0,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(Icons.check),
                          onPressed: () => finishEdit(
                            context.read<IsBeingEdited>(),
                            _controller.text,
                            widget.persistent
                                ? context.read<PersistentThoughts>()
                                : context.read<Thoughts>(),
                          ),
                        ),
                      ),
                    ),
                  )
                : Text(
                    widget.persistent
                        ? context
                              .watch<PersistentThoughts>()
                              .findByUuid(widget.uuid)
                              .thought
                        : context
                              .watch<Thoughts>()
                              .findByUuid(widget.uuid)
                              .thought,
                  ),
            tileColor: Color.fromARGB(
              _isHovered || isEditing ? 20 : 0,
              255,
              255,
              255,
            ),
            trailing: isEditing
                ? null
                : AnimatedOpacity(
                    opacity: _isHovered ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOut,
                    child: MediaQuery.of(context).size.width < 600
                        ? MenuAnchor(
                            childFocusNode: _moreButtonFocusNode,
                            menuChildren: <Widget>[
                              MenuItemButton(
                                onPressed: () => startEdit(
                                  context.read<IsBeingEdited>(),
                                  widget.persistent
                                      ? context.read<PersistentThoughts>()
                                      : context.read<Thoughts>(),
                                ),
                                child: const Text('Edit'),
                              ),
                              MenuItemButton(
                                onPressed: () {
                                  copyToClipboard(
                                    widget.persistent
                                        ? context
                                              .read<PersistentThoughts>()
                                              .findByUuid(widget.uuid)
                                              .thought
                                        : context
                                              .read<Thoughts>()
                                              .findByUuid(widget.uuid)
                                              .thought,
                                  );
                                  const snackBar = SnackBar(
                                    content: Text('Copied to clipboard.'),
                                  );
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(snackBar);
                                },
                                child: const Text('Copy'),
                              ),
                              if (!widget.persistent)
                                MenuItemButton(
                                  onPressed: () => addToLibrary(context),
                                  child: const Text('Add to Library'),
                                ),
                              MenuItemButton(
                                onPressed: () => widget.remove(widget.uuid),
                                child: const Text('Delete'),
                              ),
                            ],
                            builder:
                                (_, MenuController controller, Widget? child) {
                                  return IconButton(
                                    focusNode: _moreButtonFocusNode,
                                    onPressed: () {
                                      if (controller.isOpen) {
                                        controller.close();
                                      } else {
                                        controller.open();
                                      }
                                    },
                                    icon: const Icon(Icons.more_vert),
                                  );
                                },
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                tooltip: 'Edit',
                                onPressed: () => startEdit(
                                  context.read<IsBeingEdited>(),
                                  widget.persistent
                                      ? context.read<PersistentThoughts>()
                                      : context.read<Thoughts>(),
                                ),
                              ),
                              SizedBox(width: 5),
                              IconButton(
                                icon: _copiedFeedback
                                    ? const Icon(Icons.check)
                                    : const Icon(Icons.copy_rounded),
                                tooltip: _copiedFeedback
                                    ? 'Copied to Clipboard!'
                                    : 'Copy',
                                onPressed: _copiedFeedback
                                    ? null
                                    : () => copyToClipboard(
                                        widget.persistent
                                            ? context
                                                  .read<PersistentThoughts>()
                                                  .findByUuid(widget.uuid)
                                                  .thought
                                            : context
                                                  .read<Thoughts>()
                                                  .findByUuid(widget.uuid)
                                                  .thought,
                                      ),
                              ),
                              if (!widget.persistent) SizedBox(width: 5),
                              if (!widget.persistent)
                                IconButton(
                                  icon: const Icon(Icons.archive),
                                  tooltip: 'Add to Library',
                                  onPressed: () => addToLibrary(context),
                                ),
                              SizedBox(width: 5),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                tooltip: 'Delete',
                                onPressed: () {
                                  widget.remove(widget.uuid);
                                },
                              ),
                            ],
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}
