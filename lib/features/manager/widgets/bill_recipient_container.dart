import 'package:flutter/material.dart';
import 'package:mycondo/data/models/resident.dart';
import 'package:mycondo/data/models/unit.dart';

import 'unit_expansion_tile.dart';

class BillRecipientContainer extends StatefulWidget {
  const BillRecipientContainer({
    super.key,
    required this.selectedResidents,
    required this.allUnits,
    required this.onSelectionChanged,
  });

  final List<Resident> selectedResidents;
  final List<Unit> allUnits;
  final VoidCallback onSelectionChanged;

  @override
  State<BillRecipientContainer> createState() => _BillRecipientContainerState();
}

class _BillRecipientContainerState extends State<BillRecipientContainer> {
  List<Resident> get _selectedResidents => widget.selectedResidents;
  List<Unit> get _allUnits => widget.allUnits;

  void _addResident(Resident resident) {
    if (_selectedResidents.any((element) => element.id == resident.id)) return;

    setState(() => _selectedResidents.add(resident));
    widget.onSelectionChanged();
  }

  void _removeResident(Resident resident) {
    setState(() => _selectedResidents.remove(resident));
    widget.onSelectionChanged();
  }

  void _addUnit(Unit unit) {
    var changed = false;
    for (final member in unit.members) {
      if (_selectedResidents.any((element) => element.id == member.id)) {
        continue;
      }
      _selectedResidents.add(member);
      changed = true;
    }

    if (!changed) return;
    setState(() {});
    widget.onSelectionChanged();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 132),
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE6E2DD)),
        borderRadius: BorderRadius.circular(16),
        color: const Color(0xFFF7F5F2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _selectedResidents.isEmpty
                ? "No residents selected"
                : "${_selectedResidents.length} selected",
            style: const TextStyle(
              color: Colors.black54,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          if (_selectedResidents.isEmpty)
            const SizedBox(
              height: 58,
              child: Text(
                "Selected residents will appear here.",
                style: TextStyle(color: Colors.black45),
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: _selectedResidents
                  .map(
                    (resident) => Chip(
                      label: Text("${resident.name} (${resident.unitName})"),
                      onDeleted: () => _removeResident(resident),
                      deleteIconColor: const Color(0xFFBF2F2F),
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFFE6E2DD)),
                    ),
                  )
                  .toList(),
            ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: SizedBox(
              width: 44,
              height: 44,
              child: FilledButton(
                onPressed: () => _showSearchModal(context),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF1A1A1A),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Icon(Icons.add),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSearchModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.72,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                Container(
                  width: 42,
                  height: 4,
                  margin: const EdgeInsets.only(top: 10, bottom: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0E0E0),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
                  child: TextField(
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      hintText: "Search unit or resident",
                      filled: true,
                      fillColor: const Color(0xFFF7F5F2),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: _allUnits.length,
                    itemBuilder: (context, index) {
                      final unit = _allUnits[index];
                      return UnitExpansionTile(
                        context: context,
                        unit: unit,
                        addUnit: _addUnit,
                        addResident: _addResident,
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
