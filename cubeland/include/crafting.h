#ifndef CRAFTING_H_INCLUDED
#define CRAFTING_H_INCLUDED

#include "records.h"

// ----------------------------------------------------------------
// Shaped crafting
//
// Items are laid out in a crafting grid: 2 x 2 in the inventory
// screen, 3 x 3 at a crafting table. The grid is a container record
// (see inventory.h) with slots 1..9 numbered row by row and a
// "width" field (2 or 3); with width 2 only slots 1, 2, 4, 5 are
// used, so the numbering is the same for both sizes.
//
// The recipe book is a record too. Recipe r has fields
// "output_r", "output_count_r", "width_r", "height_r" and its
// pattern cells "cell_r_1".."cell_r_9" (row by row, width_r cells
// per row, ITEM_NONE for a gap). A pattern can sit anywhere in the
// grid and may be mirrored left to right.
// ----------------------------------------------------------------

#define DATATYPE_RECIPE_BOOK  ("recipe_book")
#define DATATYPE_CRAFT_GRID   ("craft_grid")
#define ATTR_RECIPE_OUTPUT    ("output")
#define ATTR_RECIPE_OUT_COUNT ("output_count")
#define ATTR_RECIPE_WIDTH     ("width")
#define ATTR_RECIPE_HEIGHT    ("height")
#define ATTR_RECIPE_CELL      ("cell")
#define ATTR_GRID_WIDTH       ("width")
#define GRID_SLOTS            9
#define GRID_INVENTORY_WIDTH  2
#define GRID_TABLE_WIDTH      3

void    crafting_init_book    (Attributes &book);
void    crafting_add_recipe   (Attributes &book, Integer output, Integer output_count,
                               Integer width, Integer height, Text pattern, Integer item_a, Integer item_b);
Integer crafting_recipe_count (Attributes &book);
Integer crafting_recipe_output(Attributes &book, Integer recipe);
Integer crafting_recipe_cell  (Attributes &book, Integer recipe, Integer column, Integer row);

void    grid_clear            (Attributes &grid, Integer width);
Integer grid_width            (Attributes &grid);
Integer grid_slot             (Integer column, Integer row);
Integer grid_slot_used        (Attributes &grid, Integer slot);
Integer crafting_match        (Attributes &book, Attributes &grid);
Integer crafting_match_at     (Attributes &book, Integer recipe, Attributes &grid,
                               Integer left, Integer top, Integer mirrored);
Integer crafting_take_output  (Attributes &book, Attributes &grid, Attributes &holder, Attributes &events);
void    grid_return_items     (Attributes &grid, Attributes &inventory, Attributes &events, Real x, Real y, Real z);

#endif
