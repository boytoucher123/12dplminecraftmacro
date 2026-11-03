#ifndef DROPS_H_INCLUDED
#define DROPS_H_INCLUDED

#include "config.h"
#include "records.h"

// ----------------------------------------------------------------
// Items lying in the world, waiting to be picked up
//
// All drops live in one record. Drop d has the fields "used_d",
// "item_d", "count_d", "damage_d" (tool wear), "x_d", "y_d", "z_d",
// "vx_d", "vy_d", "vz_d" and "age_d".
// ----------------------------------------------------------------

#define DROP_PICKUP_DELAY     0.5
#define DROP_PICKUP_DISTANCE  1.6
#define DROP_PULL_DISTANCE    2.6
#define DATATYPE_DROPS        ("drops")

void    drops_clear    (Attributes &drops);
Integer drop_used      (Attributes &drops, Integer drop);
Integer drop_item      (Attributes &drops, Integer drop);
Integer drop_count     (Attributes &drops, Integer drop);
Integer drop_damage    (Attributes &drops, Integer drop);
Real    drop_age       (Attributes &drops, Integer drop);
void    drop_position  (Attributes &drops, Integer drop, Real &x, Real &y, Real &z);
Integer drops_spawn    (Attributes &drops, Attributes &random, Integer item, Integer count, Integer damage, Real x, Real y, Real z);
Integer drops_restore  (Attributes &drops, Integer item, Integer count, Integer damage, Real x, Real y, Real z, Real age);
void    drops_update   (Attributes &drops, Attributes &inventory, Attributes &events,
                        Real player_x, Real player_y, Real player_z, Integer player_dead, Real dt);
void    drops_on_event (Attributes &event, Attributes &drops, Attributes &random);

#endif
