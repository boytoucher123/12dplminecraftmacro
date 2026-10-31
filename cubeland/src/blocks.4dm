#ifndef BLOCKS_4DM_INCLUDED
#define BLOCKS_4DM_INCLUDED

#include "../include/common.h"
#include "../include/blocks.h"
#include "../include/textures.h"

Integer block_is_solid(Integer block)
// ----------------------------------------------------------------
// TRUE for blocks that stop movement and hide the faces behind them
// ----------------------------------------------------------------
{
  if (block == BLOCK_AIR  ) return FALSE;
  if (block == BLOCK_WATER) return FALSE;
  return TRUE;
}

Integer block_is_furnace(Integer block)
// ----------------------------------------------------------------
// TRUE for any of the four furnace orientations
// ----------------------------------------------------------------
{
  if (block >= BLOCK_FURNACE_PX && block <= BLOCK_FURNACE_NZ) return TRUE;
  return FALSE;
}

Integer block_furnace_front(Integer block)
// ----------------------------------------------------------------
// Direction the door of a furnace block faces, 0 if not a furnace
// ----------------------------------------------------------------
{
  if (block == BLOCK_FURNACE_PX) return DIR_PX;
  if (block == BLOCK_FURNACE_NX) return DIR_NX;
  if (block == BLOCK_FURNACE_PZ) return DIR_PZ;
  if (block == BLOCK_FURNACE_NZ) return DIR_NZ;
  return 0;
}

Integer block_hardness(Integer block)
// ----------------------------------------------------------------
// Number of hits to break a block by hand, 0 means unbreakable
// ----------------------------------------------------------------
{
  if (block == BLOCK_BEDROCK       ) return 0;
  if (block == BLOCK_WATER         ) return 0;
  if (block == BLOCK_AIR           ) return 0;
  if (block == BLOCK_LEAVES        ) return 1;
  if (block == BLOCK_DIRT          ) return 2;
  if (block == BLOCK_GRASS         ) return 2;
  if (block == BLOCK_SAND          ) return 2;
  if (block == BLOCK_OAK_LOG       ) return 3;
  if (block == BLOCK_PLANKS        ) return 3;
  if (block == BLOCK_CRAFTING_TABLE) return 3;
  return 4;
}

Integer block_drop_item(Integer block)
// ----------------------------------------------------------------
// Item left behind when a block is broken, ITEM_NONE for nothing
// ----------------------------------------------------------------
{
  if (block == BLOCK_GRASS   ) return ITEM_DIRT;
  if (block == BLOCK_STONE   ) return ITEM_COBBLESTONE;
  if (block == BLOCK_LEAVES  ) return ITEM_NONE;
  if (block == BLOCK_WATER   ) return ITEM_NONE;
  if (block == BLOCK_AIR     ) return ITEM_NONE;
  if (block == BLOCK_BEDROCK ) return ITEM_NONE;
  if (block_is_furnace(block)) return ITEM_FURNACE;
  return block;
}

Integer block_face_texture(Integer block, Integer direction)
// ----------------------------------------------------------------
// Texture drawn on one face of a block
// Lit furnace doors are swapped in by the renderer
// ----------------------------------------------------------------
{
  if (block == BLOCK_BEDROCK    ) return TEX_BEDROCK;
  if (block == BLOCK_STONE      ) return TEX_STONE;
  if (block == BLOCK_COBBLESTONE) return TEX_COBBLESTONE;
  if (block == BLOCK_DIRT       ) return TEX_DIRT;
  if (block == BLOCK_LEAVES     ) return TEX_LEAVES;
  if (block == BLOCK_WATER      ) return TEX_WATER;
  if (block == BLOCK_PLANKS     ) return TEX_PLANKS;
  if (block == BLOCK_SAND       ) return TEX_SAND;

  if (block == BLOCK_GRASS) {
    if (direction == DIR_PY) return TEX_GRASS_TOP;
    if (direction == DIR_NY) return TEX_DIRT;
    return TEX_GRASS_SIDE;
  }
  if (block == BLOCK_OAK_LOG) {
    if (direction == DIR_PY || direction == DIR_NY) return TEX_LOG_TOP;
    return TEX_LOG_SIDE;
  }
  if (block == BLOCK_CRAFTING_TABLE) {
    if (direction == DIR_PY) return TEX_TABLE_TOP;
    if (direction == DIR_NY) return TEX_PLANKS;
    return TEX_TABLE_SIDE;
  }
  if (block_is_furnace(block)) {
    if (direction == DIR_PY || direction == DIR_NY) return TEX_FURNACE_TOP;
    if (direction == block_furnace_front(block)   ) return TEX_FURNACE_FRONT;
    return TEX_FURNACE_SIDE;
  }

  return TEX_STONE;
}

