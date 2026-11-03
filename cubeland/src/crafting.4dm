#ifndef CRAFTING_4DM_INCLUDED
#define CRAFTING_4DM_INCLUDED

#include "../include/common.h"
#include "../include/records.h"
#include "../include/blocks.h"
#include "../include/events.h"
#include "../include/inventory.h"
#include "../include/crafting.h"

// ---------------------------------------------------------------- the recipe book

void crafting_add_recipe(Attributes &book, Integer output, Integer output_count,
                         Integer width, Integer height, Text pattern, Integer item_a, Integer item_b)
// ----------------------------------------------------------------
// Add a recipe. pattern has width * height characters, row by row:
// "A" means item_a, "B" means item_b and "." an empty cell.
// Example, a pickaxe from planks (A) and sticks (B):
//   width 3, height 3, pattern "AAA" + ".B." + ".B." = "AAA.B..B."
// ----------------------------------------------------------------
{
  Integer recipe    = crafting_recipe_count(book) + 1;
  Integer cell      = 0;
  Integer item      = 0;
  Text    character = "";

  record_set_integer_at(book, ATTR_RECIPE_OUTPUT,    recipe, output);
  record_set_integer_at(book, ATTR_RECIPE_OUT_COUNT, recipe, output_count);
  record_set_integer_at(book, ATTR_RECIPE_WIDTH,     recipe, width);
  record_set_integer_at(book, ATTR_RECIPE_HEIGHT,    recipe, height);

  for (cell = 1; cell <= width * height; ++cell) {
    character = Get_subtext(pattern, cell, cell);
    item      = ITEM_NONE;
    if (character == "A") item = item_a;
    if (character == "B") item = item_b;
    record_set_integer(book, record_field_at(record_field_at(ATTR_RECIPE_CELL, recipe), cell), item);
  }

  record_set_integer(book, ATTR_COUNT, recipe);
}

void crafting_init_book(Attributes &book)
// ----------------------------------------------------------------
// Fill the recipe book
// ----------------------------------------------------------------
{
  record_clear      (book, DATATYPE_RECIPE_BOOK);
  record_set_integer(book, ATTR_COUNT, 0);

  //                        output               n  w  h  pattern      A                 B
  crafting_add_recipe(book, ITEM_PLANKS        , 4, 1, 1, "A"        , ITEM_OAK_LOG    , ITEM_NONE );
  crafting_add_recipe(book, ITEM_STICK         , 4, 1, 2, "AA"       , ITEM_PLANKS     , ITEM_NONE );
  crafting_add_recipe(book, ITEM_CRAFTING_TABLE, 1, 2, 2, "AAAA"     , ITEM_PLANKS     , ITEM_NONE );
  crafting_add_recipe(book, ITEM_SANDSTONE     , 1, 2, 2, "AAAA"     , ITEM_SAND       , ITEM_NONE );
  crafting_add_recipe(book, ITEM_FURNACE       , 1, 3, 3, "AAAA.AAAA", ITEM_COBBLESTONE, ITEM_NONE );
  crafting_add_recipe(book, ITEM_WOODEN_PICKAXE, 1, 3, 3, "AAA.B..B.", ITEM_PLANKS     , ITEM_STICK);
  crafting_add_recipe(book, ITEM_STONE_PICKAXE , 1, 3, 3, "AAA.B..B.", ITEM_COBBLESTONE, ITEM_STICK);
  crafting_add_recipe(book, ITEM_WOODEN_AXE    , 1, 2, 3, "AAAB.B"   , ITEM_PLANKS     , ITEM_STICK);
  crafting_add_recipe(book, ITEM_STONE_AXE     , 1, 2, 3, "AAAB.B"   , ITEM_COBBLESTONE, ITEM_STICK);
  crafting_add_recipe(book, ITEM_WOODEN_SHOVEL , 1, 1, 3, "ABB"      , ITEM_PLANKS     , ITEM_STICK);
  crafting_add_recipe(book, ITEM_STONE_SHOVEL  , 1, 1, 3, "ABB"      , ITEM_COBBLESTONE, ITEM_STICK);
  crafting_add_recipe(book, ITEM_WOODEN_SWORD  , 1, 1, 3, "AAB"      , ITEM_PLANKS     , ITEM_STICK);
  crafting_add_recipe(book, ITEM_STONE_SWORD   , 1, 1, 3, "AAB"      , ITEM_COBBLESTONE, ITEM_STICK);
}

