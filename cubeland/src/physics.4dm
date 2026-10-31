#ifndef PHYSICS_4DM_INCLUDED
#define PHYSICS_4DM_INCLUDED

#include "../include/common.h"
#include "../include/config.h"
#include "../include/util.h"
#include "../include/blocks.h"
#include "../include/world.h"
#include "../include/physics.h"

Integer physics_box_collides(Real min_x, Real min_y, Real min_z, Real max_x, Real max_y, Real max_z)
// ----------------------------------------------------------------
// TRUE if any solid cell overlaps the box
// ----------------------------------------------------------------
{
  Integer x0 = Floor(min_x);
  Integer y0 = Floor(min_y);
  Integer z0 = Floor(min_z);
  Integer x1 = Floor(max_x - COLLISION_EPSILON * 0.1);
  Integer y1 = Floor(max_y - COLLISION_EPSILON * 0.1);
  Integer z1 = Floor(max_z - COLLISION_EPSILON * 0.1);
  Integer x  = 0;
  Integer y  = 0;
  Integer z  = 0;

  for (x = x0; x <= x1; ++x) {
    for (z = z0; z <= z1; ++z) {
      for (y = y0; y <= y1; ++y) {
        if (world_is_solid(x, y, z)) return TRUE;
      }
    }
  }
  return FALSE;
}

void physics_move_box(Real &x, Real &y, Real &z, Real half_width, Real height, Real dx, Real dy, Real dz)
// ----------------------------------------------------------------
// Move a box by (dx, dy, dz), one axis at a time (y, then x, then
// z) so it slides along walls. When an axis is blocked the box is
// pushed back to touch the blocking cell. Each step must be under
// one block; callers split long moves into steps of MAX_MOVE_STEP.
// Sets g_hit_x, g_hit_z, g_hit_down and g_hit_up.
// ----------------------------------------------------------------
{
  Real new_x = x;
  Real new_y = y;
  Real new_z = z;

  g_hit_x    = FALSE;
  g_hit_z    = FALSE;
  g_hit_down = FALSE;
  g_hit_up   = FALSE;

  if (dy != 0.0) {
    new_y = y + dy;
    if (physics_box_collides(x - half_width, new_y, z - half_width, x + half_width, new_y + height, z + half_width)) {
      if (dy < 0.0) {
        new_y      = Floor(new_y) + 1.0 + COLLISION_EPSILON;
        g_hit_down = TRUE;
      } else {
        new_y    = Floor(new_y + height) - height - COLLISION_EPSILON;
        g_hit_up = TRUE;
      }
      if (physics_box_collides(x - half_width, new_y, z - half_width, x + half_width, new_y + height, z + half_width)) {
        new_y = y;
      }
    }
    y = new_y;
  }

  if (dx != 0.0) {
    new_x = x + dx;
    if (physics_box_collides(new_x - half_width, y, z - half_width, new_x + half_width, y + height, z + half_width)) {
      if (dx < 0.0) {
        new_x = Floor(new_x - half_width) + 1.0 + half_width + COLLISION_EPSILON;
      } else {
        new_x = Floor(new_x + half_width) - half_width - COLLISION_EPSILON;
      }
      if (physics_box_collides(new_x - half_width, y, z - half_width, new_x + half_width, y + height, z + half_width)) {
        new_x = x;
      }
      g_hit_x = TRUE;
    }
    x = new_x;
  }

  if (dz != 0.0) {
    new_z = z + dz;
    if (physics_box_collides(x - half_width, y, new_z - half_width, x + half_width, y + height, new_z + half_width)) {
      if (dz < 0.0) {
        new_z = Floor(new_z - half_width) + 1.0 + half_width + COLLISION_EPSILON;
      } else {
        new_z = Floor(new_z + half_width) - half_width - COLLISION_EPSILON;
      }
      if (physics_box_collides(x - half_width, y, new_z - half_width, x + half_width, y + height, new_z + half_width)) {
        new_z = z;
      }
      g_hit_z = TRUE;
    }
    z = new_z;
  }
}

Integer physics_box_in_water(Real x, Real y, Real z, Real half_width, Real height)
// ----------------------------------------------------------------
// TRUE if the lower part of a box is in a water cell
// ----------------------------------------------------------------
{
  Integer cell_x = Floor(x);
  Integer cell_y = Floor(y + height * 0.3);
  Integer cell_z = Floor(z);

  if (world_get_block(cell_x, cell_y, cell_z) == BLOCK_WATER) return TRUE;
  return FALSE;
}

