#ifndef DROPS_H_INCLUDED
#define DROPS_H_INCLUDED

#include "config.h"

// ----------------------------------------------------------------
// Items lying in the world, waiting to be picked up
// ----------------------------------------------------------------

#define DROP_PICKUP_DELAY     0.5
#define DROP_PICKUP_DISTANCE  1.6
#define DROP_PULL_DISTANCE    2.6

/*Global variables*/ {
  Integer g_drop_used [MAX_DROPS];
  Integer g_drop_item [MAX_DROPS];
  Integer g_drop_count[MAX_DROPS];
  Real    g_drop_x    [MAX_DROPS];
  Real    g_drop_y    [MAX_DROPS];
  Real    g_drop_z    [MAX_DROPS];
  Real    g_drop_vx   [MAX_DROPS];
  Real    g_drop_vy   [MAX_DROPS];
  Real    g_drop_vz   [MAX_DROPS];
  Real    g_drop_age  [MAX_DROPS];
}

void    drops_clear   ();
Integer drops_spawn   (Integer item, Integer count, Real x, Real y, Real z);
void    drops_update  (Real dt);
void    drops_on_event();

#endif
