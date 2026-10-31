#ifndef SAVE_4DM_INCLUDED
#define SAVE_4DM_INCLUDED

#include "../include/common.h"
#include "../include/config.h"
#include "../include/util.h"
#include "../include/events.h"
#include "../include/blocks.h"
#include "../include/world.h"
#include "../include/mesh.h"
#include "../include/inventory.h"
#include "../include/furnace.h"
#include "../include/cows.h"
#include "../include/drops.h"
#include "../include/player.h"
#include "../include/save.h"

// ---------------------------------------------------------------- the edit list

void save_clear_edits()
// ----------------------------------------------------------------
// Forget every recorded block change (new or freshly loaded world)
// ----------------------------------------------------------------
{
  g_edit_count    = 0;
  g_edit_overflow = 0;
}

void save_record_edit(Integer index, Integer block)
// ----------------------------------------------------------------
// Remember that the cell at world index now holds block
// Each cell is listed once, with its latest block
// ----------------------------------------------------------------
{
  Integer edit = 0;

  for (edit = g_edit_count; edit >= 1; --edit) {
    if (g_edit_index[edit] == index) {
      g_edit_block[edit] = block;
      return;
    }
  }

  if (g_edit_count >= MAX_EDITS) {
    ++g_edit_overflow;
    return;
  }
  ++g_edit_count;
  g_edit_index[g_edit_count] = index;
  g_edit_block[g_edit_count] = block;
}

void save_on_event()
// ----------------------------------------------------------------
// Event handler: record every block change for the world file
// ----------------------------------------------------------------
{
  if (g_ev_type == EVT_BLOCK_BROKEN) {
    save_record_edit(world_index(g_ev_i1, g_ev_i2, g_ev_i3), BLOCK_AIR);
  } else if (g_ev_type == EVT_BLOCK_PLACED) {
    save_record_edit(world_index(g_ev_i1, g_ev_i2, g_ev_i3), g_ev_i4);
  }
}

// ---------------------------------------------------------------- files and folders

Text save_world_path(Text name)
// ----------------------------------------------------------------
// File holding a world
// ----------------------------------------------------------------
{
  Text folder    = WORLD_FOLDER;
  Text extension = WORLD_EXTENSION;

  return folder + "\\" + name + extension;
}

void save_ensure_folder()
// ----------------------------------------------------------------
// Make the worlds folder if it isn't there yet
// ----------------------------------------------------------------
{
  if (!Directory_exists(WORLD_FOLDER)) Directory_create(WORLD_FOLDER);
}

Integer save_world_exists(Text name)
// ----------------------------------------------------------------
// TRUE if a world of this name has been saved
// ----------------------------------------------------------------
{
  if (File_exists(save_world_path(name))) return TRUE;
  return FALSE;
}

Integer save_list_worlds(Dynamic_Text &names)
// ----------------------------------------------------------------
// Names of every saved world; returns how many there are
// ----------------------------------------------------------------
{
  Dynamic_Text files;
  Integer      count    = 0;
  Integer      file     = 0;
  Integer      found    = 0;
  Text         path     = "";
  Text         pattern  = "*";
  Text         title    = "";

  Null(names);
  save_ensure_folder();

  pattern = pattern + WORLD_EXTENSION;
  if (List_files_in_folder(WORLD_FOLDER, pattern, count, files) != 0) return 0;

  for (file = 1; file <= count; ++file) {
    Get_item(files, file, path);
    title = file_title_from_path(path);
    if (title == "") continue;
    Append(title, names);
    ++found;
  }
  return found;
}

Integer save_delete_world(Text name)
// ----------------------------------------------------------------
// Delete a saved world's file
// ----------------------------------------------------------------
{
  if (!save_world_exists(name)) return FAILURE;
  if (Delete_files(save_world_path(name)) != 0) return FAILURE;
  return SUCCESS;
}

// ---------------------------------------------------------------- saving

