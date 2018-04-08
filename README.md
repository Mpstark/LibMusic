# LibMusic
A World of Warcraft library addon for playing/queuing music, storing and retrieving externally-provided song metadata, manipulating music volume, and providing easy access to song music state as well as a CallbackHandler-powered event interface.


## Usage
As with any LibStub based libary, get a library access object first

`local LibMusic = LibStub("LibMusic-1.0");`


## Events
SONG_QUEUED
QUEUE_EMPTY
SONG_ENDED
SONG_STARTED
SONG_REGISTERED
MUSIC_DISABLED
MUSIC_ENABLED
VOLUME_CHANGED
LOOPING_ENABLED
LOOPING_DISABLED






/run LibMusic:Register("Sound\\music\\Legion\\MUS_70_AnduinPt1_B.mp3", 140)
/run LibMusic:Register("Sound\\music\\Legion\\MUS_70_WindsOutoftheEast_A.mp3", 96)
/run LibMusic:Register("Sound\\music\\Legion\\MUS_70_Weep_Viola.mp3", 110)
/run LibMusic:Register("Sound\\music\\Legion\\MUS_70_WeAreNotAlone_H.mp3", 106)

/run LibMusic:StartAndPlay("Sound\\music\\Legion\\MUS_70_AnduinPt1_B.mp3")

/run LibMusic:AddToQueue("Sound\\music\\Legion\\MUS_70_WindsOutoftheEast_A.mp3")
/run LibMusic:AddToQueue("Sound\\music\\Legion\\MUS_70_Weep_Viola.mp3")
/run LibMusic:AddToQueue("Sound\\music\\Legion\\MUS_70_WeAreNotAlone_H.mp3")