#ifndef COWS_H_INCLUDED
#define COWS_H_INCLUDED

#include "config.h"

// ----------------------------------------------------------------
// Cows: wander about on land, run off when hit and drop raw beef
// ----------------------------------------------------------------

#define COW_WALK_SPEED       1.1
#define COW_PANIC_SPEED      3.2
#define COW_JUMP_SPEED       7.6
#define COW_RESPAWN_SECONDS  25.0
#define COW_ACTIVE_DISTANCE  64.0

/*Global variables*/ {
  Integer g_cow_alive    [MAX_COWS];
  Real    g_cow_x        [MAX_COWS];
  Real    g_cow_y        [MAX_COWS];
  Real    g_cow_z        [MAX_COWS];
  Real    g_cow_vy       [MAX_COWS];
  Real    g_cow_push_x   [MAX_COWS];
  Real    g_cow_push_z   [MAX_COWS];
  Real    g_cow_yaw      [MAX_COWS];
  Real    g_cow_goal_yaw [MAX_COWS];
  Integer g_cow_health   [MAX_COWS];
  Integer g_cow_walking  [MAX_COWS];
  Real    g_cow_timer    [MAX_COWS];
  Real    g_cow_panic    [MAX_COWS];
  Real    g_cow_flash    [MAX_COWS];
  Real    g_cow_step     [MAX_COWS];   // leg swing phase
  Integer g_cow_on_ground[MAX_COWS];

  Real    g_cow_respawn_timer = 0.0;
}

void    cows_clear         ();
Integer cows_alive_count   ();
Integer cows_spawn         (Real x, Real y, Real z, Real yaw);
Integer cows_spawn_random  (Integer count, Real keep_away);
void    cows_update        (Real dt);
void    cow_update         (Integer cow, Real dt);
Integer cows_ray_hit       (Real origin_x, Real origin_y, Real origin_z, Real dir_x, Real dir_y, Real dir_z, Real max_distance);
void    cow_damage         (Integer cow, Integer amount, Real push_x, Real push_z);
Integer cows_box_overlaps  (Real min_x, Real min_y, Real min_z, Real max_x, Real max_y, Real max_z);

#endif
