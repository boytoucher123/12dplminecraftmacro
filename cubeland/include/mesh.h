#ifndef MESH_H_INCLUDED
#define MESH_H_INCLUDED

#include "config.h"
#include "records.h"

// ----------------------------------------------------------------
// Cached lists of visible block faces
// The world is split into 16 x 16 x 16 sections. Each section keeps
// the faces of its blocks that touch air (or water), so drawing a
// frame only walks those lists instead of the whole world. A
// section is rebuilt when a block in or beside it changes. Plants
// are stored as one DIR_PLANT entry each.
//
// Every face also stores a light level (0..100) worked out when the
// section is built: daylight fades with depth below the column's
// sky top (caves, overhangs, under trees) and each face is darkened
// by the solid blocks around the cell in front of it (corners and
// creases look shaded).
//
// Table functions: everything here; they read the block grid and
// own the face pool.
// ----------------------------------------------------------------

#define SECTION_UNBUILT  0
#define SECTION_BUILT    1
#define SECTION_DIRTY    2
#define LAYER_KEYS         112    // NUM_FACE_GROUPS * SECTION_SIZE
#define SECTION_LAYER_SLOTS 113   // LAYER_KEYS + 1 (the end marker)
#define SECTION_LAYER_TABLE 43392 // NUM_SECTIONS * SECTION_LAYER_SLOTS
#define LIGHT_FULL         100
#define LIGHT_MIN          45
#define LIGHT_DEPTH_STEP   6      // light lost per block below the sky top
#define LIGHT_AO_STRENGTH  35     // percent lost when fully enclosed
#define FACE_TORCH_SCALE   1000   // g_face_light = sky + FACE_TORCH_SCALE * torch light

/*Global variables*/ {
  Integer g_section_state[NUM_SECTIONS];
  Integer g_section_count[NUM_SECTIONS];

  // Face pool: section s owns entries (s - 1) * SECTION_FACE_CAP + 1 ...
  Integer g_face_x  [FACE_POOL_SIZE];
  Integer g_face_y  [FACE_POOL_SIZE];
  Integer g_face_z  [FACE_POOL_SIZE];
  Integer g_face_dir[FACE_POOL_SIZE];   // DIR_* plus DIR_WET_FLAG if it touches water
  Integer g_face_light[FACE_POOL_SIZE]; // sky + FACE_TORCH_SCALE * torch, each 0..LIGHT_FULL
  Integer g_face_block[FACE_POOL_SIZE]; // the block the face belongs to

  // Each section's faces are sorted by direction group (1..6 the cube
  // face directions, 7 the plants) and, inside a group, by layer: the
  // cell's position 0..15 across the section along the face's axis
  // (x for DIR_PX and DIR_NX, ...; plants are all layer 0). Key
  // (group - 1) * 16 + layer + 1 of section s starts at entry
  // g_section_layer_start[(s - 1) * SECTION_LAYER_SLOTS + key] of the
  // section's part of the pool; slot 113 holds count + 1. Faces that
  // point towards the eye are then one run of layers per group.
  Integer g_section_layer_start[SECTION_LAYER_TABLE];

  // Scratch for sorting a section's faces by direction
  Integer g_sort_x  [SECTION_FACE_CAP];
  Integer g_sort_y  [SECTION_FACE_CAP];
  Integer g_sort_z  [SECTION_FACE_CAP];
  Integer g_sort_dir[SECTION_FACE_CAP];
  Integer g_sort_light[SECTION_FACE_CAP];
  Integer g_sort_block[SECTION_FACE_CAP];
  Integer g_sort_key  [SECTION_FACE_CAP];
  Integer g_sort_next [SECTION_LAYER_SLOTS];

  Integer g_mesh_overflow = 0;
  Integer g_mesh_builds   = 0;
}

Integer mesh_section_index (Integer p_sx, Integer p_sy, Integer p_sz);
void    mesh_reset         ();
Integer mesh_section_buried(Integer p_sx, Integer p_sy, Integer p_sz);
void    mesh_build_section (Integer p_sx, Integer p_sy, Integer p_sz);
void    mesh_group_faces   (Integer p_section, Integer p_x0, Integer p_y0, Integer p_z0);
Integer mesh_layer_key     (Integer p_direction, Integer p_local_x, Integer p_local_y, Integer p_local_z);
Integer mesh_ensure_section(Integer p_sx, Integer p_sy, Integer p_sz);
Integer mesh_face_light    (Integer p_x, Integer p_y, Integer p_z, Integer p_direction);
void    mesh_mark_dirty    (Integer p_x, Integer p_y, Integer p_z);
void    mesh_on_event      (Attributes &p_event);

#endif
