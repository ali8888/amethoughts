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
import 'package:fluttertoast/fluttertoast.dart';

class ThoughtTileMobile extends StatefulWidget {
  const ThoughtTileMobile({
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
  State<ThoughtTileMobile> createState() => _ThoughtTileMobileState();
}

class _ThoughtTileMobileState extends State<ThoughtTileMobile> {
  late TextEditingController _controller;
  final FocusNode _moreButtonFocusNode = FocusNode();
  AnimationStatus _animationStatus = .dismissed;
  DismissDirection currentDir = DismissDirection.endToStart;

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
        if (widget.persistent) {
          GlobalData.savePersistentThoughts(
            context.read<PersistentThoughts>().toList(),
          );
        }
      });
    }
  }

  void copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
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
      await GlobalData.savePersistentThoughts(
        context.read<PersistentThoughts>().toList(),
      );
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
    return Column(
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
        MenuAnchor(
          onAnimationStatusChanged: (value) => _animationStatus = value,
          menuChildren: [
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
                Fluttertoast.showToast(
                      msg: "Copied to Clipboard",
                      toastLength: Toast.LENGTH_SHORT,
                      gravity: ToastGravity.CENTER,
                      timeInSecForIosWeb: 1,
                      webPosition: "center",
                      webBgColor: "#000000",
                      fontSize: 16.0
                );
              },
              leadingIcon: Icon(Icons.copy),
              child: Text('Copy'),
            ),
            MenuItemButton(
              onPressed: () {
                startEdit(
                  context.read<IsBeingEdited>(),
                  widget.persistent
                      ? context.read<PersistentThoughts>()
                      : context.read<Thoughts>(),
                );
              },
              leadingIcon: Icon(Icons.edit),
              child: Text('Edit'),
            ),
            if (!widget.persistent)
              MenuItemButton(
                onPressed: () {
                  addToLibrary(context);
                },
                leadingIcon: Icon(Icons.archive),
                child: Text('Add to Library'),
              ),
            MenuItemButton(
              onPressed: () {
                widget.remove(widget.uuid);
              },
              leadingIcon: Icon(Icons.delete),
              child: Text('Delete'),
            ),
          ],
          builder:
              (
                BuildContext context,
                MenuController menuController,
                Widget? child,
              ) {
                return Dismissible(
                  background: Container(
                    alignment: currentDir==DismissDirection.endToStart ? Alignment.centerRight : Alignment.centerLeft,
                    padding: EdgeInsets.only(left: 20, right: 20),
                    decoration: BoxDecoration(
                      color: currentDir==DismissDirection.endToStart ? Colors.red : Colors.green,
                      borderRadius: BorderRadius.circular(16.0)
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if(currentDir==DismissDirection.endToStart)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16.0,0,16,0),
                          child: Text("Delete", style: TextStyle(color: Colors.white)),
                        ),
                        if(currentDir==DismissDirection.endToStart)
                        Icon(Icons.delete, color: Colors.white),
                        if(currentDir!=DismissDirection.endToStart)
                        Icon( Icons.archive, color: Colors.white),
                        if(currentDir!=DismissDirection.endToStart)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16.0,0,16,0),
                          child: Text("Library", style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                  direction: isEditing
                      ? DismissDirection.none
                      : (widget.persistent ? DismissDirection.endToStart : DismissDirection.horizontal),
                  key: Key(widget.uuid),
                  onUpdate:(details) { 
                    context.read<IsBeingEdited>().clear();
                    setState(() {
                      currentDir = details.direction;
                    });
                    
                  },
                  onDismissed: (direction) {
                    switch (direction) {
                      case DismissDirection.endToStart:
                        // DELETE
                        widget.remove(widget.uuid);
                        break;
                      case DismissDirection.startToEnd:
                        // ADD TO LIBRARY
                        addToLibrary(context);
                        break;

                      default:
                        break;
                    }
                  },
                  child: Material(
                    color: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: isEditing ? null : () {
                        context.read<IsBeingEdited>().clear();
                        if (_animationStatus.isForwardOrCompleted) {
                          menuController.close();
                        } else {
                          menuController.open();
                        }
                      },
                      onLongPress: isEditing ? null : () { 
                        menuController.close();
                        startEdit(
                        context.read<IsBeingEdited>(),
                        widget.persistent
                            ? context.read<PersistentThoughts>()
                            : context.read<Thoughts>());
                      },
                      child: ListTile(
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
                      ),
                    ),
                  ),
                );
              },
        ),
      ],
    );
  }
}