Integer save_world()
// ----------------------------------------------------------------
// Write the current world to its file. Emits EVT_WORLD_SAVED.
// ----------------------------------------------------------------
{
  File    file;
  Text    line   = "";
  Integer slot   = 0;
  Integer item   = 0;
  Integer edit   = 0;
  Integer on_row = 0;

  if (g_world_name == "") return FAILURE;

  save_ensure_folder();
  if (File_open(save_world_path(g_world_name), "w", "", file) != 0) return FAILURE;

  line = WORLD_FILE_TAG;
  File_write_line(file, line + " 1");
  File_write_line(file, "seed " + To_text(g_world_seed));
  File_write_line(file, "player " + To_text(g_player_x, 3) + " " + To_text(g_player_y, 3) + " " + To_text(g_player_z, 3)
                      + " " + To_text(g_player_yaw, 4) + " " + To_text(g_player_pitch, 4)
                      + " " + To_text(g_player_health) + " " + To_text(g_player_selected));
  File_write_line(file, "spawn " + To_text(g_spawn_x, 3) + " " + To_text(g_spawn_y, 3) + " " + To_text(g_spawn_z, 3));

  for (slot = 1; slot <= INVENTORY_SLOTS; ++slot) {
    if (g_inv_item[slot] == ITEM_NONE || g_inv_count[slot] <= 0) continue;
    File_write_line(file, "slot " + To_text(slot) + " " + To_text(g_inv_item[slot]) + " " + To_text(g_inv_count[slot]));
  }

  for (item = 1; item <= MAX_FURNACES; ++item) {
    if (!g_furnace_used[item]) continue;
    File_write_line(file, "furnace " + To_text(g_furnace_x[item]) + " " + To_text(g_furnace_y[item]) + " " + To_text(g_furnace_z[item])
                        + " " + To_text(g_furnace_in_item  [item]) + " " + To_text(g_furnace_in_count  [item])
                        + " " + To_text(g_furnace_fuel_item[item]) + " " + To_text(g_furnace_fuel_count[item])
                        + " " + To_text(g_furnace_out_item [item]) + " " + To_text(g_furnace_out_count [item])
                        + " " + To_text(g_furnace_burn_left[item], 2) + " " + To_text(g_furnace_burn_total[item], 2)
                        + " " + To_text(g_furnace_progress [item], 2));
  }

  for (item = 1; item <= MAX_COWS; ++item) {
    if (!g_cow_alive[item]) continue;
    File_write_line(file, "cow " + To_text(g_cow_x[item], 3) + " " + To_text(g_cow_y[item], 3) + " " + To_text(g_cow_z[item], 3)
                        + " " + To_text(g_cow_yaw[item], 3) + " " + To_text(g_cow_health[item]));
  }

  for (item = 1; item <= MAX_DROPS; ++item) {
    if (!g_drop_used[item]) continue;
    File_write_line(file, "drop " + To_text(g_drop_item[item]) + " " + To_text(g_drop_count[item])
                        + " " + To_text(g_drop_x[item], 3) + " " + To_text(g_drop_y[item] + DROP_HALF_SIZE, 3) + " " + To_text(g_drop_z[item], 3));
  }

  // Block changes, several index/block pairs to a line
  line   = "";
  on_row = 0;
  for (edit = 1; edit <= g_edit_count; ++edit) {
    if (on_row == 0) line = "edits";
    line = line + " " + To_text(g_edit_index[edit]) + " " + To_text(g_edit_block[edit]);
    ++on_row;
    if (on_row >= EDITS_PER_LINE) {
      File_write_line(file, line);
      on_row = 0;
    }
  }
  if (on_row > 0) File_write_line(file, line);

  File_write_line(file, "end");
  File_close(file);

  emit_event(EVT_WORLD_SAVED, 0, 0, 0, 0, 0.0, 0.0, 0.0, g_world_name);
  return SUCCESS;
}

// ---------------------------------------------------------------- loading

Integer save_word_integer(Dynamic_Text &words, Integer position)
// ----------------------------------------------------------------
// Word number position of a split line as an Integer (0 if bad)
// ----------------------------------------------------------------
{
  Text    word  = "";
  Integer value = 0;

  Get_item(words, position, word);
  if (Get_subtext(word, 1, 1) == "-") {
    From_text(Get_subtext(word, 2, Text_length(word)), value);
    return -value;
  }
  From_text(word, value);
  return value;
}

Real save_word_real(Dynamic_Text &words, Integer position)
// ----------------------------------------------------------------
// Word number position of a split line as a Real (0 if bad)
// ----------------------------------------------------------------
{
  Text word  = "";
  Real value = 0.0;

  Get_item(words, position, word);
  From_text(word, value);
  return value;
}

