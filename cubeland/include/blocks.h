#ifndef BLOCKS_H_INCLUDED
#define BLOCKS_H_INCLUDED

// ----------------------------------------------------------------
// Block, item and face direction identifiers, and the rules that
// go with them (hardness, tools, drops, food, fuel, smelting)
// Items 1..63 are the blocks of the same number, 64+ are items that
// cannot be placed. Every function here is honest: it only looks
// at its arguments (and the finished texture numbers).
// ----------------------------------------------------------------

#define BLOCK_AIR             0
#define BLOCK_BEDROCK         1
#define BLOCK_STONE           2
#define BLOCK_COBBLESTONE     3
#define BLOCK_DIRT            4
#define BLOCK_GRASS           5
#define BLOCK_OAK_LOG         6
#define BLOCK_LEAVES          7
#define BLOCK_WATER           8
#define BLOCK_PLANKS          9
#define BLOCK_CRAFTING_TABLE  10
#define BLOCK_FURNACE_PX      11   // furnace with its door facing +x
#define BLOCK_FURNACE_NX      12   //                              -x
#define BLOCK_FURNACE_PZ      13   //                              +z
#define BLOCK_FURNACE_NZ      14   //                              -z
#define BLOCK_SAND            15
#define BLOCK_SANDSTONE       16
#define BLOCK_CACTUS          17
#define BLOCK_COAL_ORE        18
#define BLOCK_GRAVEL          19
#define BLOCK_TALL_GRASS      20   // plants: drawn as one picture that
#define BLOCK_POPPY           21   // faces the camera, nothing collides
#define BLOCK_DANDELION       22   // with them and placing a block
#define BLOCK_DEAD_BUSH       23   // replaces them
#define MAX_BLOCK_ID          23

#define ITEM_NONE             0
#define ITEM_BEDROCK          1
#define ITEM_STONE            2
#define ITEM_COBBLESTONE      3
#define ITEM_DIRT             4
#define ITEM_GRASS            5
#define ITEM_OAK_LOG          6
#define ITEM_LEAVES           7
#define ITEM_PLANKS           9
#define ITEM_CRAFTING_TABLE   10
#define ITEM_FURNACE          11
#define ITEM_SAND             15
#define ITEM_SANDSTONE        16
#define ITEM_CACTUS           17
#define ITEM_COAL_ORE         18
#define ITEM_GRAVEL           19
#define ITEM_POPPY            21
#define ITEM_DANDELION        22
#define FIRST_PURE_ITEM       64   // items from here on are not blocks
#define ITEM_STICK            64
#define ITEM_RAW_BEEF         65
#define ITEM_COOKED_BEEF      66
#define ITEM_COAL             67
#define ITEM_WOODEN_PICKAXE   68
#define ITEM_STONE_PICKAXE    69
#define ITEM_WOODEN_AXE       70
#define ITEM_STONE_AXE        71
#define ITEM_WOODEN_SHOVEL    72
#define ITEM_STONE_SHOVEL     73
#define ITEM_WOODEN_SWORD     74
#define ITEM_STONE_SWORD      75
#define MAX_ITEM_ID           75

// Tool kinds and tiers
#define TOOL_NONE             0
#define TOOL_PICKAXE          1
#define TOOL_AXE              2
#define TOOL_SHOVEL           3
#define TOOL_SWORD            4
#define TIER_NONE             0
#define TIER_WOOD             1
#define TIER_STONE            2

// Face directions (outward normal of a block face)
#define DIR_PX                1
#define DIR_NX                2
#define DIR_PY                3
#define DIR_NY                4
#define DIR_PZ                5
#define DIR_NZ                6
#define DIR_PLANT             7    // a plant picture (not a cube face)
#define NUM_FACE_GROUPS       7
#define DIR_WET_FLAG          8    // added to a face that touches water

Integer block_is_solid       (Integer block);
Integer block_is_plant       (Integer block);
Integer block_hides_faces    (Integer block);
Integer block_is_furnace     (Integer block);
Integer block_furnace_front  (Integer block);
Integer block_falls          (Integer block);
Integer block_hand_hits      (Integer block);
Integer block_tool_kind      (Integer block);
Integer block_needs_tool     (Integer block);
Integer block_hits_with      (Integer block, Integer tool_item);
Integer block_drop_item      (Integer block, Integer tool_item);
Integer block_face_texture   (Integer block, Integer direction);
Real    block_face_shade     (Integer direction);
Text    item_name            (Integer item);
Integer item_places_block    (Integer item);
Integer item_is_block        (Integer item);
Integer item_max_stack       (Integer item);
Integer item_tool_kind       (Integer item);
Integer item_tool_tier       (Integer item);
Integer item_max_uses        (Integer item);
Integer item_attack_damage   (Integer item);
Integer item_food_value      (Integer item);
Integer item_fuel_seconds    (Integer item);
Integer item_smelt_result    (Integer item);
Integer item_top_texture     (Integer item);
Integer item_side_texture    (Integer item);
Integer item_sprite_texture  (Integer item);
Integer block_plant_texture  (Integer block);

#endif
