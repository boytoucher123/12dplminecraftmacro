#ifndef event_id_registry_h_included
#define event_id_registry_h_included

// Global ID
#define G_ID(I01) ID_##I01

{
    #define REGISTER_ID(I01) Integer G_ID(I01) = __LINE__;

    // Main panel events
    #define MAIN_PANEL(I01) MAIN_PANEL_##I01
    REGISTER_EVENT(MAIN_PANEL(panel         ));
    REGISTER_EVENT(MAIN_PANEL(process_button));
    REGISTER_EVENT(MAIN_PANEL(finish_button ));
    REGISTER_EVENT(MAIN_PANEL(help_button   ));
    REGISTER_EVENT(MAIN_PANEL(message_box   ));
    REGISTER_EVENT(MAIN_PANEL(Process       ));


    // Upgrade, add descriptions
    // then ID() gets id, DESC() can get description type of thing
}

#endif