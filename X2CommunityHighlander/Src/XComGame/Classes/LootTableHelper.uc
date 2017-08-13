class LootTableHelper extends Object;

static function AddEntryToLootTable(name TableName, LootTableEntry AddTableEntry)
{
	local X2LootTableManager LootManager;
	local LootTableEntry TableEntry;
	local int Index, TableEntryIndex;
	local int NewSumChances, OldChance, SumChances;

	LootManager = X2LootTableManager(class'Engine'.static.FindClassDefaultObject("X2LootTableManager"));

	Index = LootManager.default.LootTables.Find('TableName', TableName);

	if (Index  != INDEX_NONE)
	{
		foreach LootManager.default.LootTables[Index].Loots(TableEntry)
		{
			if (TableEntry.RollGroup == AddTableEntry.RollGroup)
				SumChances += TableEntry.Chance;
		}

		// Recalculate the chances
		NewSumChances = SumChances + AddTableEntry.Chance;
		if (NewSumChances > 0)
		{
			for (TableEntryIndex = 0; TableEntryIndex < LootManager.default.LootTables[Index].Loots.Length; TableEntryIndex++)
			{
				if (LootManager.default.LootTables[Index].Loots[TableEntryIndex].RollGroup == AddTableEntry.RollGroup)
				{
					OldChance = LootManager.default.LootTables[Index].Loots[TableEntryIndex].Chance;
					LootManager.default.LootTables[Index].Loots[TableEntryIndex].Chance = Round(100 / NewSumChances * OldChance);
				}
			}
			AddTableEntry.Chance = Round(100 / NewSumChances * AddTableEntry.Chance);
		}

		// Add the new table entry
		LootManager.default.LootTables[Index].Loots.AddItem(AddTableEntry);
	}
}