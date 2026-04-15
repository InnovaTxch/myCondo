import 'package:flutter/material.dart';

import 'package:mycondo/data/models/unit.dart';
import 'package:mycondo/data/models/resident.dart';

class UnitExpansionTile extends ExpansionTile {
  UnitExpansionTile({
    super.key, 
    required BuildContext context,
    required Unit unit,
    required ValueChanged<Unit> addUnit,
    required ValueChanged<Resident> addResident,
  }) : super(
          leading: const Icon(Icons.domain),
          title: Text(unit.name),
          subtitle: Text("${unit.members.length} members"),
          trailing: TextButton(
            onPressed: () {
              addUnit(unit);
              Navigator.pop(context);
            }, 
            child: const Text("ADD UNIT")
          ),
          children: unit.members.map((Resident res) => ListTile(
            title: Text(res.name),
            leading: const Icon(Icons.person_outline),
            onTap: () {
              addResident(res);
              Navigator.pop(context);
            },
          )).toList(),
        );
}