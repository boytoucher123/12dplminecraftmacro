#ifndef FURNACE_H_INCLUDED
#define FURNACE_H_INCLUDED

#include "config.h"
#include "records.h"

// ----------------------------------------------------------------
// Furnaces: each placed furnace has an input, fuel and output slot
// Burning fuel cooks one input item every COOK_SECONDS
// Furnaces keep working on real time, even while a screen is open
//
// All furnaces live in one record. Furnace f has the fields
// "used_f", "x_f", "y_f", "z_f", "burn_f", "burn_total_f" and
// "progress_f"; its three slots are container slots (inventory.h)
// number furnace_slot(f, FURNACE_SLOT_*) of the same record.
// ----------------------------------------------------------------

#define DATATYPE_FURNACES       ("furnaces")
#define ATTR_FURNACE_BURN       ("burn")
#define ATTR_FURNACE_BURN_TOTAL ("burn_total")
#define ATTR_FURNACE_PROGRESS   ("progress")
#define FURNACE_SLOT_INPUT      1
#define FURNACE_SLOT_FUEL       2
#define FURNACE_SLOT_OUTPUT     3
#define FURNACE_SLOTS           3

void    furnaces_clear        (Attributes &furnaces);
Integer furnace_slot          (Integer furnace, Integer which);
Integer furnace_used          (Attributes &furnaces, Integer furnace);
void    furnace_cell          (Attributes &furnaces, Integer furnace, Integer &x, Integer &y, Integer &z);
Real    furnace_burn_left     (Attributes &furnaces, Integer furnace);
Real    furnace_burn_total    (Attributes &furnaces, Integer furnace);
Real    furnace_progress      (Attributes &furnaces, Integer furnace);
void    furnace_set_state     (Attributes &furnaces, Integer furnace, Real burn_left, Real burn_total, Real progress);
Integer furnace_find          (Attributes &furnaces, Integer x, Integer y, Integer z);
Integer furnace_get_or_create (Attributes &furnaces, Integer x, Integer y, Integer z);
void    furnace_remove        (Attributes &furnaces, Attributes &events, Integer furnace);
Integer furnace_is_lit        (Attributes &furnaces, Integer x, Integer y, Integer z);
Integer furnace_can_cook      (Attributes &furnaces, Integer furnace);
void    furnace_step          (Attributes &furnaces, Integer furnace, Real dt);
void    furnaces_update       (Attributes &furnaces, Real dt);
void    furnace_on_event      (Attributes &event, Attributes &furnaces, Attributes &events);

#endif
