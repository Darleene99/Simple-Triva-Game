
list colorChoices = ["Start", "Stop"];

// The newline (\n) helps to visually separate this text from the dialog heading line 
string message = "\nPlease make a choice.";   

integer channelDialog;
integer listenId;
key toucherId;

default
{
    state_entry()
    {
        channelDialog = -1 - (integer)("0x" + llGetSubString((string)llGetKey(), -7, -1) );
    }

    touch_start(integer num_detected)
    {
        toucherId = llDetectedKey(0);
        llDialog(toucherId, message, colorChoices, channelDialog);
        listenId = llListen(channelDialog, "", toucherId, "");
    }
    
    listen(integer channel, string name, key id, string message)
    {
        if (message == "Start" || message == "Stop")
        {
            llMessageLinked(LINK_THIS, 0, message, id);
        }
        llListenRemove(listenId);
    }
}