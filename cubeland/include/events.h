#ifndef EVENTS_H_INCLUDED
#define EVENTS_H_INCLUDED

#include "config.h"

// ----------------------------------------------------------------
// Game event queue
// Modules never call each other to report what happened, they emit
// an event instead. game_dispatch_events() hands every event to each
// module's *_on_event() handler, which reads the g_ev_* globals.
// ----------------------------------------------------------------

#define EVENT_QUEUE_SIZE      512

// Event types and their payloads
#define EVT_NONE              0
#define EVT_BLOCK_BROKEN      1    // i1..i3 cell, i4 block that was there
#define EVT_BLOCK_PLACED      2    // i1..i3 cell, i4 new block
#define EVT_COW_HURT          3    // i1 cow
#define EVT_COW_KILLED        4    // i1 cow, r1..r3 position
#define EVT_ITEM_PICKED_UP    5    // i1 item, i2 count
#define EVT_PLAYER_HURT       6    // i1 amount
#define EVT_PLAYER_DIED       7
#define EVT_PLAYER_ATE        8    // i1 item, i2 health gained
#define EVT_OPEN_SCREEN       9    // i1 screen, i2..i4 cell of the block used
#define EVT_CLOSE_SCREEN      10
#define EVT_TOAST             11   // text
#define EVT_ITEM_CRAFTED      12   // i1 item, i2 count
#define EVT_SPAWN_DROP        13   // i1 item, i2 count, r1..r3 position
#define EVT_WORLD_SAVED       14   // text world name
#define EVT_PLAYER_RESPAWNED  15

// Screens that EVT_OPEN_SCREEN can open
#define SCREEN_NONE           0
#define SCREEN_INVENTORY      1
#define SCREEN_CRAFTING       2
#define SCREEN_FURNACE        3

/*Global variables*/ {
  Integer g_event_head  = 1;
  Integer g_event_count = 0;
  Integer g_event_lost  = 0;

  Integer g_event_type [EVENT_QUEUE_SIZE];
  Integer g_event_i1   [EVENT_QUEUE_SIZE];
  Integer g_event_i2   [EVENT_QUEUE_SIZE];
  Integer g_event_i3   [EVENT_QUEUE_SIZE];
  Integer g_event_i4   [EVENT_QUEUE_SIZE];
  Real    g_event_r1   [EVENT_QUEUE_SIZE];
  Real    g_event_r2   [EVENT_QUEUE_SIZE];
  Real    g_event_r3   [EVENT_QUEUE_SIZE];
  Text    g_event_text [EVENT_QUEUE_SIZE];

  // The event currently being dispatched
  Integer g_ev_type = EVT_NONE;
  Integer g_ev_i1   = 0;
  Integer g_ev_i2   = 0;
  Integer g_ev_i3   = 0;
  Integer g_ev_i4   = 0;
  Real    g_ev_r1   = 0.0;
  Real    g_ev_r2   = 0.0;
  Real    g_ev_r3   = 0.0;
  Text    g_ev_text = "";
}

void    events_clear     ();
void    emit_event       (Integer type, Integer i1, Integer i2, Integer i3, Integer i4, Real r1, Real r2, Real r3, Text text);
void    emit_simple_event(Integer type);
void    emit_cell_event  (Integer type, Integer x, Integer y, Integer z, Integer block);
void    emit_item_event  (Integer type, Integer item, Integer count);
void    emit_drop_event  (Integer item, Integer count, Real x, Real y, Real z);
void    emit_toast       (Text text);
Integer next_event       ();

#endif
