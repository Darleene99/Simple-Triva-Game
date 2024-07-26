// written by hiddenmachine on july 16, 2024
integer DEBUG = 1;
float GAME_TIMEOUT = 5.0;


vector TEXT_COLOR = <1.0, 1.0, 1.0>;
float TEXT_ALPHA = 1.0;

// soft lock to avoid click on unexpected moment
// this is stupid and was removed
//integer locked = 0;

// @TODO: replace with a menu to pick a theme
// the notecard holding the question
string      NOTECARD = "test questions";
// float       WAITTIME_BEFORE_QUESTION = 2.0;
// float       WAITTIME_LISTEN_HANDLER = 2.0;

// --------------------------------
// variables for parsing notecard
// --------------------------------

// internal for SL notecard reason
integer     intLine1;
key         keyConfigQueryhandle;
key         keyConfigUUID;


// internal for the game to be working
integer totalQuestion = 0;
list listQuestions = [];
list listAnswers = [];
string lastQuestion = "";
// key senderId = NULL_KEY;

// -----------------------------------
// variables for the current game Q/A
// -----------------------------------
//integer gameStarted = 0;
// list listResponseBag = [];
//integer listenHandler = 0;
string currentQuestion = "";
// string currentAnswer = "";
integer questionIdx;
key winner; 


// -----------------------------------------------
// variables for the player and money parameters
// -----------------------------------------------
list listParticipantsAndScore = [];

// menu runtimes
integer channelDialog;
integer listenId;
key toucherId;

// avatar key as a URI
string id2Link(key id) {
    return "secondlife:///app/agent/" + (string)id +  "/about";
}


readNotecard() {
    llOwnerSay("Reading notecard.");
    // read notecard and parse Q and A
    if (llGetInventoryType(NOTECARD) == INVENTORY_NONE)
    {
        llSay(DEBUG_CHANNEL, "The notecard '"+NOTECARD+"'  is missing!");
        state ready;
    }
    keyConfigQueryhandle = llGetNotecardLine(NOTECARD, intLine1);
    keyConfigUUID = llGetInventoryKey(NOTECARD);
}


initScores() 
{
    // reset variables for realtime game processing
    //listenHandler = 0;
    listParticipantsAndScore = [];
}

//
// General reset
//
ResetScript() {
    //locked = 1;
    
    llSetText("Loading questions...", <1.0, 1.0, 1.0>, 1.0);
    
    readNotecard();

    // reset game status
    // gameStarted = 0; // don't need
    
    // reset variables for reading notecard 
    totalQuestion = 0;
    // lastQuestion = "";
    listQuestions = [];
    listAnswers = [];
    questionIdx = 0;

}


//
// Basic functions
//
integer RandomInteger(integer _min, integer _max)
{
    return _min + (integer)(llFrand(_max - _min + 1));
}

//
// DebugMSG
//
DebugMsg(string _message)
{
    if (DEBUG) {
        llOwnerSay(_message);
    }
}

integer askQuestion(integer n)
{
    integer len = llGetListLength(listQuestions);
    if (n >= len) {
        // handle DONE
        return FALSE;
    } else {
        currentQuestion = llList2String(listQuestions, n);
        llSay(0, currentQuestion);
        return TRUE;
    }

}

integer processResponse(string response)
{
    string responseLower = llToLower(response);
    string currentAnswer = llList2String(listAnswers, questionIdx);
    list correctResponseList = llParseString2List(
        currentAnswer,
        [";"], 
        []);
    list correctResponseListLower = [];
    integer i;
    integer len = llGetListLength(correctResponseList);
    for (i = 0; i < len; ++i) {
        string item = llList2String(correctResponseList, i);
        correctResponseListLower += llToLower(item);
    }
    if (llListFindList(correctResponseListLower, [responseLower]) != -1) {
        return TRUE;
    } else {
        return FALSE;
    }
}

showScores()
{
    integer i;
    integer len = llGetListLength(listParticipantsAndScore);
    string curr = "";
    for (i = 0; i < len; i += 2) {
        key winner = llList2Key(listParticipantsAndScore, i);
        integer score = llList2Integer(listParticipantsAndScore, i + 1);
        string line = llKey2Name(winner) + ": " + (string)score;
        if (llStringLength(curr) + llStringLength(line) <= 250) {
            if (curr != "") {
                curr += "\n";
            }
            curr += line;
        }
    }
    setText(curr);
}

givePoint(key winner) 
{
    integer idx = llListFindList(listParticipantsAndScore, [winner]);
    if (idx == -1) {
        listParticipantsAndScore += [winner, 1];
    } else {
        integer score = llList2Integer(listParticipantsAndScore, idx + 1);
        listParticipantsAndScore = llListReplaceList(listParticipantsAndScore, [score + 1], idx + 1, idx + 1);
    }
    showScores();
}


