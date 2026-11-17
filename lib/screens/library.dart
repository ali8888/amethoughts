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
import 'package:amethoughts/widgets/thought_tile/thought_tile_desktop.dart';
import 'package:amethoughts/widgets/thought_tile/thought_tile_mobile.dart';
import 'package:bloc_signals_flutter/bloc_signals_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  late TextEditingController _searchController;
  bool sortingByNewest = true;


  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    List<Thought> filteredList = context.watch<PersistentThoughts>().filtered(_searchController.text).toList();
    return Align(
      alignment: Alignment.topCenter,
      child: SizedBox(
        width: MediaQuery.of(context).size.width * (GlobalData.isDesktop ? 0.75 : 0.95),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: GlobalData.isDesktop ? 25 : 40,),
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
                          suffixIcon: _searchController.text.isEmpty ? null : IconButton(
                            tooltip: 'Clear',
                            icon: Icon(Icons.clear),
                            onPressed: () => setState(() { context.read<IsBeingEdited>().clear(); _searchController.clear();}),
                          ),
                          hintText: 'Search',
                          hintStyle: TextStyle(overflow: TextOverflow.fade),
                          contentPadding: EdgeInsets.symmetric(vertical: kIsWeb ? 18 : 10),
                          filled: true,
                        ),
                      ),
                ),
                    SizedBox(width:5),
                    Tooltip(
                      message: sortingByNewest ? "Sort from Oldest to Newest" : "Sort from Newest to Oldest",
                      child: IconButton(
                        icon: Icon(sortingByNewest ? Icons.keyboard_double_arrow_down : Icons.keyboard_double_arrow_up ),
                        onPressed: () {
                          setState(() {
                            context.read<IsBeingEdited>().clear();
                            sortingByNewest = !sortingByNewest;
                          });
                        },
                      ),
                    )
              ],
            ),
            SizedBox(height: 25,),
            Expanded(
              child: filteredList.isEmpty
                  ? Align(
                      alignment: Alignment.center,
                      child: context.read<PersistentThoughts>().toList().isEmpty
                          ? Text("This is where you can store thoughts forever even after closing the app.\nTry adding one from the home tab!", textAlign: TextAlign.center)
                          : Text(
                              "None of your persistent thoughts match your search query.\nTry tweaking or clearing your query.",
                              textAlign: TextAlign.center,
                            ),
                    )
                  : ListView.builder(
                itemCount: filteredList.length,
                itemBuilder: (context, index) {
                  int computedIndex = sortingByNewest ? index : filteredList.length-index-1;
                  int computedPreviousIndex = sortingByNewest ? computedIndex-1 : computedIndex+1;
                  if(GlobalData.isDesktop) {
                    return ThoughtTileDesktop(
                      uuid: filteredList[computedIndex].uuid,
                      showDate: index==0 || !filteredList[computedIndex].sameDay(filteredList[computedPreviousIndex]),
                      persistent: true,
                      updateList: () {
                        if (!mounted) return;
                        setState(() {});
                      },
                      remove: (uuid) {
                        if (!mounted) return;
                        setState(() {
                          context.read<PersistentThoughts>().removeWhere((element) => uuid == element.uuid);
                          GlobalData.removePersistentThought(uuid);
                        });
                      },
                    );
                  } else {
                    return ThoughtTileMobile(
                      uuid: filteredList[computedIndex].uuid,
                      showDate: index==0 || !filteredList[computedIndex].sameDay(filteredList[computedPreviousIndex]),
                      persistent: true,
                      updateList: () {
                        if (!mounted) return;
                        setState(() {});
                      },
                      remove: (uuid) {
                        if (!mounted) return;
                        setState(() {
                          context.read<PersistentThoughts>().removeWhere((element) => uuid == element.uuid);
                          GlobalData.removePersistentThought(uuid);
                        });
                      },
                    );
                  }
                  
                },
              ),
            ),
            SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
