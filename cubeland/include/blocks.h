#ifndef BLOCKS_H_INCLUDED
#define BLOCKS_H_INCLUDED

// ----------------------------------------------------------------
// Block, item and face direction identifiers
// Items 1..15 are the blocks of the same number, 20+ are items
// that cannot be placed
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
#define ITEM_STICK            20
#define ITEM_RAW_BEEF         21
#define ITEM_COOKED_BEEF      22
#define MAX_ITEM_ID           22

// Face directions (outward normal of a block face)
#define DIR_PX                1
#define DIR_NX                2
#define DIR_PY                3
#define DIR_NY                4
#define DIR_PZ                5
#define DIR_NZ                6
#define DIR_WET_FLAG          8    // added to a face that touches water

Integer block_is_solid      (Integer block);
Integer block_is_furnace    (Integer block);
Integer block_furnace_front (Integer block);
Integer block_hardness      (Integer block);
Integer block_drop_item     (Integer block);
Integer block_face_texture  (Integer block, Integer direction);
Real    block_face_shade    (Integer direction);
Text    item_name           (Integer item);
Integer item_places_block   (Integer item);
Integer item_is_block       (Integer item);
Integer item_food_value     (Integer item);
Integer item_fuel_seconds   (Integer item);
Integer item_smelt_result   (Integer item);
Integer item_top_texture    (Integer item);
Integer item_side_texture   (Integer item);

#endif
