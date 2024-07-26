float interval = 30.0;
key senderId;

default
{
    state_entry()
    {
        llMessageLinked(LINK_THIS, 0, llGetScriptName(), "");
    }

    link_message(integer sender_num, integer num, string message, key id)
    {
        if (message == "Start")
        {
            senderId = id;
            llMessageLinked(LINK_THIS, 0, "PopQuestion", senderId);
            llSetTimerEvent(interval);
        } else if (message == "Answered") {
            llSetTimerEvent(0);
            llMessageLinked(LINK_THIS, 0, "PopQuestion", senderId);
        } else if (message == "Stop") {
            llSay(0, "Requested to stop");
            llSetTimerEvent(0);
        } else if (message == "End") {
            llSetTimerEvent(0);
        }
    }

    timer()
    {
        llSay(0, "Times up!!! Moving to a new question");
        llMessageLinked(LINK_THIS, 0, "PopQuestion", senderId);
    }
}