setText(string m)
{
    llSetText(m, TEXT_COLOR, TEXT_ALPHA);
}

dumpScores()
{
    integer i;
    integer len = llGetListLength(listParticipantsAndScore);
    string curr = "";
    for (i = 0; i < len; i += 2) {
        key winner = llList2Key(listParticipantsAndScore, i);
        integer score = llList2Integer(listParticipantsAndScore, i + 1);
        string line = llKey2Name(winner) + ": " + (string)score;
        llSay(0, line);
    }
}

msgAnnounce() {
    string m = "===================================="
        + "\nReady for new game? Click to start!!"
        + "\n====================================";
    llSay(0, m);
}


default
{
    state_entry()
    {
        ResetScript();
        //loadNotecard();
    }

    dataserver(key keyQueryId, string strData)
    {
        if (keyQueryId == keyConfigQueryhandle)
        {
            // once finish reading, move to state "main"
            if (strData == EOF) {
                state ready;
            }

            keyConfigQueryhandle = llGetNotecardLine(NOTECARD, intLine1++);
            
             // Trim Whitespace; (not mandatory; if you use a space as marker you must erase this line
            strData = llStringTrim(strData, STRING_TRIM_HEAD);
            
            // is it a comment or empty line?
            string beginCharacter = llGetSubString(strData, 0, 0);
            if (beginCharacter != "#")
            {
                string tempLine = llStringTrim(llGetSubString(strData, 2, -1), STRING_TRIM);
                
                // uncomment to see what was parsed
                //DebugMsg(tempLine);
                
                // Manage question line
                if (beginCharacter == "Q")
                {                    
                    lastQuestion = tempLine;
                }
                
                // Manage response line
                else if (beginCharacter == "A" && lastQuestion != "" && tempLine != "")
                {                    
                    listQuestions += lastQuestion;
                    listAnswers += tempLine;
                    totalQuestion++;
                    lastQuestion = "";
                }
            }
        }
    }
}

state ready
{
    state_entry()
    {
        DebugMsg("reading completed: " + (string)totalQuestion + " total questions");
        //locked = 0;
        llSetText("Ready for new game", <1.0, 1.0, 1.0>, 1.0);
        msgAnnounce();

        channelDialog = -1 - (integer)("0x" + llGetSubString((string)llGetKey(), -7, -1) );
        listenId = llListen(channelDialog, "", toucherId, "");
    }

    touch_start(integer num_detected)
    {
        llDialog(llDetectedKey(0), 
            "\nPlease make a choice.",
            ["Start"], 
            channelDialog);
    }
    
    changed(integer intChange)
    {
        if (intChange & CHANGED_INVENTORY)
        {
            // If the notecard has changed, then reload the notecard
            if (keyConfigUUID != llGetInventoryKey(NOTECARD)) {
                llResetScript();
            }
        }
    }
    

    listen(integer channel, string name, key id, string message)
    {
        if (message == "Start")
        {
            questionIdx = 0;
            state gameStarted;
        }
    }
}

state gameStarted
{
    state_entry()
    {
        // set scores and shit
        if (askQuestion(questionIdx)) {
            state questionAsked;
        } else {
            state gameOver;
        }
    }
}

state questionAsked
{
    state_entry() 
    {
        llSetTimerEvent(GAME_TIMEOUT);
        winner = NULL_KEY;
        llListen(0, "", "", "");
    }

    timer()
    {
        string answer = llList2String(listAnswers, questionIdx);
        llSay(0, "Time ran out, the answer was: " + answer);
        questionIdx++;
        state gameStarted;
    }

    listen(integer channel, string name, key id, string message)
    {
        if (processResponse(message)) {
            winner = id;
            state scoreWinner;
        }
    }
}

state scoreWinner
{
    state_entry()
    {
        llSay(0, "That was correct " + id2Link(winner) + " ! Next question in 3 seconds...");
        string name = llKey2Name(winner);
        givePoint(winner);
        questionIdx += 1;
        winner = NULL_KEY;
        llSetTimerEvent(3.0);
    }

    timer()
    {
        state gameStarted;
    }
}

state gameOver
{
    state_entry()
    {
        llSay(0, "Game over! Click to reset!");
        llListen(channelDialog, "", NULL_KEY, "");
    }

    touch_start(integer num_detected)
    {
        llDialog(llDetectedKey(0), "wat do", ["scores", "replay"], channelDialog);
    }
    listen(integer chan, string name, key id, string msg)
    {
        if (msg == "scores") {
            dumpScores();
        } else if (msg == "replay") {
            state ready;
        }
    }
}