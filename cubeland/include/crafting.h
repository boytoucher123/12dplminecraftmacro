#ifndef CRAFTING_H_INCLUDED
#define CRAFTING_H_INCLUDED

// ----------------------------------------------------------------
// Recipes
// Crafting is picked from a list rather than laid out in a grid:
// each recipe takes up to two kinds of ingredient. Hand recipes can
// be made from the inventory screen, the rest need a crafting table.
// ----------------------------------------------------------------

#define MAX_RECIPES        8
#define RECIPE_INPUTS      2
#define RECIPE_INPUT_SLOTS 16   // MAX_RECIPES * RECIPE_INPUTS

/*Global variables*/ {
  Integer g_recipe_count = 0;
  Integer g_recipe_output      [MAX_RECIPES];
  Integer g_recipe_output_count[MAX_RECIPES];
  Integer g_recipe_needs_table [MAX_RECIPES];
  Integer g_recipe_input       [RECIPE_INPUT_SLOTS];
  Integer g_recipe_input_count [RECIPE_INPUT_SLOTS];
}

void    crafting_init         ();
void    crafting_add_recipe   (Integer output, Integer output_count, Integer needs_table,
                               Integer input_1, Integer count_1, Integer input_2, Integer count_2);
Integer crafting_input_slot   (Integer recipe, Integer which);
Integer crafting_can_craft    (Integer recipe);
Integer crafting_craft        (Integer recipe, Real drop_x, Real drop_y, Real drop_z);
Text    crafting_describe     (Integer recipe);

#endif
