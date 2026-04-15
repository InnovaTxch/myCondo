import 'package:flutter/material.dart';
import 'package:mycondo/data/models/resident.dart';
import 'package:mycondo/data/models/unit.dart';

import 'unit_expansion_tile.dart';

class BillRecipientContainer extends StatefulWidget {
  final List<Resident> selectedResidents;
  final List<Unit> allUnits;

  const BillRecipientContainer({
    super.key,
    required this.selectedResidents,
    required this.allUnits,
  });

  @override
  State<BillRecipientContainer> createState() => _BillRecipientContainerState();
}


class _BillRecipientContainerState extends State<BillRecipientContainer> {
  List<Resident> get _selectedResidents => widget.selectedResidents;
  List<Unit> get _allUnits => widget.allUnits;

  void _addResident(Resident r) {
    if (!_selectedResidents.any((element) => element.id == r.id)) {
      setState(() => _selectedResidents.add(r));
    }
  }

  void _addUnit(Unit u) {
    for (var member in u.members) {
      _addResident(member);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 120),
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey.shade50,
      ),
      child: Stack(
        children: [
          if (_selectedResidents.isEmpty)
            const Center(child: Text("No residents selected", style: TextStyle(color: Colors.grey))),
          
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: _selectedResidents.map((r) => Chip(
              label: Text("${r.name} (${r.unitName})"),
              onDeleted: () => setState(() => _selectedResidents.remove(r)),
              deleteIconColor: Colors.redAccent,
              backgroundColor: Colors.blue.shade50,
            )).toList(),
          ),
          
          // Floating Plus Button inside container (Bottom Right)
          Positioned(
            bottom: 0,
            right: 0,
            child: FloatingActionButton.small(
              onPressed: () => _showSearchModal(context),
              child: const Icon(Icons.add),
            ),
          )
        ],
      ),
    );
  }

  void _showSearchModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: TextField(
                    decoration: InputDecoration(prefixIcon: Icon(Icons.search), 
                    hintText: "Search Unit or Resident", 
                    border: OutlineInputBorder())),
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
                        addResident: _addResident
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