#ifndef SAVE_H_INCLUDED
#define SAVE_H_INCLUDED

#include "config.h"

// ----------------------------------------------------------------
// World files
// A world is saved as its seed plus everything that differs from
// what the seed generates: the blocks that were changed, the
// player, the inventory, furnaces, cows and dropped items. Loading
// regenerates the terrain from the seed and applies the changes.
// Files live in WORLD_FOLDER inside the 12d working folder.
// ----------------------------------------------------------------

#define WORLD_FOLDER     "cubeland_worlds"
#define WORLD_EXTENSION  ".cubeworld"
#define WORLD_FILE_TAG   "CUBELAND_WORLD"
#define EDITS_PER_LINE   16

/*Global variables*/ {
  Text    g_world_name = "";
  Integer g_edit_count = 0;
  Integer g_edit_index[MAX_EDITS];
  Integer g_edit_block[MAX_EDITS];
  Integer g_edit_overflow = 0;
}

void    save_clear_edits ();
void    save_record_edit (Integer index, Integer block);
void    save_on_event    ();
Text    save_world_path  (Text name);
void    save_ensure_folder();
Integer save_world_exists(Text name);
Integer save_list_worlds (Dynamic_Text &names);
Integer save_delete_world(Text name);
Integer save_world       ();
Integer load_world       (Text name);

#endif
