class X2LootTable extends Object
	native(Core)
	config(GameCore);

cpptext
{
	virtual void RollForLootTableGroup(const FLootTable& LootTable, INT Group, TArray<FName>& RolledLoot);
}

// Issue #41 - making non-private to DLC/Mods can make run-time adjustments 
//             requires re-invoking InitLootTables again
var config array<LootTable> LootTables; 
var private native Map_Mirror       LootTablesMap{TMap<FName, INT>};        //  maps table name to index into LootTables array

// bValidateItemNames when false, expected to be used for character template names.
native function InitLootTables(bool bValidateItemNames=true);		//  validates loot tables and sets up LootTablesMap
native function RollForLootTable(const out name LootTableName, out array<name> RolledLoot);

// Start Issue #275 - Add a loot table interface
// static function are for use in the DLCInfo OnPostTemplatesCreated event
public function AddEntryAndReload(name TableName, LootTableEntry AddTableEntry)
{
	AddEntry(TableName, AddTableEntry);
	InitLootTables();
}

public function RemoveEntryAndReload(name TableName, LootTableEntry TableEntry)
{
	RemoveEntry(TableName, TableEntry);
	InitLootTables();
}

public function AddLootTableAndReload(LootTable AddLootTable)
{
	local LootTableEntry Loot;
	foreach AddLootTable.Loots(Loot)
	{
		AddEntry(AddLootTable.TableName, Loot);
	}
	InitLootTables();
}

public function RemoveLootTableAndReload(LootTable LootTable)
{
	RemoveLootTable(LootTable);
	InitLootTables();
}

public static function AddLootTable(LootTable AddLootTable)
{
	local LootTableEntry Loot;
	foreach AddLootTable.Loots(Loot)
	{
		AddEntry(AddLootTable.TableName, Loot);
	}
}

public static function RemoveLootTable(LootTable RemoveLootTable)
{
	local X2LootTable LootTable;

	LootTable = X2LootTable(class'Engine'.static.FindClassDefaultObject(string(default.Class.Name)));
	LootTable.LootTables.RemoveItem(RemoveLootTable);
}

public static function AddEntryToLootTable(name TableName, LootTableEntry AddTableEntry)
{
	AddEntry(TableName, AddTableEntry);
}

private static function RemoveEntry(name TableName, LootTableEntry TableEntry)
{
	local X2LootTable LootTable;
	local int Index;

	LootTable = X2LootTable(class'Engine'.static.FindClassDefaultObject(string(default.Class.Name))); 

	Index = LootTable.LootTables.Find('TableName', TableName);

	if (Index  != INDEX_NONE)
	{
		LootTable.LootTables[Index].Loots.RemoveItem(TableEntry);
	}
}

// When the sum of chances is greater 100% after adding an entry, recalculate chances to 100% total
private static function AddEntry(name TableName, LootTableEntry AddTableEntry)
{
	local X2LootTable LootTable;
	local LootTableEntry TableEntry;
	local int Index, OldChance, NewChance, SumChances, TableEntryIndex;

	LootTable = X2LootTable(class'Engine'.static.FindClassDefaultObject(string(default.Class.Name))); 
	`LOG(string(default.Class.Name) @ LootTable);

	Index = LootTable.LootTables.Find('TableName', TableName);

	if (Index  != INDEX_NONE)
	{
		// Add the new table entry
		LootTable.LootTables[Index].Loots.AddItem(AddTableEntry);

		// Recalculate the chances
		foreach LootTable.LootTables[Index].Loots(TableEntry)
		{
			if (TableEntry.RollGroup == AddTableEntry.RollGroup)
				SumChances += TableEntry.Chance;
		}

		if (SumChances > 100)
		{
			for (TableEntryIndex = 0; TableEntryIndex < LootTable.LootTables[Index].Loots.Length; TableEntryIndex++)
			{
				if (LootTable.LootTables[Index].Loots[TableEntryIndex].RollGroup == AddTableEntry.RollGroup)
				{
					OldChance = LootTable.LootTables[Index].Loots[TableEntryIndex].Chance;
					NewChance = Round(100 / SumChances * OldChance);
					LootTable.LootTables[Index].Loots[TableEntryIndex].Chance = NewChance;
				}
			}
		}
	}
}
// End Issue #275