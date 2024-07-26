integer DEBUG = 1;

// soft lock to avoid click on unexpected moment
integer locked = 0;

// @TODO: replace with a menu to pick a theme
// the notecard holding the question
string      NOTECARD = "test questions";
float       WAITTIME_BEFORE_QUESTION = 2.0;
float       WAITTIME_LISTEN_HANDLER = 2.0;

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
key senderId = NULL_KEY;

// -----------------------------------
// variables for the current game Q/A
// -----------------------------------
integer gameStarted = 0;
list listResponseBag = [];
integer listenHandler = 0;
string currentQuestion = "";
string currentAnswer = "";

// -----------------------------------------------
// variables for the player and money parameters
// -----------------------------------------------
list listParticipantsAndScore = [];

//
// General reset
//
ResetScript() {
    
    // lock click when reset
    locked = 1;
    
    llSetText("Loading questions...", <1.0, 1.0, 1.0>, 1.0);
    
    ResetCurrentScore();
    
    // read notecard and parse Q and A
    if (llGetInventoryType(NOTECARD) == INVENTORY_NONE)
    {
        llSay(DEBUG_CHANNEL, "The notecard '"+NOTECARD+"'  is missing!");
        state main;
    }
    keyConfigQueryhandle = llGetNotecardLine(NOTECARD, intLine1);
    keyConfigUUID = llGetInventoryKey(NOTECARD);
    
    // reset game status
    gameStarted = 0;
    
    // reset variables for reading notecard 
    totalQuestion = 0;
    lastQuestion = "";
    listQuestions = [];
    listAnswers = [];
    
    // reset variables for realtime game processing
    listenHandler = 0;
    currentQuestion = "";
    currentAnswer = "";
    listParticipantsAndScore = [];
    
    //llMessageLinked(LINK_THIS, 0, llGetScriptName(), "");
    //llMessageLinked(LINK_THIS, 0, "Stop", NULL_KEY);
}


//
// Increment play score when finding good answer
//
IncrementPlayerScore(key _id)
{
    
    // lock click and answers
    locked = 1;
    
    //DebugMsg("IncrementPlayerScore: " + _id);
    
    // did the participant list was updated?
    integer scoreUpdated = 0;
    
    // current len of participants who responded at least 1 good question
    integer lenParticipants = llGetListLength(listParticipantsAndScore);
    list listNewParticipantsAndScore = [];
    
    // loop thru participant and increment their score (if needed)
    integer a = 0;
    for (a = 0; a < lenParticipants; a++)
    {
        key _tmpKey =  llList2Key(listParticipantsAndScore, a);
        integer _score =  (integer)llList2String(listParticipantsAndScore, a + 1);
        DebugMsg("_score = " + (string)_score);
        listNewParticipantsAndScore += _tmpKey;
        if (_tmpKey == _id)
        {
            _score++;
            a++;
            scoreUpdated = 1;
        }
        listNewParticipantsAndScore += (string)_score;
    }
    
    // if we updated someone score in the list, we replace
    if (scoreUpdated == 1)
    {
        listParticipantsAndScore = listNewParticipantsAndScore;
    }
    
    // if its 1st good answer, we add new entry
    if (scoreUpdated == 0)
    {
        listParticipantsAndScore += _id;
        listParticipantsAndScore += "1";
    }
    
    //DebugMsg("listParticipantsAndScore = " + (string)listParticipantsAndScore);
    
    // unlock the game
    locked = 0;
}

//
// Reset the text that show the score
//
ResetCurrentScore()
{
     llSetText("", <1.0, 1.0, 1.0>, 1.0);
}

//
// Show current score
//
DisplayCurrentScore()
{
    // current len of participants who responded at least 1 good question
    integer lenParticipantsAndScore = llGetListLength(listParticipantsAndScore);
    string scoreMessage = "--- SCORE ---\n \n";
    // loop thru participant and increment their score (if needed)
    integer a = 0;
    for (a = 0; a < lenParticipantsAndScore; a++)
    {
        string _tmpKey =  llList2String(listParticipantsAndScore, a);
        integer _score =  (integer)llList2String(listParticipantsAndScore, a + 1);
        string _name =  llKey2Name( (key) _tmpKey);
        scoreMessage = scoreMessage + _name + " : " + (string)_score + "\n";
        a=a+1;
    }
    scoreMessage = scoreMessage + " \n";
    llSetText(scoreMessage, <1.0, 1.0, 1.0>, 1.0);
}



