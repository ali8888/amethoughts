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
import 'package:amethoughts/widgets/erase_dialog.dart';
import 'package:amethoughts/widgets/thought_tile/thought_tile_desktop.dart';
import 'package:amethoughts/widgets/thought_tile/thought_tile_mobile.dart';
import 'package:bloc_signals_flutter/bloc_signals_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

import '../global.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  FocusNode focusNode = FocusNode();
  late TextEditingController _mainController;
  late TextEditingController _searchController;
  AnimationStatus _animationStatus = .dismissed;
  String filterKeyword = "";
  bool sortingByNewest = true;

  @override
  void initState() {
    super.initState();
    _mainController = TextEditingController();
    _searchController = TextEditingController();
    if (GlobalData.initError) {
      GlobalData.initError = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Error : Some settings have not been loaded correctly.",
            ),
            duration: Duration(seconds: 3),
          ),
        );
      });
    }
  }

  @override
  void dispose() {
    focusNode.dispose();
    _mainController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void addThought(Thoughts thoughts) {
    if (_mainController.text != "") {
      setState(() {
        thoughts.insert(Thought(_mainController.text));
        _mainController.clear();
        focusNode.requestFocus();
        if (thoughts.toList().length > 10000) {
          thoughts.removeLast();
        }
      });
    }
  }

  void eraseAllThoughts(BuildContext context, Function setState) {
    setState(() {
      if (GlobalData.dontShowAgain!) {
        setState(() {
          context.read<Thoughts>().clear();
        });
      } else {
        showEraseDialog(
          context,
          () => setState(() => context.read<Thoughts>().clear()),
        );
      }
    });
  }

  void addAllToLibrary(BuildContext context, Function setState) {
    setState(() {
      context.read<PersistentThoughts>().recreate(
        context.read<Thoughts>().toList() +
            context.read<PersistentThoughts>().toList(),
      );
      context.read<Thoughts>().clear();
      GlobalData.savePersistentThoughts(
        context.read<PersistentThoughts>().toList(),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Thought> filteredList = context
        .watch<Thoughts>()
        .filtered(_searchController.text)
        .toList();

    final thoughts = context.read<Thoughts>();
    final library = context.read<PersistentThoughts>();

    SaveQueue().beforeClose = thoughts.toList().isEmpty ? null : () async {
      final activeSnapshot = List<Thought>.of(thoughts.toList());
      if (activeSnapshot.isEmpty) return true;

      final merged = [...activeSnapshot, ...library.toList()];

      await GlobalData.savePersistentThoughts(merged, persistOnClose: true);
      library.recreate(merged);
      thoughts.clear();
      return true;
      
    };
    
    return Align(
      alignment: AlignmentGeometry.topCenter,
      child: SizedBox(
        width: MediaQuery.of(context).size.width * (GlobalData.isDesktop ? 0.75 : 0.95),
        child: Column(
          children: [
            SizedBox(height: 40),
            // Main Input Box (Desktop only)
            if (GlobalData.isDesktop)
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _mainController,
                        focusNode: focusNode,
                        maxLength: 200,
                        onSubmitted: (value) {
                          context.read<IsBeingEdited>().clear();
                          addThought(context.read<Thoughts>());
                        },
                        onChanged: (value) => setState(
                          () => context.read<IsBeingEdited>().clear(),
                        ),
                        autofocus: true,
                        decoration: InputDecoration(
                          suffixIcon: _mainController.text.isEmpty
                              ? null
                              : IconButton(
                                  tooltip: 'Clear',
                                  icon: Icon(Icons.clear),
                                  onPressed: () =>
                                      setState(() => _mainController.clear()),
                                ),
                          hintText: GlobalData.placeholder,
                          hintStyle: TextStyle(overflow: TextOverflow.fade),
                          filled: false,
                        ),
                      ),
                    ),
                    SizedBox(width: 20),
                    SizedBox(
                      width: 70,
                      height: 70,
                      child: Tooltip(
                        message: "Add a thought!",
                        child: FilledButton(
                          onPressed: _mainController.text.isEmpty
                              ? null
                              : () {
                                  context.read<IsBeingEdited>().clear();
                                  addThought(context.read<Thoughts>());
                                },
                          child: Icon(Icons.add),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (GlobalData.isDesktop) SizedBox(height: 20),
            // Search Input Box
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {
                        context.read<IsBeingEdited>().clear();
                      });
                    },
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      suffixIcon: _searchController.text.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Clear',
                              icon: Icon(Icons.clear),
                              onPressed: () => setState(() {
                                context.read<IsBeingEdited>().clear();
                                _searchController.clear();
                              }),
                            ),
                      hintText: "Search",
                      hintStyle: TextStyle(overflow: TextOverflow.fade),
                      contentPadding: EdgeInsets.symmetric(
                        vertical: kIsWeb ? 18 : 10,
                      ),
                      filled: true,
                    ),
                  ),
                ),
                SizedBox(width: 5),
                Tooltip(
                  message: sortingByNewest
                      ? "Sort from Oldest to Newest"
                      : "Sort from Newest to Oldest",
                  child: IconButton(
                    icon: Icon(
                      sortingByNewest
                          ? Icons.keyboard_double_arrow_down
                          : Icons.keyboard_double_arrow_up,
                    ),
                    onPressed: () {
                      setState(() {
                        context.read<IsBeingEdited>().clear();
                        sortingByNewest = !sortingByNewest;
                      });
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            // List of Thoughts
            Expanded(
              child: filteredList.isEmpty
                  ? Align(
                      alignment: Alignment.center,
                      child: context.watch<Thoughts>().toList().isEmpty
                          ? Text("Your thoughts will show up here!")
                          : Text(
                              "None of your thoughts match your search query.\nTry tweaking or clearing your query.",
                              textAlign: TextAlign.center,
                            ),
                    )
                  : ListView.builder(
                      itemCount: filteredList.length,
                      itemBuilder: (context, index) {
                        if(GlobalData.isDesktop) {
                          return ThoughtTileDesktop(
                            uuid: sortingByNewest
                                ? filteredList[index].uuid
                                : filteredList[filteredList.length - index - 1]
                                      .uuid,
                            updateList: () {
                              if (!mounted) return;
                              setState(() {});
                            },
                            remove: (uuid) {
                              if (!mounted) return;
                              setState(() {
                                context.read<Thoughts>().removeWhere(
                                  (element) => uuid == element.uuid,
                                );
                              });
                            },
                          );
                        } else {
                          return ThoughtTileMobile(
                            uuid: sortingByNewest
                                ? filteredList[index].uuid
                                : filteredList[filteredList.length - index - 1]
                                      .uuid,
                            updateList: () {
                              if (!mounted) return;
                              setState(() {});
                            },
                            remove: (uuid) {
                              if (!mounted) return;
                              setState(() {
                                context.read<Thoughts>().removeWhere(
                                  (element) => uuid == element.uuid,
                                );
                              });
                            },
                          );
                        }
                        
                      },
                    ),
            ),
            // Bottom control buttons
            if (GlobalData.isDesktop)
              Align(
                alignment: AlignmentGeometry.bottomCenter,
                child: context.read<Thoughts>().toList().isEmpty
                    ? null
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ElevatedButton(
                            onPressed: () => addAllToLibrary(context, setState),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.archive_outlined),
                                SizedBox(width: 5),
                                Text("Add all to library"),
                              ],
                            ),
                          ),
                          SizedBox(width: 5),
                          ElevatedButton(
                            onPressed: () => eraseAllThoughts(context, setState),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.delete_outline),
                                SizedBox(width: 5),
                                Text("Erase all"),
                              ],
                            ),
                          ),
                        ],
                      ),
              ),
            if (!GlobalData.isDesktop)
              // Mobile Input Box
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _mainController,
                        focusNode: focusNode,
                        maxLength: 200,
                        onSubmitted: (value) {
                          context.read<IsBeingEdited>().clear();
                          addThought(context.read<Thoughts>());
                        },
                        onChanged: (value) => setState(
                          () => context.read<IsBeingEdited>().clear(),
                        ),
                        autofocus: true,
                        decoration: InputDecoration(
                          suffixIcon: _mainController.text.isEmpty
                              ? null
                              : IconButton(
                                  icon: Icon(Icons.clear),
                                  onPressed: () =>
                                      setState(() => _mainController.clear()),
                                ),
                          hintText: GlobalData.placeholder,
                          hintStyle: TextStyle(overflow: TextOverflow.fade),
                          filled: false,
                        ),
                      ),
                    ),
                    SizedBox(width: 5),
                      if (focusNode.hasFocus && _mainController.text.isNotEmpty)
                        IconButton.filled(
                          onPressed: () {
                            context.read<IsBeingEdited>().clear();
                            addThought(context.read<Thoughts>());
                          },
                          icon: Icon(Icons.add),
                        ),
                      if ((!focusNode.hasFocus || _mainController.text.isEmpty) && context.read<Thoughts>().toList().isNotEmpty)
                        MenuAnchor(
                          onAnimationStatusChanged: (value) =>
                              _animationStatus = value,
                          builder:
                              (
                                BuildContext context,
                                MenuController menuController,
                                Widget? child,
                              ) {
                                return IconButton(
                                  onPressed: () {
                                    if (_animationStatus.isForwardOrCompleted) {
                                      menuController.close();
                                    } else {
                                      menuController.open();
                                    }
                                  },
                                  icon: Icon(Icons.more_vert),
                                );
                              },
                          menuChildren: [
                            MenuItemButton(
                              onPressed: () =>
                                  addAllToLibrary(context, setState),
                              leadingIcon: Icon(Icons.archive_outlined),
                              child: Text('Add to Library'),
                            ),
                            MenuItemButton(
                              onPressed: () => eraseAllThoughts(context, setState),
                              leadingIcon: Icon(Icons.delete_outline),
                              child: Text('Erase all'),
                            ),
                          ],
                        ),
                  ],
                ),
              ),
            SizedBox(height: GlobalData.isDesktop ? 30 : 10),
          ],
        ),
      ),
    );
  }
}
