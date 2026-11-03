#ifndef BLOCKS_4DM_INCLUDED
#define BLOCKS_4DM_INCLUDED

#include "../include/common.h"
#include "../include/blocks.h"
#include "../include/textures.h"

// ---------------------------------------------------------------- blocks

Integer block_is_solid(Integer block)
// ----------------------------------------------------------------
// TRUE for blocks that stop movement and hide the faces behind them
// ----------------------------------------------------------------
{
  if (block == BLOCK_AIR   ) return FALSE;
  if (block == BLOCK_WATER ) return FALSE;
  if (block_is_plant(block)) return FALSE;
  return TRUE;
}

Integer block_is_plant(Integer block)
// ----------------------------------------------------------------
// TRUE for grass tufts, flowers and dead bushes
// ----------------------------------------------------------------
{
  if (block >= BLOCK_TALL_GRASS && block <= BLOCK_DEAD_BUSH) return TRUE;
  return FALSE;
}

Integer block_hides_faces(Integer block)
// ----------------------------------------------------------------
// TRUE if a block hides the faces of the blocks next to it (water
// is handled separately: faces against water are drawn only when
// the camera is under water)
// ----------------------------------------------------------------
{
  return block_is_solid(block);
}

Integer block_plant_texture(Integer block)
// ----------------------------------------------------------------
// Sprite drawn for a plant block, 0 if it isn't a plant
// ----------------------------------------------------------------
{
  if (block == BLOCK_TALL_GRASS) return TEX_PLANT_GRASS;
  if (block == BLOCK_POPPY     ) return TEX_PLANT_POPPY;
  if (block == BLOCK_DANDELION ) return TEX_PLANT_DANDELION;
  if (block == BLOCK_DEAD_BUSH ) return TEX_PLANT_DEAD_BUSH;
  return 0;
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

Integer block_falls(Integer block)
// ----------------------------------------------------------------
// TRUE for blocks that fall when there is nothing under them
// ----------------------------------------------------------------
{
  if (block == BLOCK_SAND  ) return TRUE;
  if (block == BLOCK_GRAVEL) return TRUE;
  return FALSE;
}

Integer block_hand_hits(Integer block)
// ----------------------------------------------------------------
// Number of hits to break a block with an empty hand (or the wrong
// tool), 0 means unbreakable
// ----------------------------------------------------------------
{
  if (block == BLOCK_BEDROCK       ) return 0;
  if (block == BLOCK_WATER         ) return 0;
  if (block == BLOCK_AIR           ) return 0;
  if (block_is_plant(block)       ) return 1;
  if (block == BLOCK_LEAVES        ) return 1;
  if (block == BLOCK_CACTUS        ) return 1;
  if (block == BLOCK_DIRT          ) return 2;
  if (block == BLOCK_GRASS         ) return 2;
  if (block == BLOCK_SAND          ) return 2;
  if (block == BLOCK_GRAVEL        ) return 3;
  if (block == BLOCK_OAK_LOG       ) return 4;
  if (block == BLOCK_PLANKS        ) return 4;
  if (block == BLOCK_CRAFTING_TABLE) return 4;
  if (block == BLOCK_SANDSTONE     ) return 6;
  if (block == BLOCK_COAL_ORE      ) return 10;
  return 8;
}

Integer block_tool_kind(Integer block)
// ----------------------------------------------------------------
// The tool that breaks a block faster (TOOL_*)
// ----------------------------------------------------------------
{
  if (block == BLOCK_DIRT          ) return TOOL_SHOVEL;
  if (block == BLOCK_GRASS         ) return TOOL_SHOVEL;
  if (block == BLOCK_SAND          ) return TOOL_SHOVEL;
  if (block == BLOCK_GRAVEL        ) return TOOL_SHOVEL;
  if (block == BLOCK_OAK_LOG       ) return TOOL_AXE;
  if (block == BLOCK_PLANKS        ) return TOOL_AXE;
  if (block == BLOCK_CRAFTING_TABLE) return TOOL_AXE;
  if (block == BLOCK_STONE         ) return TOOL_PICKAXE;
  if (block == BLOCK_COBBLESTONE   ) return TOOL_PICKAXE;
  if (block == BLOCK_SANDSTONE     ) return TOOL_PICKAXE;
  if (block == BLOCK_COAL_ORE      ) return TOOL_PICKAXE;
  if (block_is_furnace(block)      ) return TOOL_PICKAXE;
  return TOOL_NONE;
}

Integer block_needs_tool(Integer block)
// ----------------------------------------------------------------
// TRUE for blocks that drop nothing unless broken with their tool
// (stone and everything made of it needs a pickaxe)
// ----------------------------------------------------------------
{
  if (block_tool_kind(block) == TOOL_PICKAXE) return TRUE;
  return FALSE;
}

Integer block_hits_with(Integer block, Integer tool_item)
// ----------------------------------------------------------------
// Number of hits to break a block holding tool_item
// The right tool divides the hand hits by 2 (wood) or 3 (stone)
// ----------------------------------------------------------------
{
  Integer hits  = block_hand_hits(block);
  Integer speed = 1;

  if (hits <= 0) return 0;

  if (item_tool_kind(tool_item) == block_tool_kind(block)) {
    if (item_tool_tier(tool_item) == TIER_WOOD ) speed = 3;
    if (item_tool_tier(tool_item) == TIER_STONE) speed = 4;
  }

  hits = Floor((hits + speed - 1.0) / speed);
  if (hits < 1) hits = 1;

  return hits;
}

Integer block_drop_item(Integer block, Integer tool_item)
// ----------------------------------------------------------------
// Item left behind when a block is broken while holding tool_item,
// ITEM_NONE for nothing
// ----------------------------------------------------------------
{
  if (block_needs_tool(block)) {
    if (item_tool_kind(tool_item) != block_tool_kind(block)) return ITEM_NONE;
  }

  if (block == BLOCK_GRASS   ) return ITEM_DIRT;
  if (block == BLOCK_STONE   ) return ITEM_COBBLESTONE;
  if (block == BLOCK_COAL_ORE) return ITEM_COAL;
  if (block == BLOCK_LEAVES  ) return ITEM_NONE;
  if (block == BLOCK_TALL_GRASS) return ITEM_NONE;
  if (block == BLOCK_DEAD_BUSH ) return ITEM_STICK;
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
  if (block == BLOCK_COAL_ORE   ) return TEX_COAL_ORE;
  if (block == BLOCK_GRAVEL     ) return TEX_GRAVEL;

  if (block == BLOCK_GRASS) {
    if (direction == DIR_PY) return TEX_GRASS_TOP;
    if (direction == DIR_NY) return TEX_DIRT;
    return TEX_GRASS_SIDE;
  }
  if (block == BLOCK_OAK_LOG) {
    if (direction == DIR_PY || direction == DIR_NY) return TEX_LOG_TOP;
    return TEX_LOG_SIDE;
  }
  if (block == BLOCK_SANDSTONE) {
    if (direction == DIR_PY || direction == DIR_NY) return TEX_SANDSTONE_TOP;
    return TEX_SANDSTONE_SIDE;
  }
  if (block == BLOCK_CACTUS) {
    if (direction == DIR_PY || direction == DIR_NY) return TEX_CACTUS_TOP;
    return TEX_CACTUS_SIDE;
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

// ---------------------------------------------------------------- items

Text item_name(Integer item)
// ----------------------------------------------------------------
// Display name of an item
// ----------------------------------------------------------------
{
  if (item == ITEM_BEDROCK        ) return "Bedrock";
  if (item == ITEM_STONE          ) return "Stone";
  if (item == ITEM_COBBLESTONE    ) return "Cobblestone";
  if (item == ITEM_DIRT           ) return "Dirt";
  if (item == ITEM_GRASS          ) return "Grass Block";
  if (item == ITEM_OAK_LOG        ) return "Oak Log";
  if (item == ITEM_LEAVES         ) return "Oak Leaves";
  if (item == ITEM_PLANKS         ) return "Oak Planks";
  if (item == ITEM_CRAFTING_TABLE ) return "Crafting Table";
  if (item == ITEM_FURNACE        ) return "Furnace";
  if (item == ITEM_SAND           ) return "Sand";
  if (item == ITEM_SANDSTONE      ) return "Sandstone";
  if (item == ITEM_CACTUS         ) return "Cactus";
  if (item == ITEM_COAL_ORE       ) return "Coal Ore";
  if (item == ITEM_GRAVEL         ) return "Gravel";
  if (item == ITEM_POPPY          ) return "Poppy";
  if (item == ITEM_DANDELION      ) return "Dandelion";
  if (item == ITEM_STICK          ) return "Stick";
  if (item == ITEM_RAW_BEEF       ) return "Raw Beef";
  if (item == ITEM_COOKED_BEEF    ) return "Cooked Beef";
  if (item == ITEM_COAL           ) return "Coal";
  if (item == ITEM_WOODEN_PICKAXE ) return "Wooden Pickaxe";
  if (item == ITEM_STONE_PICKAXE  ) return "Stone Pickaxe";
  if (item == ITEM_WOODEN_AXE     ) return "Wooden Axe";
  if (item == ITEM_STONE_AXE      ) return "Stone Axe";
  if (item == ITEM_WOODEN_SHOVEL  ) return "Wooden Shovel";
  if (item == ITEM_STONE_SHOVEL   ) return "Stone Shovel";
  if (item == ITEM_WOODEN_SWORD   ) return "Wooden Sword";
  if (item == ITEM_STONE_SWORD    ) return "Stone Sword";
  return "";
}

Integer item_places_block(Integer item)
// ----------------------------------------------------------------
// Block an item places, BLOCK_AIR if it cannot be placed
// Furnaces are turned to face the player when placed
// ----------------------------------------------------------------
{
  if (item < ITEM_BEDROCK   ) return BLOCK_AIR;
  if (item > MAX_BLOCK_ID   ) return BLOCK_AIR;
  if (item == BLOCK_WATER   ) return BLOCK_AIR;
  if (item >  ITEM_FURNACE && item <= BLOCK_FURNACE_NZ) return BLOCK_AIR;
  if (item == BLOCK_TALL_GRASS) return BLOCK_AIR;
  if (item == BLOCK_DEAD_BUSH ) return BLOCK_AIR;
  return item;
}

Integer item_is_block(Integer item)
// ----------------------------------------------------------------
// TRUE if the item is drawn as a little cube
// ----------------------------------------------------------------
{
  if (block_is_plant(item)) return FALSE;
  if (item_places_block(item) != BLOCK_AIR) return TRUE;
  return FALSE;
}

Integer item_max_stack(Integer item)
// ----------------------------------------------------------------
// How many of an item fit in one slot (tools don't stack)
// ----------------------------------------------------------------
{
  if (item_tool_kind(item) != TOOL_NONE) return 1;
  return MAX_STACK;
}

Integer item_tool_kind(Integer item)
// ----------------------------------------------------------------
// TOOL_* kind of a tool item, TOOL_NONE for everything else
// ----------------------------------------------------------------
{
  if (item == ITEM_WOODEN_PICKAXE || item == ITEM_STONE_PICKAXE) return TOOL_PICKAXE;
  if (item == ITEM_WOODEN_AXE     || item == ITEM_STONE_AXE    ) return TOOL_AXE;
  if (item == ITEM_WOODEN_SHOVEL  || item == ITEM_STONE_SHOVEL ) return TOOL_SHOVEL;
  if (item == ITEM_WOODEN_SWORD   || item == ITEM_STONE_SWORD  ) return TOOL_SWORD;
  return TOOL_NONE;
}

Integer item_tool_tier(Integer item)
// ----------------------------------------------------------------
// TIER_WOOD or TIER_STONE for tools, TIER_NONE otherwise
// ----------------------------------------------------------------
{
  if (item == ITEM_WOODEN_PICKAXE || item == ITEM_WOODEN_AXE ) return TIER_WOOD;
  if (item == ITEM_WOODEN_SHOVEL  || item == ITEM_WOODEN_SWORD) return TIER_WOOD;
  if (item == ITEM_STONE_PICKAXE  || item == ITEM_STONE_AXE  ) return TIER_STONE;
  if (item == ITEM_STONE_SHOVEL   || item == ITEM_STONE_SWORD ) return TIER_STONE;
  return TIER_NONE;
}

Integer item_max_uses(Integer item)
// ----------------------------------------------------------------
// Number of uses before a tool breaks, 0 for items that don't wear
// ----------------------------------------------------------------
{
  if (item_tool_tier(item) == TIER_WOOD ) return 60;
  if (item_tool_tier(item) == TIER_STONE) return 132;
  return 0;
}

Integer item_attack_damage(Integer item)
// ----------------------------------------------------------------
// Damage done to a cow when hitting it while holding item
// ----------------------------------------------------------------
{
  Integer kind = item_tool_kind(item);
  Integer tier = item_tool_tier(item);

  if (kind == TOOL_SWORD) return 2 + tier;
  if (kind == TOOL_AXE  ) return 1 + tier;
  if (kind != TOOL_NONE ) return 2;
  return 1;
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
  if (item == ITEM_COAL          ) return 40;
  if (item == ITEM_OAK_LOG       ) return 20;
  if (item == ITEM_PLANKS        ) return 10;
  if (item == ITEM_CRAFTING_TABLE) return 15;
  if (item == ITEM_STICK         ) return 5;
  if (item_tool_tier(item) == TIER_WOOD) return 10;
  return 0;
}

Integer item_smelt_result(Integer item)
// ----------------------------------------------------------------
// What a furnace turns an item into, ITEM_NONE if it cannot
// ----------------------------------------------------------------
{
  if (item == ITEM_RAW_BEEF   ) return ITEM_COOKED_BEEF;
  if (item == ITEM_COBBLESTONE) return ITEM_STONE;
  if (item == ITEM_SAND       ) return ITEM_SANDSTONE;
  if (item == ITEM_OAK_LOG    ) return ITEM_COAL;
  return ITEM_NONE;
}

Integer item_top_texture(Integer item)
// ----------------------------------------------------------------
// Texture for the top of a block item's cube
// ----------------------------------------------------------------
{
  if (item == ITEM_FURNACE) return TEX_FURNACE_TOP;
  return block_face_texture(item_places_block(item), DIR_PY);
}

Integer item_side_texture(Integer item)
// ----------------------------------------------------------------
// Texture for the sides of a block item's cube
// ----------------------------------------------------------------
{
  if (item == ITEM_FURNACE) return TEX_FURNACE_FRONT;
  return block_face_texture(item_places_block(item), DIR_PZ);
}

Integer item_sprite_texture(Integer item)
// ----------------------------------------------------------------
// Flat 16 x 16 picture of an item that is not a block (drawn as a
// sprite in slots, in the hand and when dropped), 0 for blocks
// ----------------------------------------------------------------
{
  if (item == ITEM_STICK         ) return TEX_ITEM_STICK;
  if (item == ITEM_RAW_BEEF      ) return TEX_ITEM_RAW_BEEF;
  if (item == ITEM_COOKED_BEEF   ) return TEX_ITEM_COOKED_BEEF;
  if (item == ITEM_COAL          ) return TEX_ITEM_COAL;
  if (item == ITEM_WOODEN_PICKAXE) return TEX_ITEM_WOODEN_PICKAXE;
  if (item == ITEM_STONE_PICKAXE ) return TEX_ITEM_STONE_PICKAXE;
  if (item == ITEM_WOODEN_AXE    ) return TEX_ITEM_WOODEN_AXE;
  if (item == ITEM_STONE_AXE     ) return TEX_ITEM_STONE_AXE;
  if (item == ITEM_WOODEN_SHOVEL ) return TEX_ITEM_WOODEN_SHOVEL;
  if (item == ITEM_STONE_SHOVEL  ) return TEX_ITEM_STONE_SHOVEL;
  if (item == ITEM_WOODEN_SWORD  ) return TEX_ITEM_WOODEN_SWORD;
  if (item == ITEM_STONE_SWORD   ) return TEX_ITEM_STONE_SWORD;
  return block_plant_texture(item);
}

#endif