//
// Display top 3
//
DisplayTop3()
{
    llSay(0, "@TODO - DisplayTop3()");
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


PopQuestion() 
{
    // soft lock click when async processing
    if (locked == 1)
    {
        return;
    }
    
    llSleep(2.0);
    
    // at this point, we will process list and prepare for the new question
    // (its why we avoid new click. It might create collision with the variables)
    locked = 1;
    
    // ready to listen to people answer 
    if (listenHandler == 0)
    {
        listenHandler = llListen(0, "", "", "");
        DebugMsg("new listen handler: " + (string)listenHandler);
    }
    
    gameStarted = 1;
    
    // Len of available questions list
    integer lenQuestionsList = llGetListLength(listQuestions);
     
    // Test if we still have question to display
    if (lenQuestionsList == 0)
    {
        DebugMsg("lenQuestionsList=" + (string)lenQuestionsList);
        llSay(0, "No more questions!! Thanks for playing");
        llMessageLinked(LINK_THIS, 0, "End", senderId);

        DisplayTop3();
        
        // clean the listen handler
        if (listenHandler != 0)
        {
            DebugMsg("Remove listen handler...");
            llListenRemove(listenHandler);
            llSleep(WAITTIME_LISTEN_HANDLER);
        }
        
        // Reset everything to restart fresh
        llResetScript();
     }
     
     //
     // At this point, we still have questions available for the game
     //
     
     // Pull out a question
     DebugMsg("Pop out a question out of the list...");
     integer currentQuestionIdx = RandomInteger(0, lenQuestionsList - 1);
     
     // Current question and answer(s)
     currentQuestion = llList2String(listQuestions, currentQuestionIdx);
     currentAnswer =  llToLower(llList2String(listAnswers, currentQuestionIdx));
     
     // Recreate the questions/answers list after picking an item
     integer a;
     list newListQuestions = [];
     list newListAnswers = [];
     for (a = 0; a < lenQuestionsList; a++)
     {
         if (currentQuestionIdx != a)
         {
            newListQuestions = (newListQuestions=[]) + newListQuestions + llList2String(listQuestions, a);
            newListAnswers = (newListAnswers=[]) + newListAnswers + llList2String(listAnswers, a);
         }
     }
     
     // re-assign global var
     listQuestions = newListQuestions;
     listAnswers =  newListAnswers;
     
     // lets begin
     llSay(0, "====================================");
     llSay(0, "Get ready for the question...");
     llSay(0, "====================================");
    
     //DebugMsg("listQuestions = " + (string)listQuestions);
     //DebugMsg("listAnswers = " + (string)listAnswers);
     //DebugMsg("currentQuestion = " + currentQuestion);
     //DebugMsg("currentAnswer = " + currentAnswer);
     //DebugMsg("Questions remains = " + (string)llGetListLength(listQuestions));
     
     // we give time for people to get ready for the question
     llSleep(WAITTIME_BEFORE_QUESTION);
     
     // bam
     llSay(0, currentQuestion);
     locked = 0;
}


//
// DEFAULT STATE (ON REZ)
// Load questions from notecard and prepare the game
//
default
{
    state_entry()
    {
        ResetScript();
    }

    dataserver(key keyQueryId, string strData)
    {
        if (keyQueryId == keyConfigQueryhandle)
        {
            // once finish reading, move to state "main"
            if (strData == EOF)
                state main;

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
                    listQuestions = (listQuestions=[]) + listQuestions + lastQuestion;
                    listAnswers = (listAnswers=[]) + listAnswers + tempLine;
                    totalQuestion++;
                    lastQuestion = "";
                }
            }
        }
    }
}

state main
{
    state_entry()
    {
        DebugMsg("reading completed: " + (string)totalQuestion + " total questions");
        locked = 0;
        llSetText("Ready for new game", <1.0, 1.0, 1.0>, 1.0);
        llSay(0, "====================================");
        llSay(0, "Ready for new game? Click to start!!");
        llSay(0, "====================================");
    }
    
    changed(integer intChange)
    {
        if (intChange & CHANGED_INVENTORY)
        {
            // If the notecard has changed, then reload the notecard
            if (keyConfigUUID != llGetInventoryKey(NOTECARD))
                llResetScript();
        }
    }
    
    link_message(integer sender_num, integer num, string message, key id)
    {
        if (message == "PopQuestion")
        {
            senderId = id;
            PopQuestion();
        }
        else if (message == "Stop")
        {
            ResetScript();
        }
    }
    
    listen(integer channel, string name, key id, string message)
    {
        // avoid processing for unnecessary channel
        if (channel == 0 && gameStarted == 1 && locked == 0) 
        {
            // normalize the response given by the user
            string responseGiven = llToLower(message);
            
            //DebugMsg("responseGiven = " + responseGiven);
            //DebugMsg("currentAnswer = " + currentAnswer);
            
            // parse the correct response line. and convert to list
            list correctResponseList = llParseString2List(currentAnswer,[";"],[]);
            integer lenCorrectResponse = llGetListLength(correctResponseList);
            
            //DebugMsg("correctResponseList = " + (string)correctResponseList);
            //DebugMsg("lenCorrectResponse = " + (string)lenCorrectResponse);
            
            integer a = 0;
            while (a < lenCorrectResponse)
            {
                string aCorrectAnswer = llStringTrim(llList2String(correctResponseList, a), STRING_TRIM);
                a++;
                
                //DebugMsg("aCorrectAnswer = " + aCorrectAnswer);
                
                if (aCorrectAnswer == responseGiven)
                {
                    IncrementPlayerScore(id);
                    llSay(0, "Good answer " + name + "!!");
                    
                    DisplayCurrentScore();
                    
                    llMessageLinked(LINK_THIS, 0, "Answered", senderId);
                    //DebugMsg("(ID = " + (string)id + ")");
                    return;
                }
            }  
        }
        
    }
}