Integer load_world(Text name)
// ----------------------------------------------------------------
// Read a world file: regenerate the terrain from its seed, apply
// the saved block changes and restore everything else
// Returns SUCCESS or FAILURE (missing or unreadable file)
// ----------------------------------------------------------------
{
  File         file;
  Dynamic_Text words;
  Text         line     = "";
  Text         key      = "";
  Integer      count    = 0;
  Integer      word     = 0;
  Integer      index    = 0;
  Integer      block    = 0;
  Integer      slot     = 0;
  Integer      furnace  = 0;
  Integer      cow      = 0;
  Integer      cell     = 0;
  Integer      cell_x   = 0;
  Integer      cell_y   = 0;
  Integer      cell_z   = 0;
  Integer      seeded   = FALSE;

  if (!save_world_exists(name)) return FAILURE;
  if (File_open(save_world_path(name), "r", "", file) != 0) return FAILURE;

  if (File_read_line(file, line) != 0) {
    File_close(file);
    return FAILURE;
  }
  Null(words);
  From_text(line, words);
  Get_item(words, 1, key);
  if (key != WORLD_FILE_TAG) {
    File_close(file);
    return FAILURE;
  }

  g_world_name = name;
  save_clear_edits();
  inventory_clear();
  furnaces_clear();
  cows_clear();
  drops_clear();

  while (File_read_line(file, line) == 0) {
    Null(words);
    count = From_text(line, words);
    if (count < 1) continue;
    Get_item(words, 1, key);

    if (key == "end") break;

    if (key == "seed" && count >= 2) {
      world_generate(save_word_integer(words, 2));
      mesh_reset();
      seeded = TRUE;
    } else if (!seeded) {
      continue;
    } else if (key == "player" && count >= 8) {
      player_reset(save_word_real(words, 2), save_word_real(words, 3), save_word_real(words, 4));
      g_player_yaw      = save_word_real   (words, 5);
      g_player_pitch    = save_word_real   (words, 6);
      g_player_health   = clamp_integer(save_word_integer(words, 7), 1, PLAYER_MAX_HEALTH);
      g_player_selected = clamp_integer(save_word_integer(words, 8), 1, HOTBAR_SLOTS);
    } else if (key == "spawn" && count >= 4) {
      g_spawn_x = save_word_real(words, 2);
      g_spawn_y = save_word_real(words, 3);
      g_spawn_z = save_word_real(words, 4);
    } else if (key == "slot" && count >= 4) {
      slot = save_word_integer(words, 2);
      if (slot >= 1 && slot <= INVENTORY_SLOTS) {
        g_inv_item [slot] = save_word_integer(words, 3);
        g_inv_count[slot] = save_word_integer(words, 4);
      }
    } else if (key == "furnace" && count >= 13) {
      furnace = furnace_get_or_create(save_word_integer(words, 2), save_word_integer(words, 3), save_word_integer(words, 4));
      if (furnace > 0) {
        g_furnace_in_item   [furnace] = save_word_integer(words, 5);
        g_furnace_in_count  [furnace] = save_word_integer(words, 6);
        g_furnace_fuel_item [furnace] = save_word_integer(words, 7);
        g_furnace_fuel_count[furnace] = save_word_integer(words, 8);
        g_furnace_out_item  [furnace] = save_word_integer(words, 9);
        g_furnace_out_count [furnace] = save_word_integer(words, 10);
        g_furnace_burn_left [furnace] = save_word_real   (words, 11);
        g_furnace_burn_total[furnace] = save_word_real   (words, 12);
        g_furnace_progress  [furnace] = save_word_real   (words, 13);
      }
    } else if (key == "cow" && count >= 6) {
      cow = cows_spawn(save_word_real(words, 2), save_word_real(words, 3), save_word_real(words, 4), save_word_real(words, 5));
      if (cow > 0) g_cow_health[cow] = clamp_integer(save_word_integer(words, 6), 1, COW_HEALTH);
    } else if (key == "drop" && count >= 6) {
      drops_spawn(save_word_integer(words, 2), save_word_integer(words, 3),
                  save_word_real(words, 4), save_word_real(words, 5), save_word_real(words, 6));
    } else if (key == "edits") {
      for (word = 2; word + 1 <= count; word = word + 2) {
        index = save_word_integer(words, word);
        block = save_word_integer(words, word + 1);
        if (index < 1 || index > WORLD_CELLS) continue;
        g_world[index] = block;
        save_record_edit(index, block);
        // index = (x * WORLD_SIZE_Z + z) * WORLD_HEIGHT + y + 1
        cell   = index - 1;
        cell_y = positive_mod(cell, WORLD_HEIGHT);
        cell   = floor_divide(cell, WORLD_HEIGHT);
        cell_z = positive_mod(cell, WORLD_SIZE_Z);
        cell_x = floor_divide(cell, WORLD_SIZE_Z);
        mesh_mark_dirty(cell_x, cell_y, cell_z);
      }
    }
  }
  File_close(file);

  if (!seeded) return FAILURE;

  // Furnaces that lost their block (shouldn't happen) are dropped
  for (furnace = 1; furnace <= MAX_FURNACES; ++furnace) {
    if (!g_furnace_used[furnace]) continue;
    if (!block_is_furnace(world_get_block(g_furnace_x[furnace], g_furnace_y[furnace], g_furnace_z[furnace]))) {
      g_furnace_used[furnace] = FALSE;
    }
  }

  events_clear();
  return SUCCESS;
}

#endif
