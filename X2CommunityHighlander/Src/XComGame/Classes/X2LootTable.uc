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
public function AddEntry(name TableName, LootTableEntry TableEntry)
{
	AddEntryIntern(self, TableName, TableEntry);
}

public function RemoveEntry(name TableName, LootTableEntry TableEntry)
{
	RemoveEntryIntern(self, TableName, TableEntry);
}

public function AddLootTable(LootTable AddLootTable)
{
	local LootTableEntry Loot;
	foreach AddLootTable.Loots(Loot)
	{
		AddEntryIntern(self, AddLootTable.TableName, Loot);
	}
}

public function RemoveLootTable(LootTable LootTable)
{
	RemoveLootTable(LootTable);
}

public static function AddLootTableStatic(LootTable AddLootTable)
{
	local X2LootTable LootTable;
	local LootTableEntry Loot;

	LootTable = X2LootTable(class'Engine'.static.FindClassDefaultObject(string(default.Class.Name)));
	foreach AddLootTable.Loots(Loot)
	{
		AddEntryIntern(LootTable, AddLootTable.TableName, Loot);
	}
}

public static function RemoveLootTableStatic(LootTable RemoveLootTable)
{
	local X2LootTable LootTable;

	LootTable = X2LootTable(class'Engine'.static.FindClassDefaultObject(string(default.Class.Name)));
	LootTable.LootTables.RemoveItem(RemoveLootTable);
}

public static function AddEntryStatic(name TableName, LootTableEntry AddTableEntry)
{
	local X2LootTable LootTable;

	LootTable = X2LootTable(class'Engine'.static.FindClassDefaultObject(string(default.Class.Name)));
	AddEntryIntern(LootTable, TableName, AddTableEntry);
}

public static function RemoveEntryStatic(name TableName, LootTableEntry TableEntry)
{
	local X2LootTable LootTable;
	LootTable = X2LootTable(class'Engine'.static.FindClassDefaultObject(string(default.Class.Name))); 
	RemoveEntryIntern(LootTable, TableName, TableEntry);
}

private static function RemoveEntryIntern(X2LootTable LootTable, name TableName, LootTableEntry TableEntry)
{
	local int Index, EntryIndex;

	Index = LootTable.LootTables.Find('TableName', TableName);

	if (Index  != INDEX_NONE)
	{
		for (EntryIndex = 0; EntryIndex < LootTable.LootTables[Index].Loots.Length; EntryIndex++)
		{
			if (LootTable.LootTables[Index].Loots[EntryIndex].RollGroup == TableEntry.RollGroup &&
				LootTable.LootTables[Index].Loots[EntryIndex].TemplateName == TableEntry.TemplateName &&
				LootTable.LootTables[Index].Loots[EntryIndex].TableRef == TableEntry.TableRef
			)
			{
				// Remove the table entry
				LootTable.LootTables[Index].Loots.Remove(EntryIndex, 1);
				// Recalculate the chances for the roll group
				RecalculateChances(LootTable, Index, TableEntry.RollGroup);
				break;
			}
		}
	}
}

private static function AddEntryIntern(X2LootTable LootTable, name TableName, LootTableEntry TableEntry)
{
	local int Index;

	Index = LootTable.LootTables.Find('TableName', TableName);

	if (Index  != INDEX_NONE)
	{
		// Add the new table entry
		LootTable.LootTables[Index].Loots.AddItem(TableEntry);

		// Recalculate the chances for the roll group
		RecalculateChances(LootTable, Index, TableEntry.RollGroup);
	}
}

// When the sum of chances is unequal 100% after adding/removing an entry, recalculate chances to 100% total
static function RecalculateChances(X2LootTable LootTable, int Index, int RollGroup)
{
	local LootTableEntry TableEntry;
	local int OldChance, NewChance, SumChances, NewSumChances, TableEntryIndex;

	foreach LootTable.LootTables[Index].Loots(TableEntry)
	{
		if (TableEntry.RollGroup == RollGroup)
			SumChances += TableEntry.Chance;
	}

	if (SumChances != 100)
	{
		for (TableEntryIndex = 0; TableEntryIndex < LootTable.LootTables[Index].Loots.Length; TableEntryIndex++)
		{
			if (LootTable.LootTables[Index].Loots[TableEntryIndex].RollGroup == RollGroup)
			{
				OldChance = LootTable.LootTables[Index].Loots[TableEntryIndex].Chance;
				NewChance = Round(100 / SumChances * OldChance);

				// Add round based differences to the last entry
				NewSumChances += NewChance;
				if(TableEntryIndex == LootTable.LootTables[Index].Loots.Length - 1 && NewSumChances != 100)
				{
					NewChance += (100 - NewSumChances);
				}

				LootTable.LootTables[Index].Loots[TableEntryIndex].Chance = NewChance;
			}
		}
	}
}
// End Issue #275