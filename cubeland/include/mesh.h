#ifndef MESH_H_INCLUDED
#define MESH_H_INCLUDED

#include "config.h"

// ----------------------------------------------------------------
// Cached lists of visible block faces
// The world is split into 16 x 16 x 16 sections. Each section keeps
// the faces of its blocks that touch air (or water), so drawing a
// frame only walks those lists instead of the whole world. A
// section is rebuilt when a block in or beside it changes.
// ----------------------------------------------------------------

#define SECTION_UNBUILT  0
#define SECTION_BUILT    1
#define SECTION_DIRTY    2
#define SECTION_DIR_GROUPS 2304   // NUM_SECTIONS * 6

/*Global variables*/ {
  Integer g_section_state[NUM_SECTIONS];
  Integer g_section_count[NUM_SECTIONS];

  // Face pool: section s owns entries (s - 1) * SECTION_FACE_CAP + 1 ...
  Integer g_face_x  [FACE_POOL_SIZE];
  Integer g_face_y  [FACE_POOL_SIZE];
  Integer g_face_z  [FACE_POOL_SIZE];
  Integer g_face_dir[FACE_POOL_SIZE];   // DIR_* plus DIR_WET_FLAG if it touches water

  // Each section's faces are grouped by direction: group d of
  // section s starts at entry g_section_dir_start[(s - 1) * 6 + d]
  // of the section's part of the pool and holds g_section_dir_count
  Integer g_section_dir_start[SECTION_DIR_GROUPS];
  Integer g_section_dir_count[SECTION_DIR_GROUPS];

  // Scratch for sorting a section's faces by direction
  Integer g_sort_x  [SECTION_FACE_CAP];
  Integer g_sort_y  [SECTION_FACE_CAP];
  Integer g_sort_z  [SECTION_FACE_CAP];
  Integer g_sort_dir[SECTION_FACE_CAP];
  Integer g_sort_next[6];

  Integer g_mesh_overflow = 0;
  Integer g_mesh_builds   = 0;
}

Integer mesh_section_index (Integer sx, Integer sy, Integer sz);
void    mesh_reset         ();
Integer mesh_section_buried(Integer sx, Integer sy, Integer sz);
void    mesh_build_section (Integer sx, Integer sy, Integer sz);
void    mesh_group_faces   (Integer section);
Integer mesh_ensure_section(Integer sx, Integer sy, Integer sz);
void    mesh_mark_dirty    (Integer x, Integer y, Integer z);
void    mesh_on_event      ();

#endif
