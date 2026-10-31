#ifndef FURNACE_H_INCLUDED
#define FURNACE_H_INCLUDED

#include "config.h"

// ----------------------------------------------------------------
// Furnaces: each placed furnace has an input, fuel and output slot
// Burning fuel cooks one input item every COOK_SECONDS
// Furnaces keep working on real time, even while a screen is open
// ----------------------------------------------------------------

#define FURNACE_SLOT_INPUT   1
#define FURNACE_SLOT_FUEL    2
#define FURNACE_SLOT_OUTPUT  3

/*Global variables*/ {
  Integer g_furnace_used      [MAX_FURNACES];
  Integer g_furnace_x         [MAX_FURNACES];
  Integer g_furnace_y         [MAX_FURNACES];
  Integer g_furnace_z         [MAX_FURNACES];
  Integer g_furnace_in_item   [MAX_FURNACES];
  Integer g_furnace_in_count  [MAX_FURNACES];
  Integer g_furnace_fuel_item [MAX_FURNACES];
  Integer g_furnace_fuel_count[MAX_FURNACES];
  Integer g_furnace_out_item  [MAX_FURNACES];
  Integer g_furnace_out_count [MAX_FURNACES];
  Real    g_furnace_burn_left [MAX_FURNACES];
  Real    g_furnace_burn_total[MAX_FURNACES];
  Real    g_furnace_progress  [MAX_FURNACES];
}

void    furnaces_clear        ();
Integer furnace_find          (Integer x, Integer y, Integer z);
Integer furnace_get_or_create (Integer x, Integer y, Integer z);
void    furnace_remove        (Integer furnace);
Integer furnace_is_lit        (Integer x, Integer y, Integer z);
Integer furnace_can_cook      (Integer furnace);
void    furnace_step          (Integer furnace, Real dt);
void    furnaces_update       (Real dt);
void    furnace_get_slot      (Integer furnace, Integer slot);
void    furnace_set_slot      (Integer furnace, Integer slot);
void    furnace_on_event      ();

#endif
