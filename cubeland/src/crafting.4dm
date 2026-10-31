#ifndef CRAFTING_4DM_INCLUDED
#define CRAFTING_4DM_INCLUDED

#include "../include/common.h"
#include "../include/blocks.h"
#include "../include/events.h"
#include "../include/inventory.h"
#include "../include/crafting.h"

void crafting_add_recipe(Integer output, Integer output_count, Integer needs_table,
                         Integer input_1, Integer count_1, Integer input_2, Integer count_2)
// ----------------------------------------------------------------
// Register a recipe; use ITEM_NONE / 0 for an unused input
// ----------------------------------------------------------------
{
  if (g_recipe_count >= MAX_RECIPES) return;

  ++g_recipe_count;
  g_recipe_output      [g_recipe_count] = output;
  g_recipe_output_count[g_recipe_count] = output_count;
  g_recipe_needs_table [g_recipe_count] = needs_table;

  g_recipe_input      [crafting_input_slot(g_recipe_count, 1)] = input_1;
  g_recipe_input_count[crafting_input_slot(g_recipe_count, 1)] = count_1;
  g_recipe_input      [crafting_input_slot(g_recipe_count, 2)] = input_2;
  g_recipe_input_count[crafting_input_slot(g_recipe_count, 2)] = count_2;
}

void crafting_init()
// ----------------------------------------------------------------
// The recipe book
// ----------------------------------------------------------------
{
  g_recipe_count = 0;

  //                  output               count  table  input 1           n  input 2     n
  crafting_add_recipe(ITEM_PLANKS        , 4    , FALSE, ITEM_OAK_LOG    , 1, ITEM_NONE , 0);
  crafting_add_recipe(ITEM_STICK         , 4    , FALSE, ITEM_PLANKS     , 2, ITEM_NONE , 0);
  crafting_add_recipe(ITEM_CRAFTING_TABLE, 1    , FALSE, ITEM_PLANKS     , 4, ITEM_NONE , 0);
  crafting_add_recipe(ITEM_FURNACE       , 1    , TRUE , ITEM_COBBLESTONE, 8, ITEM_NONE , 0);
  crafting_add_recipe(ITEM_STICK         , 2    , TRUE , ITEM_LEAVES     , 4, ITEM_NONE , 0);
  crafting_add_recipe(ITEM_GRASS         , 1    , TRUE , ITEM_DIRT       , 1, ITEM_LEAVES, 1);
}

Integer crafting_input_slot(Integer recipe, Integer which)
// ----------------------------------------------------------------
// Position of input which (1 or 2) of a recipe in g_recipe_input
// ----------------------------------------------------------------
{
  return (recipe - 1) * RECIPE_INPUTS + which;
}

Integer crafting_can_craft(Integer recipe)
// ----------------------------------------------------------------
// TRUE if the inventory holds every ingredient of a recipe
// ----------------------------------------------------------------
{
  Integer which = 0;
  Integer slot  = 0;

  if (recipe < 1 || recipe > g_recipe_count) return FALSE;

  for (which = 1; which <= RECIPE_INPUTS; ++which) {
    slot = crafting_input_slot(recipe, which);
    if (g_recipe_input[slot] == ITEM_NONE) continue;
    if (inventory_count_item(g_recipe_input[slot]) < g_recipe_input_count[slot]) return FALSE;
  }
  return TRUE;
}

Integer crafting_craft(Integer recipe, Real drop_x, Real drop_y, Real drop_z)
// ----------------------------------------------------------------
// Make a recipe once: take the ingredients, add the result
// If the result doesn't fit it is dropped at (drop_x, y, z)
// Emits EVT_ITEM_CRAFTED. Returns SUCCESS or FAILURE.
// ----------------------------------------------------------------
{
  Integer which = 0;
  Integer slot  = 0;
  Integer left  = 0;

  if (!crafting_can_craft(recipe)) return FAILURE;

  for (which = 1; which <= RECIPE_INPUTS; ++which) {
    slot = crafting_input_slot(recipe, which);
    if (g_recipe_input[slot] == ITEM_NONE) continue;
    inventory_remove_item(g_recipe_input[slot], g_recipe_input_count[slot]);
  }

  left = inventory_add(g_recipe_output[recipe], g_recipe_output_count[recipe]);
  if (left > 0) emit_drop_event(g_recipe_output[recipe], left, drop_x, drop_y, drop_z);

  emit_item_event(EVT_ITEM_CRAFTED, g_recipe_output[recipe], g_recipe_output_count[recipe]);
  return SUCCESS;
}

Text crafting_describe(Integer recipe)
// ----------------------------------------------------------------
// "4 Oak Planks + 1 Oak Leaves" style list of ingredients
// ----------------------------------------------------------------
{
  Integer which  = 0;
  Integer slot   = 0;
  Text    result = "";

  for (which = 1; which <= RECIPE_INPUTS; ++which) {
    slot = crafting_input_slot(recipe, which);
    if (g_recipe_input[slot] == ITEM_NONE) continue;
    if (result != "") result = result + " + ";
    result = result + To_text(g_recipe_input_count[slot]) + " " + item_name(g_recipe_input[slot]);
  }
  return result;
}

#endif