Integer physics_raycast_blocks(Real origin_x, Real origin_y, Real origin_z, Real dir_x, Real dir_y, Real dir_z, Real max_distance)
// ----------------------------------------------------------------
// Walk a ray through the grid cell by cell (3D DDA) and stop at the
// first block that is neither air nor water. dir must be a unit
// vector. Returns TRUE on a hit within max_distance and sets
// g_ray_x/y/z (the cell), g_ray_normal_* (the face that was hit)
// and g_ray_distance.
// ----------------------------------------------------------------
{
  Integer cell_x     = Floor(origin_x);
  Integer cell_y     = Floor(origin_y);
  Integer cell_z     = Floor(origin_z);
  Integer step_x     = 1;
  Integer step_y     = 1;
  Integer step_z     = 1;
  Real    delta_x    = 1000000.0;
  Real    delta_y    = 1000000.0;
  Real    delta_z    = 1000000.0;
  Real    next_x     = 1000000.0;
  Real    next_y     = 1000000.0;
  Real    next_z     = 1000000.0;
  Real    travelled  = 0.0;
  Integer normal_x   = 0;
  Integer normal_y   = 0;
  Integer normal_z   = 0;
  Integer block      = 0;
  Integer guard      = 0;

  if (dir_x != 0.0) delta_x = Absolute(1.0 / dir_x);
  if (dir_y != 0.0) delta_y = Absolute(1.0 / dir_y);
  if (dir_z != 0.0) delta_z = Absolute(1.0 / dir_z);

  if (dir_x < 0.0) {
    step_x = -1;
    next_x = (origin_x - cell_x) * delta_x;
  } else {
    next_x = (cell_x + 1.0 - origin_x) * delta_x;
  }
  if (dir_y < 0.0) {
    step_y = -1;
    next_y = (origin_y - cell_y) * delta_y;
  } else {
    next_y = (cell_y + 1.0 - origin_y) * delta_y;
  }
  if (dir_z < 0.0) {
    step_z = -1;
    next_z = (origin_z - cell_z) * delta_z;
  } else {
    next_z = (cell_z + 1.0 - origin_z) * delta_z;
  }

  while (guard < 64) {
    ++guard;

    block = world_get_block(cell_x, cell_y, cell_z);
    if (block != BLOCK_AIR && block != BLOCK_WATER && world_in_bounds(cell_x, cell_y, cell_z)) {
      g_ray_x        = cell_x;
      g_ray_y        = cell_y;
      g_ray_z        = cell_z;
      g_ray_normal_x = normal_x;
      g_ray_normal_y = normal_y;
      g_ray_normal_z = normal_z;
      g_ray_distance = travelled;
      return TRUE;
    }

    normal_x = 0;
    normal_y = 0;
    normal_z = 0;
    if (next_x <= next_y && next_x <= next_z) {
      travelled = next_x;
      next_x    = next_x + delta_x;
      cell_x    = cell_x + step_x;
      normal_x  = -step_x;
    } else if (next_y <= next_z) {
      travelled = next_y;
      next_y    = next_y + delta_y;
      cell_y    = cell_y + step_y;
      normal_y  = -step_y;
    } else {
      travelled = next_z;
      next_z    = next_z + delta_z;
      cell_z    = cell_z + step_z;
      normal_z  = -step_z;
    }

    if (travelled > max_distance) return FALSE;
  }
  return FALSE;
}

Real physics_ray_box(Real origin_x, Real origin_y, Real origin_z, Real dir_x, Real dir_y, Real dir_z,
                     Real min_x, Real min_y, Real min_z, Real max_x, Real max_y, Real max_z)
// ----------------------------------------------------------------
// Distance along a ray to where it enters a box (slab method)
// Returns -1 if the ray misses or the box is behind the origin
// ----------------------------------------------------------------
{
  Real enter = -1000000.0;
  Real leave =  1000000.0;
  Real t0    = 0.0;
  Real t1    = 0.0;
  Real swap  = 0.0;

  if (dir_x == 0.0) {
    if (origin_x < min_x || origin_x > max_x) return -1.0;
  } else {
    t0 = (min_x - origin_x) / dir_x;
    t1 = (max_x - origin_x) / dir_x;
    if (t0 > t1) {
      swap = t0;
      t0   = t1;
      t1   = swap;
    }
    enter = max_real(enter, t0);
    leave = min_real(leave, t1);
  }

  if (dir_y == 0.0) {
    if (origin_y < min_y || origin_y > max_y) return -1.0;
  } else {
    t0 = (min_y - origin_y) / dir_y;
    t1 = (max_y - origin_y) / dir_y;
    if (t0 > t1) {
      swap = t0;
      t0   = t1;
      t1   = swap;
    }
    enter = max_real(enter, t0);
    leave = min_real(leave, t1);
  }

  if (dir_z == 0.0) {
    if (origin_z < min_z || origin_z > max_z) return -1.0;
  } else {
    t0 = (min_z - origin_z) / dir_z;
    t1 = (max_z - origin_z) / dir_z;
    if (t0 > t1) {
      swap = t0;
      t0   = t1;
      t1   = swap;
    }
    enter = max_real(enter, t0);
    leave = min_real(leave, t1);
  }

  if (enter > leave || leave < 0.0) return -1.0;
  if (enter < 0.0) return 0.0;
  return enter;
}

#endif
