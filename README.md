# LibMusic
A World of Warcraft library addon for playing/queuing music, storing and retrieving externally-provided song metadata, manipulating music volume, and providing easy access to song music state as well as a CallbackHandler-powered event interface.


## Usage
As with any LibStub based libary, get a library access object first:

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
