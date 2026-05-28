import 'package:flutter/material.dart';
import 'package:mycondo/theme/app_theme.dart';
import 'package:mycondo/data/models/resident.dart';
import 'package:mycondo/data/models/unit.dart';

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

  List<Resident> get _allResidents {
    final residentsById = <String, Resident>{};
    for (final unit in _allUnits) {
      for (final member in unit.members) {
        residentsById.putIfAbsent(
          member.id,
          () => Resident(
            id: member.id,
            name: member.name,
            unitName: member.unitName.isEmpty ? unit.name : member.unitName,
          ),
        );
      }
    }

    final residents = residentsById.values.toList();
    residents.sort((a, b) {
      final byUnit = a.unitName.toLowerCase().compareTo(
        b.unitName.toLowerCase(),
      );
      if (byUnit != 0) return byUnit;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return residents;
  }

  List<String> get _unitFilters {
    final units = _allResidents
        .map((resident) => resident.unitName.trim())
        .where((unitName) => unitName.isNotEmpty)
        .toSet()
        .toList();
    units.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return units;
  }

  bool _isSelected(Resident resident) {
    return _selectedResidents.any((item) => item.id == resident.id);
  }

  void _toggleResident(Resident resident, bool selected) {
    final isAlreadySelected = _isSelected(resident);
    if (selected && !isAlreadySelected) {
      setState(() => _selectedResidents.add(resident));
      widget.onSelectionChanged();
      return;
    }
    if (!selected && isAlreadySelected) {
      setState(
        () => _selectedResidents.removeWhere((item) => item.id == resident.id),
      );
      widget.onSelectionChanged();
    }
  }

  void _addFilteredResidents(List<Resident> residents) {
    var changed = false;
    for (final resident in residents) {
      if (_selectedResidents.any((item) => item.id == resident.id)) {
        continue;
      }
      _selectedResidents.add(resident);
      changed = true;
    }

    if (!changed) return;
    setState(() {});
    widget.onSelectionChanged();
  }

  void _clearFilteredResidents(List<Resident> residents) {
    final filteredIds = residents.map((resident) => resident.id).toSet();
    final nextSelection = _selectedResidents
        .where((resident) => !filteredIds.contains(resident.id))
        .toList();

    if (nextSelection.length == _selectedResidents.length) {
      return;
    }

    setState(() {
      _selectedResidents
        ..clear()
        ..addAll(nextSelection);
    });
    widget.onSelectionChanged();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 150),
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE6E2DD)),
        borderRadius: BorderRadius.circular(14),
        color: AppColors.creamWhite,
      ),
      child: Stack(
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 18, 12, 46),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _selectedResidents.isEmpty
                        ? Icons.group_outlined
                        : Icons.check_circle_outline,
                    color: _selectedResidents.isEmpty
                        ? Colors.black38
                        : AppColors.successGreen,
                    size: 28,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _selectedResidents.isEmpty
                        ? 'No residents selected'
                        : '${_selectedResidents.length} residents selected',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.darkText,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _selectedResidents.isEmpty
                        ? 'Tap + to add recipients'
                        : 'Tap + to edit recipients',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.black54,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: SizedBox(
              width: 46,
              height: 42,
              child: FilledButton(
                onPressed: () => _showSearchModal(context),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.darkText,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  visualDensity: VisualDensity.compact,
                ),
                child: const Icon(Icons.add, size: 24),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSearchModal(BuildContext context) {
    final searchController = TextEditingController();
    var query = '';
    var selectedUnits = <String>{};

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.86,
          minChildSize: 0.58,
          maxChildSize: 0.94,
          expand: false,
          builder: (context, scrollController) {
            return StatefulBuilder(
              builder: (context, modalSetState) {
                final normalizedQuery = query.trim().toLowerCase();
                final filteredResidents = _allResidents.where((resident) {
                  final unitMatches =
                      selectedUnits.isEmpty ||
                      selectedUnits.contains(resident.unitName);
                  final matchesSearch =
                      normalizedQuery.isEmpty ||
                      resident.name.toLowerCase().contains(normalizedQuery) ||
                      resident.unitName.toLowerCase().contains(normalizedQuery);
                  return unitMatches && matchesSearch;
                }).toList();
                final selectedShownCount = filteredResidents
                    .where(_isSelected)
                    .length;
                final allShownSelected =
                    filteredResidents.isNotEmpty &&
                    selectedShownCount == filteredResidents.length;
                final noneShownSelected = selectedShownCount == 0;
                final headerCheckboxValue = allShownSelected
                    ? true
                    : noneShownSelected
                    ? false
                    : null;

                return Column(
                  children: [
                    Container(
                      width: 42,
                      height: 4,
                      margin: const EdgeInsets.only(top: 10, bottom: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0E0E0),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Select Residents',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.darkText,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${_selectedResidents.length} selected',
                                  style: const TextStyle(
                                    color: Colors.black54,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.darkText,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Done'),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
                      child: TextField(
                        controller: searchController,
                        onChanged: (value) {
                          modalSetState(() => query = value);
                        },
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.search),
                          hintText: 'Search by resident name or unit',
                          filled: true,
                          fillColor: AppColors.creamWhite,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
                      child: Row(
                        children: [
                          OutlinedButton.icon(
                            onPressed: () async {
                              final units = await _showUnitFilterSheet(
                                context,
                                selectedUnits,
                              );
                              if (units == null) return;
                              modalSetState(() => selectedUnits = units);
                            },
                            icon: const Icon(Icons.filter_list, size: 18),
                            label: const Text('Filter'),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: selectedUnits.isEmpty
                                ? const Text(
                                    'All units',
                                    style: TextStyle(
                                      color: Colors.black54,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  )
                                : SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                      children: selectedUnits.map((unitName) {
                                        return Padding(
                                          padding: const EdgeInsets.only(
                                            right: 6,
                                          ),
                                          child: InputChip(
                                            label: Text(unitName),
                                            onDeleted: () {
                                              modalSetState(() {
                                                selectedUnits =
                                                    Set<String>.from(
                                                      selectedUnits,
                                                    )..remove(unitName);
                                              });
                                            },
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.fromLTRB(18, 0, 18, 0),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                      decoration: const BoxDecoration(
                        color: AppColors.creamWhite,
                        border: Border(
                          top: BorderSide(color: Color(0xFFE6E2DD)),
                          bottom: BorderSide(color: Color(0xFFE6E2DD)),
                        ),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 42,
                            child: Checkbox(
                              tristate: true,
                              value: headerCheckboxValue,
                              onChanged: filteredResidents.isEmpty
                                  ? null
                                  : (_) {
                                      if (allShownSelected) {
                                        _clearFilteredResidents(
                                          filteredResidents,
                                        );
                                      } else {
                                        _addFilteredResidents(
                                          filteredResidents,
                                        );
                                      }
                                      modalSetState(() {});
                                    },
                            ),
                          ),
                          const Expanded(
                            flex: 3,
                            child: Text(
                              'Name',
                              style: TextStyle(
                                color: Colors.black54,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const Expanded(
                            flex: 2,
                            child: Text(
                              'Unit',
                              style: TextStyle(
                                color: Colors.black54,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: filteredResidents.isEmpty
                          ? const Center(
                              child: Text(
                                'No matching residents found.',
                                style: TextStyle(color: Colors.black54),
                              ),
                            )
                          : ListView.builder(
                              controller: scrollController,
                              padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                              itemCount: filteredResidents.length,
                              itemBuilder: (context, index) {
                                final resident = filteredResidents[index];
                                final isChecked = _isSelected(resident);
                                return _buildResidentRow(
                                  resident: resident,
                                  isChecked: isChecked,
                                  onChanged: (value) {
                                    _toggleResident(resident, value);
                                    modalSetState(() {});
                                  },
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
      },
    ).whenComplete(searchController.dispose);
  }

  Widget _buildResidentRow({
    required Resident resident,
    required bool isChecked,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFEDE9E4))),
      ),
      child: InkWell(
        onTap: () => onChanged(!isChecked),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Row(
            children: [
              SizedBox(
                width: 42,
                child: Checkbox(
                  value: isChecked,
                  onChanged: (value) => onChanged(value ?? false),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  resident.name,
                  style: const TextStyle(
                    color: AppColors.darkText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  resident.unitName,
                  style: const TextStyle(
                    color: Colors.black54,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<Set<String>?> _showUnitFilterSheet(
    BuildContext context,
    Set<String> currentSelection,
  ) {
    var draftSelection = Set<String>.from(currentSelection);

    return showModalBottomSheet<Set<String>>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, filterSetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Filter by Unit',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.darkText,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _unitFilters.map((unitName) {
                        final selected = draftSelection.contains(unitName);
                        return FilterChip(
                          label: Text(unitName),
                          selected: selected,
                          onSelected: (value) {
                            filterSetState(() {
                              draftSelection = Set<String>.from(draftSelection);
                              if (value) {
                                draftSelection.add(unitName);
                              } else {
                                draftSelection.remove(unitName);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop(<String>{});
                          },
                          child: const Text('Clear'),
                        ),
                        const Spacer(),
                        FilledButton(
                          onPressed: () {
                            Navigator.of(context).pop(draftSelection);
                          },
                          child: const Text('Apply'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
