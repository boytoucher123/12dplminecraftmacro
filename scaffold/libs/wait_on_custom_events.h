// #ifndef WAIT_ON_CUSTOM_EVENTS_H_INCLUDED
// #define WAIT_ON_CUSTOM_EVENTS_H_INCLUDED


Integer wait_on_custom_events(Integer64 &id, Text &cmd, Text &msg);
Integer emit_event           (Integer64  id, Text  cmd, Text  msg);
Integer emit_urgent_event    (Integer64  id, Text  cmd, Text  msg);


#ifdef WAIT_ON_CUSTOM_EVENTS_IMPLEMENTATION
{
    Integer           __queue_size = 0;
    Dynamic_Integer64 __id__queue;
    Dynamic_Text      __msg_queue;
    Dynamic_Text      __cmd_queue;
}

Integer wait_on_custom_events(Integer64 &id, Text &cmd, Text &msg)
// ---------------------------------------------------------------
// Queue size is required since there seemingly isn't actually a
// way to shrink a Dynamic_Text object
// ---------------------------------------------------------------
{
    //Integer num_items = 0;
    //Get_number_of_items(__id__queue, num_items);

    if (__queue_size == 0) {
        return Wait_on_events(id, cmd, msg);
    }

    Get_item(__id__queue, 1, id );
    Get_item(__cmd_queue, 1, cmd);
    Get_item(__msg_queue, 1, msg);

    {for (Integer i = 2; i <= __queue_size; i++) {

        Integer64 tmp_id  = 0;
        Text      tmp_cmd = "";
        Text      tmp_msg = "";

        Get_item(__id__queue, i, tmp_id );
        Get_item(__cmd_queue, i, tmp_cmd);
        Get_item(__msg_queue, i, tmp_msg);

        Set_item(__id__queue, i-1, tmp_id );
        Set_item(__cmd_queue, i-1, tmp_cmd);
        Set_item(__msg_queue, i-1, tmp_msg);

    }}

    __queue_size--;

    if (__queue_size == 0) {
        // Reset sizes
        Dynamic_Integer64 tmp_id__queue;
        Dynamic_Text      tmp_msg_queue;
        Dynamic_Text      tmp_cmd_queue;

        __id__queue = tmp_id__queue;
        __msg_queue = tmp_msg_queue;
        __cmd_queue = tmp_cmd_queue;
    }


    return 0;
}

Integer emit_event(Integer64 id, Text cmd, Text msg)
// -------------------------------------------------
// Add event to end of queue
// -------------------------------------------------
{
    // @TODO error handling && validation

    __queue_size++;

    Integer num_items = 0;
    Get_number_of_items(__id__queue, num_items);

    if (__queue_size < num_items) {
        Set_item(__id__queue, __queue_size, id );
        Set_item(__msg_queue, __queue_size, cmd);
        Set_item(__cmd_queue, __queue_size, msg);
    } else {
        Append(id , __id__queue);
        Append(msg, __msg_queue);
        Append(cmd, __cmd_queue);
    }

    return 0;
}

Integer emit_urgent_event(Integer64 id, Text cmd, Text msg)
// --------------------------------------------------------
// Insert event at start of queue
// --------------------------------------------------------
{
    Dynamic_Integer64 tmp_id__queue;
    Dynamic_Text      tmp_msg_queue;
    Dynamic_Text      tmp_cmd_queue;
    Append(id , tmp_id__queue);
    Append(msg, tmp_msg_queue);
    Append(cmd, tmp_cmd_queue);

    // @TODO conditional set_item for loop crap, i guess
    Append(__id__queue, tmp_id__queue);
    Append(__msg_queue, tmp_msg_queue);
    Append(__cmd_queue, tmp_cmd_queue);

    __id__queue = tmp_id__queue;
    __msg_queue = tmp_msg_queue;
    __cmd_queue = tmp_cmd_queue;
    __queue_size++;

    return 0;
}

#endif