Integer crafting_recipe_count(Attributes &book)
// ----------------------------------------------------------------
// Number of recipes in the book
// ----------------------------------------------------------------
{
  return record_integer(book, ATTR_COUNT);
}

Integer crafting_recipe_output(Attributes &book, Integer recipe)
// ----------------------------------------------------------------
// Item a recipe makes
// ----------------------------------------------------------------
{
  return record_integer_at(book, ATTR_RECIPE_OUTPUT, recipe);
}

Integer crafting_recipe_cell(Attributes &book, Integer recipe, Integer column, Integer row)
// ----------------------------------------------------------------
// Item in a pattern cell (column and row from 1), ITEM_NONE for a
// gap or a cell outside the pattern
// ----------------------------------------------------------------
{
  Integer width  = record_integer_at(book, ATTR_RECIPE_WIDTH,  recipe);
  Integer height = record_integer_at(book, ATTR_RECIPE_HEIGHT, recipe);

  if (column < 1 || column > width ) return ITEM_NONE;
  if (row    < 1 || row    > height) return ITEM_NONE;

  return record_integer(book, record_field_at(record_field_at(ATTR_RECIPE_CELL, recipe), (row - 1) * width + column));
}

// ---------------------------------------------------------------- the grid

void grid_clear(Attributes &grid, Integer width)
// ----------------------------------------------------------------
// Empty crafting grid of width 2 or 3
// ----------------------------------------------------------------
{
  container_clear   (grid, DATATYPE_CRAFT_GRID, 1, GRID_SLOTS);
  record_set_integer(grid, ATTR_GRID_WIDTH, width);
}

Integer grid_width(Attributes &grid)
// ----------------------------------------------------------------
// 2 for the inventory grid, 3 at a crafting table
// ----------------------------------------------------------------
{
  return record_integer(grid, ATTR_GRID_WIDTH);
}

Integer grid_slot(Integer column, Integer row)
// ----------------------------------------------------------------
// Slot of a grid cell (column and row from 1, top left first)
// ----------------------------------------------------------------
{
  return (row - 1) * GRID_TABLE_WIDTH + column;
}

Integer grid_slot_used(Attributes &grid, Integer slot)
// ----------------------------------------------------------------
// TRUE if a slot number is part of this grid's size
// ----------------------------------------------------------------
{
  Integer width  = grid_width(grid);
  Integer column = slot - Floor((slot - 1) / 3.0) * 3;
  Integer row    = Floor((slot - 1) / 3.0) + 1;

  if (slot < 1 || slot > GRID_SLOTS) return FALSE;
  if (column > width || row > width) return FALSE;
  return TRUE;
}

Integer crafting_match_at(Attributes &book, Integer recipe, Attributes &grid,
                          Integer left, Integer top, Integer mirrored)
// ----------------------------------------------------------------
// TRUE if the grid holds exactly the recipe's pattern with its top
// left cell at grid column left, row top (optionally mirrored),
// and nothing anywhere else
// ----------------------------------------------------------------
{
  Integer width        = grid_width(grid);
  Integer recipe_width = record_integer_at(book, ATTR_RECIPE_WIDTH, recipe);
  Integer column       = 0;
  Integer row          = 0;
  Integer pattern_col  = 0;
  Integer wanted       = 0;

  for (row = 1; row <= width; ++row) {
    for (column = 1; column <= width; ++column) {
      pattern_col = column - left + 1;
      if (mirrored) pattern_col = recipe_width - pattern_col + 1;
      wanted = crafting_recipe_cell(book, recipe, pattern_col, row - top + 1);
      if (slot_item(grid, grid_slot(column, row)) != wanted) return FALSE;
    }
  }
  return TRUE;
}

