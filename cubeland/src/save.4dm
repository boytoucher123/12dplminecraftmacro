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
#include "../include/records.h"
#include "../include/settings.h"
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

void save_on_event(Attributes &event)
// ----------------------------------------------------------------
// Event handler: record every block change for the world file
// ----------------------------------------------------------------
{
  Integer type = event_type(event);
  Integer x    = event_integer(event, 1);
  Integer y    = event_integer(event, 2);
  Integer z    = event_integer(event, 3);

  if (!world_in_bounds(x, y, z)) return;

  if (type == EVT_BLOCK_BROKEN) {
    save_record_edit(world_index(x, y, z), BLOCK_AIR);
  } else if (type == EVT_BLOCK_PLACED) {
    save_record_edit(world_index(x, y, z), event_integer(event, 4));
  }
}

Text save_world_path(Text name)
// ----------------------------------------------------------------
// File holding a world
// ----------------------------------------------------------------
{
  Text folder    = WORLD_FOLDER;
  Text extension = WORLD_EXTENSION;

  return folder + "\\" + name + extension;
}

Text save_settings_path()
// ----------------------------------------------------------------
// File holding the settings (shared by every world)
// ----------------------------------------------------------------
{
  Text folder = WORLD_FOLDER;
  Text file   = SETTINGS_FILE;

  return folder + "\\" + file;
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

// ---------------------------------------------------------------- records

Text text_escape(Text value)
// ----------------------------------------------------------------
// Make a Text value safe to store as one word: "%" becomes "%25",
// a space "%20", and an empty value "%00"
// ----------------------------------------------------------------
{
  Integer length    = Text_length(value);
  Integer position  = 0;
  Text    character = "";
  Text    result    = "";

  if (length == 0) return "%00";

  for (position = 1; position <= length; ++position) {
    character = Get_subtext(value, position, position);
    if (character == "%") {
      result = result + "%25";
    } else if (character == " ") {
      result = result + "%20";
    } else {
      result = result + character;
    }
  }
  return result;
}

Text text_unescape(Text value)
// ----------------------------------------------------------------
// Undo text_escape
// ----------------------------------------------------------------
{
  Integer length    = Text_length(value);
  Integer position  = 1;
  Text    character = "";
  Text    code      = "";
  Text    result    = "";

  while (position <= length) {
    character = Get_subtext(value, position, position);
    if (character == "%" && position + 2 <= length) {
      code = Get_subtext(value, position + 1, position + 2);
      if (code == "25") result = result + "%";
      if (code == "20") result = result + " ";
      position = position + 3;
      continue;
    }
    result   = result + character;
    position = position + 1;
  }
  return result;
}

void save_write_record(File &file, Text name, Attributes &record)
// ----------------------------------------------------------------
// Write every field of a record as "rec <name> <field> <type>
// <value>" lines. A field's type is found by trying to read it as
// an Integer, then a Real, then a Text.
// ----------------------------------------------------------------
{
  Integer fields        = 0;
  Integer field         = 0;
  Integer integer_value = 0;
  Real    real_value    = 0.0;
  Text    text_value    = "";
  Text    field_name    = "";
  Text    start         = "";

  Get_number_of_attributes(record, fields);
  for (field = 1; field <= fields; ++field) {
    if (Get_attribute_name(record, field, field_name) != 0) continue;
    start = "rec " + name + " " + field_name;
    if (Get_attribute(record, field, integer_value) == 0) {
      File_write_line(file, start + " i " + To_text(integer_value));
    } else if (Get_attribute(record, field, real_value) == 0) {
      File_write_line(file, start + " r " + To_text(real_value, 6));
    } else if (Get_attribute(record, field, text_value) == 0) {
      File_write_line(file, start + " t " + text_escape(text_value));
    }
  }
}

Integer save_read_field(Dynamic_Text &words, Integer count, Attributes &record)
// ----------------------------------------------------------------
// Apply one "rec <name> <field> <type> <value>" line (already split
// into words) to a record. Returns SUCCESS or FAILURE.
// ----------------------------------------------------------------
{
  Text field = "";
  Text type  = "";
  Text value = "";

  if (count < 5) return FAILURE;

  Get_item(words, 3, field);
  Get_item(words, 4, type);
  Get_item(words, 5, value);

  if (type == "i") {
    record_set_integer(record, field, save_word_integer(words, 5));
  } else if (type == "r") {
    record_set_real(record, field, save_word_real(words, 5));
  } else if (type == "t") {
    record_set_text(record, field, text_unescape(value));
  } else {
    return FAILURE;
  }
  return SUCCESS;
}

// ---------------------------------------------------------------- worlds

Integer save_world(Text name, Attributes &info, Attributes &player, Attributes &inventory,
                   Attributes &furnaces, Attributes &cows, Attributes &drops, Attributes &events)
// ----------------------------------------------------------------
// Write a world to its file. Emits EVT_WORLD_SAVED.
// ----------------------------------------------------------------
{
  File    file;
  Text    line   = "";
  Integer edit   = 0;
  Integer on_row = 0;

  if (name == "") return FAILURE;

  save_ensure_folder();
  if (File_open(save_world_path(name), "w", "", file) != 0) return FAILURE;

  line = WORLD_FILE_TAG;
  File_write_line(file, line + " " + To_text(WORLD_FILE_VERSION));
  File_write_line(file, "seed " + To_text(world_info_seed(info)));

  save_write_record(file, RECORD_WORLD,     info);
  save_write_record(file, RECORD_PLAYER,    player);
  save_write_record(file, RECORD_INVENTORY, inventory);
  save_write_record(file, RECORD_FURNACES,  furnaces);
  save_write_record(file, RECORD_COWS,      cows);
  save_write_record(file, RECORD_DROPS,     drops);

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

  emit_event(events, EVT_WORLD_SAVED, 0, 0, 0, 0, 0.0, 0.0, 0.0, name);
  return SUCCESS;
}

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

Integer load_world(Text name, Attributes &info, Attributes &player, Attributes &inventory,
                   Attributes &furnaces, Attributes &cows, Attributes &drops, Text &problem)
// ----------------------------------------------------------------
// Read a world file: regenerate the terrain from its seed, apply
// the saved block changes and read the records back
// Returns SUCCESS, or FAILURE with problem saying why
// ----------------------------------------------------------------
{
  File         file;
  Dynamic_Text words;
  Text         line     = "";
  Text         key      = "";
  Text         target   = "";
  Integer      count    = 0;
  Integer      word     = 0;
  Integer      index    = 0;
  Integer      block    = 0;
  Integer      furnace  = 0;
  Integer      cell     = 0;
  Integer      cell_x   = 0;
  Integer      cell_y   = 0;
  Integer      cell_z   = 0;
  Integer      fx       = 0;
  Integer      fy       = 0;
  Integer      fz       = 0;
  Integer      seeded   = FALSE;

  problem = "";
  if (!save_world_exists(name)) {
    problem = "there is no saved world called " + name;
    return FAILURE;
  }
  if (File_open(save_world_path(name), "r", "", file) != 0) {
    problem = "the world file couldn't be opened";
    return FAILURE;
  }

  if (File_read_line(file, line) != 0) {
    File_close(file);
    problem = "the world file is empty";
    return FAILURE;
  }
  Null(words);
  count = From_text(line, words);
  Get_item(words, 1, key);
  if (key != WORLD_FILE_TAG) {
    File_close(file);
    problem = "it isn't a Cubeland world file";
    return FAILURE;
  }
  if (count < 2 || save_word_integer(words, 2) != WORLD_FILE_VERSION) {
    File_close(file);
    problem = "it was saved by an older version of Cubeland";
    return FAILURE;
  }

  save_clear_edits();
  inventory_clear (inventory);
  furnaces_clear  (furnaces);
  cows_clear      (cows);
  drops_clear     (drops);

  while (File_read_line(file, line) == 0) {
    Null(words);
    count = From_text(line, words);
    if (count < 1) continue;
    Get_item(words, 1, key);

    if (key == "end") break;

    if (key == "seed" && count >= 2) {
      world_generate(info, save_word_integer(words, 2));
      mesh_reset();
      player_reset(player, 0.0, 0.0, 0.0);
      seeded = TRUE;
    } else if (!seeded) {
      continue;
    } else if (key == "rec" && count >= 5) {
      Get_item(words, 2, target);
      if (target == RECORD_WORLD    ) save_read_field(words, count, info);
      if (target == RECORD_PLAYER   ) save_read_field(words, count, player);
      if (target == RECORD_INVENTORY) save_read_field(words, count, inventory);
      if (target == RECORD_FURNACES ) save_read_field(words, count, furnaces);
      if (target == RECORD_COWS     ) save_read_field(words, count, cows);
      if (target == RECORD_DROPS    ) save_read_field(words, count, drops);
    } else if (key == "edits") {
      for (word = 2; word + 1 <= count; word = word + 2) {
        index = save_word_integer(words, word);
        block = save_word_integer(words, word + 1);
        if (index < 1 || index > WORLD_CELLS) continue;
        save_record_edit(index, block);
        // index = (x * WORLD_SIZE_Z + z) * WORLD_HEIGHT + y + 1
        cell   = index - 1;
        cell_y = positive_mod(cell, WORLD_HEIGHT);
        cell   = floor_divide(cell, WORLD_HEIGHT);
        cell_z = positive_mod(cell, WORLD_SIZE_Z);
        cell_x = floor_divide(cell, WORLD_SIZE_Z);
        world_set_block(cell_x, cell_y, cell_z, block);
        mesh_mark_dirty(cell_x, cell_y, cell_z);
      }
    }
  }
  File_close(file);

  if (!seeded) {
    problem = "the world file has no seed";
    return FAILURE;
  }
  world_finish_maps();

  // Furnaces that lost their block (shouldn't happen) are forgotten
  for (furnace = 1; furnace <= MAX_FURNACES; ++furnace) {
    if (!furnace_used(furnaces, furnace)) continue;
    furnace_cell(furnaces, furnace, fx, fy, fz);
    if (!block_is_furnace(world_get_block(fx, fy, fz))) record_set_integer_at(furnaces, ATTR_USED, furnace, FALSE);
  }

  return SUCCESS;
}

#endif