Real block_face_shade(Integer direction)
// ----------------------------------------------------------------
// Fixed light level of a face direction (sun from above, slightly
// to one side) so the sides of a cube read clearly
// ----------------------------------------------------------------
{
  if (direction == DIR_PY) return 1.0;
  if (direction == DIR_NY) return 0.55;
  if (direction == DIR_PZ || direction == DIR_NZ) return 0.84;
  return 0.70;
}

Text item_name(Integer item)
// ----------------------------------------------------------------
// Display name of an item
// ----------------------------------------------------------------
{
  if (item == ITEM_BEDROCK       ) return "Bedrock";
  if (item == ITEM_STONE         ) return "Stone";
  if (item == ITEM_COBBLESTONE   ) return "Cobblestone";
  if (item == ITEM_DIRT          ) return "Dirt";
  if (item == ITEM_GRASS         ) return "Grass Block";
  if (item == ITEM_OAK_LOG       ) return "Oak Log";
  if (item == ITEM_LEAVES        ) return "Oak Leaves";
  if (item == ITEM_PLANKS        ) return "Oak Planks";
  if (item == ITEM_CRAFTING_TABLE) return "Crafting Table";
  if (item == ITEM_FURNACE       ) return "Furnace";
  if (item == ITEM_SAND          ) return "Sand";
  if (item == ITEM_STICK         ) return "Stick";
  if (item == ITEM_RAW_BEEF      ) return "Raw Beef";
  if (item == ITEM_COOKED_BEEF   ) return "Cooked Beef";
  return "";
}

Integer item_places_block(Integer item)
// ----------------------------------------------------------------
// Block an item places, BLOCK_AIR if it cannot be placed
// Furnaces are turned to face the player when placed
// ----------------------------------------------------------------
{
  if (item >= ITEM_BEDROCK && item <= ITEM_FURNACE) {
    if (item == 8) return BLOCK_AIR;
    return item;
  }
  if (item == ITEM_SAND) return BLOCK_SAND;
  return BLOCK_AIR;
}

Integer item_is_block(Integer item)
// ----------------------------------------------------------------
// TRUE if the item is drawn as a little cube
// ----------------------------------------------------------------
{
  if (item_places_block(item) != BLOCK_AIR) return TRUE;
  return FALSE;
}

Integer item_food_value(Integer item)
// ----------------------------------------------------------------
// Health restored by eating an item, 0 if it is not food
// ----------------------------------------------------------------
{
  if (item == ITEM_RAW_BEEF   ) return 2;
  if (item == ITEM_COOKED_BEEF) return 7;
  return 0;
}

Integer item_fuel_seconds(Integer item)
// ----------------------------------------------------------------
// Seconds an item burns for in a furnace, 0 if it is not fuel
// One item takes COOK_SECONDS to cook
// ----------------------------------------------------------------
{
  if (item == ITEM_OAK_LOG       ) return 20;
  if (item == ITEM_PLANKS        ) return 10;
  if (item == ITEM_CRAFTING_TABLE) return 15;
  if (item == ITEM_STICK         ) return 5;
  return 0;
}

Integer item_smelt_result(Integer item)
// ----------------------------------------------------------------
// What a furnace turns an item into, ITEM_NONE if it cannot
// ----------------------------------------------------------------
{
  if (item == ITEM_RAW_BEEF   ) return ITEM_COOKED_BEEF;
  if (item == ITEM_COBBLESTONE) return ITEM_STONE;
  return ITEM_NONE;
}

Integer item_top_texture(Integer item)
// ----------------------------------------------------------------
// Texture for the top of an item's cube (icons and dropped items)
// ----------------------------------------------------------------
{
  if (item == ITEM_STICK      ) return TEX_STICK;
  if (item == ITEM_RAW_BEEF   ) return TEX_RAW_BEEF;
  if (item == ITEM_COOKED_BEEF) return TEX_COOKED_BEEF;
  if (item == ITEM_FURNACE    ) return TEX_FURNACE_TOP;
  return block_face_texture(item_places_block(item), DIR_PY);
}

Integer item_side_texture(Integer item)
// ----------------------------------------------------------------
// Texture for the sides of an item's cube (icons and dropped items)
// ----------------------------------------------------------------
{
  if (item == ITEM_STICK      ) return TEX_STICK;
  if (item == ITEM_RAW_BEEF   ) return TEX_RAW_BEEF;
  if (item == ITEM_COOKED_BEEF) return TEX_COOKED_BEEF;
  if (item == ITEM_FURNACE    ) return TEX_FURNACE_FRONT;
  return block_face_texture(item_places_block(item), DIR_PZ);
}

#endif
