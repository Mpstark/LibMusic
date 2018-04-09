# LibMusic
A World of Warcraft library addon for playing/queuing music, storing and retrieving externally-provided song metadata, manipulating music volume, and providing easy access to song music state as well as a CallbackHandler-powered event interface.


## Usage
As with any LibStub-based libary, get a library access object first:

`local LibMusic = LibStub("LibMusic-1.0");`


## Events
Based on CallbackHandler, LibMusic provides several callback-based events, listed below. Registering for these events is a little different from how you might expect, however, as LibMusic is not 'embedded' into your addon. Notice the lack of a colon and the fact that a `self` table is the first argument. If `method` is a string, `self[method](arg)` will be called when the event fires. If `method` is a function, the function `method(arg)` will be called and the `self` table will be ignored. If `method` is nil or is not provided, `self[EVENT_NAME](arg)` will be called.

`LibMusic.RegisterEvent(self, "EVENT_NAME"[, method, [arg]])`

`LibMusic.UnregisterEvent(self, "EVENT_NAME"[, method, [arg]])`

`LibMusic.UnregisterAllEvents(self)`

### SONG_QUEUED (handle)
A song was added to the queue.

### QUEUE_EMPTY
The queue was emptied, and the last song is now playing, or the queue was cleared on purpose.

### SONG_ENDED (handle)
The currently playing song ended.

### SONG_STARTED (handle[, length])
A new song has started to be played.

### SONG_REGISTERED (handle, length)
A new song has been registered with LibMusic.

### VOLUME_CHANGED (newVolume)
The game's music volume has changed. Note that in the case of the easing volume functions, this is called BEFORE easing the volume to the final volume. This is NOT called each frame as the volume changes.

### MUSIC_DISABLED
The game's music was disabled.

### MUSIC_ENABLED
The game's music was enabled.

### LOOPING_ENABLED
Music looping was enabled. This DOES NOT affect music played through LibMusic, but if the game is not playing a registered track via PlayMusic, then the music will be looped according to the game's internal logic.

### LOOPING_DISABLED
Music looping was disabled.
