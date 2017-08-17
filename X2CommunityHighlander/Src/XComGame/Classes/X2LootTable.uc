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
public function AddEntryAndReload(name TableName, LootTableEntry TableEntry)
{
	AddEntry(self, TableName, TableEntry);
	InitLootTables();
}

public function RemoveEntryAndReload(name TableName, LootTableEntry TableEntry)
{
	RemoveEntry(self, TableName, TableEntry);
	InitLootTables();
}

public function AddLootTableAndReload(LootTable AddLootTable)
{
	local LootTableEntry Loot;
	foreach AddLootTable.Loots(Loot)
	{
		AddEntry(self, AddLootTable.TableName, Loot);
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
	local X2LootTable LootTable;
	local LootTableEntry Loot;

	LootTable = X2LootTable(class'Engine'.static.FindClassDefaultObject(string(default.Class.Name)));
	foreach AddLootTable.Loots(Loot)
	{
		AddEntry(LootTable, AddLootTable.TableName, Loot);
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
	local X2LootTable LootTable;

	LootTable = X2LootTable(class'Engine'.static.FindClassDefaultObject(string(default.Class.Name)));
	AddEntry(LootTable, TableName, AddTableEntry);
}

public static function RemoveEntryFromLootTable(name TableName, LootTableEntry TableEntry)
{
	local X2LootTable LootTable;
	LootTable = X2LootTable(class'Engine'.static.FindClassDefaultObject(string(default.Class.Name))); 
	RemoveEntry(LootTable, TableName, TableEntry);
}

private static function RemoveEntry(X2LootTable LootTable, name TableName, LootTableEntry TableEntry)
{
	local int Index;

	Index = LootTable.LootTables.Find('TableName', TableName);

	if (Index  != INDEX_NONE)
	{
		LootTable.LootTables[Index].Loots.RemoveItem(TableEntry);
	}
}

// When the sum of chances is greater 100% after adding an entry, recalculate chances to 100% total
private static function AddEntry(X2LootTable LootTable, name TableName, LootTableEntry AddTableEntry)
{
	local LootTableEntry TableEntry;
	local int Index, OldChance, NewChance, SumChances, TableEntryIndex;

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