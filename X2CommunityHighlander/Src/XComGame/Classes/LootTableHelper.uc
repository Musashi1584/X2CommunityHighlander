class LootTableHelper extends Object;

static function AddEntryToLootTable(name TableName, LootTableEntry AddTableEntry)
{
	local X2LootTable LootTableCDO;
	local LootTableEntry TableEntry;
	local int Index, TableEntryIndex;
	local array<int> SumChances;
	local int NewSumChances, OldChance;

	LootTableCDO = X2LootTable (class'Engine'.static.FindClassDefaultObject("X2LootTable"));

	Index = LootTableCDO.default.LootTables.Find('TableName', TableName);

	if (Index  != INDEX_NONE)
	{
		foreach LootTableCDO.default.LootTables[Index].Loots(TableEntry)
		{
			SumChances[TableEntry.RollGroup] += TableEntry.Chance;
		}

		// Recalculate the chances
		NewSumChances = SumChances[AddTableEntry.RollGroup] + AddTableEntry.Chance;
		if (NewSumChances > 0)
		{
			for (TableEntryIndex = 0; TableEntryIndex < LootTableCDO.default.LootTables[Index].Loots.Length; TableEntryIndex++)
			{
				if (LootTableCDO.default.LootTables[Index].Loots[TableEntryIndex].RollGroup == AddTableEntry.RollGroup)
				{
					OldChance = LootTableCDO.default.LootTables[Index].Loots[TableEntryIndex].Chance;
					LootTableCDO.default.LootTables[Index].Loots[TableEntryIndex].Chance = Round(100 / NewSumChances * OldChance);

				}
			}
			AddTableEntry.Chance = Round(100 / NewSumChances * AddTableEntry.Chance);
		}

		// Add the new table entry
		LootTableCDO.default.LootTables[Index].Loots.AddItem(AddTableEntry);
	}
}