Integer crafting_match(Attributes &book, Attributes &grid)
// ----------------------------------------------------------------
// The recipe laid out in the grid, 0 if none
// ----------------------------------------------------------------
{
  Integer width  = grid_width(grid);
  Integer recipe = 0;
  Integer rw     = 0;
  Integer rh     = 0;
  Integer left   = 0;
  Integer top    = 0;
  Integer slot   = 0;
  Integer filled = 0;

  for (slot = 1; slot <= GRID_SLOTS; ++slot) {
    if (!slot_is_empty(grid, slot)) ++filled;
  }
  if (filled == 0) return 0;

  for (recipe = 1; recipe <= crafting_recipe_count(book); ++recipe) {
    rw = record_integer_at(book, ATTR_RECIPE_WIDTH,  recipe);
    rh = record_integer_at(book, ATTR_RECIPE_HEIGHT, recipe);
    if (rw > width || rh > width) continue;
    for (top = 1; top <= width - rh + 1; ++top) {
      for (left = 1; left <= width - rw + 1; ++left) {
        if (crafting_match_at(book, recipe, grid, left, top, FALSE)) return recipe;
        if (crafting_match_at(book, recipe, grid, left, top, TRUE )) return recipe;
      }
    }
  }
  return 0;
}

Integer crafting_take_output(Attributes &book, Attributes &grid, Attributes &holder, Attributes &events)
// ----------------------------------------------------------------
// Click on the output slot: if the grid makes something and the
// cursor (holder's CURSOR_SLOT) can take it, use one item from each
// grid cell and add the result to the cursor
// Emits EVT_ITEM_CRAFTED. Returns the item made, ITEM_NONE if not.
// ----------------------------------------------------------------
{
  Integer recipe       = crafting_match(book, grid);
  Integer output       = 0;
  Integer output_count = 0;
  Integer cursor_item  = slot_item (holder, CURSOR_SLOT);
  Integer cursor_count = slot_count(holder, CURSOR_SLOT);
  Integer slot         = 0;

  if (recipe == 0) return ITEM_NONE;

  output       = crafting_recipe_output(book, recipe);
  output_count = record_integer_at(book, ATTR_RECIPE_OUT_COUNT, recipe);

  if (cursor_item != ITEM_NONE) {
    if (cursor_item != output) return ITEM_NONE;
    if (cursor_count + output_count > item_max_stack(output)) return ITEM_NONE;
  }

  for (slot = 1; slot <= GRID_SLOTS; ++slot) {
    if (!slot_is_empty(grid, slot)) slot_take_one(grid, slot);
  }
  slot_set(holder, CURSOR_SLOT, output, cursor_count + output_count, 0);

  emit_item_event(events, EVT_ITEM_CRAFTED, output, output_count);
  return output;
}

void grid_return_items(Attributes &grid, Attributes &inventory, Attributes &events, Real x, Real y, Real z)
// ----------------------------------------------------------------
// Move everything left in the grid back into the inventory when
// the screen closes; what doesn't fit is dropped at (x, y, z)
// ----------------------------------------------------------------
{
  Integer slot = 0;
  Integer left = 0;

  for (slot = 1; slot <= GRID_SLOTS; ++slot) {
    if (slot_is_empty(grid, slot)) continue;
    left = inventory_add_worn(inventory, slot_item(grid, slot), slot_count(grid, slot), slot_damage(grid, slot));
    if (left > 0) emit_drop_event(events, slot_item(grid, slot), left, slot_damage(grid, slot), x, y, z);
    slot_clear(grid, slot);
  }
}

#endif
