# LÖVE 11.5 API

Auto-converted from love-api. Signatures show parameter names; types omitted for brevity.

---
## Global Functions

### love.getVersion() → major, minor, revision, codename
Gets the current running version of LÖVE.

### love.hasDeprecationOutput() → enabled
Gets whether LÖVE displays warnings when using deprecated functionality. It is disabled by default in fused mode, and enabled by default otherwise.

When deprecation output is enabled, the first use of a formally deprecated LÖVE API will show a message at the bottom of the screen for a short time, and print the message to the console.

### love.isVersionCompatible(version) → compatible
Gets whether the given version is compatible with the current running version of LÖVE.
- Variant 2: love.isVersionCompatible(major, minor, revision) → compatible

### love.setDeprecationOutput(enable)
Sets whether LÖVE displays warnings when using deprecated functionality. It is disabled by default in fused mode, and enabled by default otherwise.

When deprecation output is enabled, the first use of a formally deprecated LÖVE API will show a message at the bottom of the screen for a short time, and print the message to the console.

---
## Callbacks

### love.conf(t)
If a file called conf.lua is present in your game folder (or .love file), it is run before the LÖVE modules are loaded. You can use this file to overwrite the love.conf function, which is later called by the LÖVE 'boot' script. Using the love.conf function, you can set some configuration options, and change things like the default size of the window, which modules are loaded, and other stuff.

### love.directorydropped(path)
Callback function triggered when a directory is dragged and dropped onto the window.

### love.displayrotated(index, orientation)
Called when the device display orientation changed, for example, user rotated their phone 180 degrees.

### love.draw()
Callback function used to draw on the screen every frame.

### love.errorhandler(msg) → mainLoop
The error handler, used to display error messages.

### love.filedropped(file)
Callback function triggered when a file is dragged and dropped onto the window.

### love.focus(focus)
Callback function triggered when window receives or loses focus.

### love.gamepadaxis(joystick, axis, value)
Called when a Joystick's virtual gamepad axis is moved.

### love.gamepadpressed(joystick, button)
Called when a Joystick's virtual gamepad button is pressed.

### love.gamepadreleased(joystick, button)
Called when a Joystick's virtual gamepad button is released.

### love.joystickadded(joystick)
Called when a Joystick is connected.

### love.joystickaxis(joystick, axis, value)
Called when a joystick axis moves.

### love.joystickhat(joystick, hat, direction)
Called when a joystick hat direction changes.

### love.joystickpressed(joystick, button)
Called when a joystick button is pressed.

### love.joystickreleased(joystick, button)
Called when a joystick button is released.

### love.joystickremoved(joystick)
Called when a Joystick is disconnected.

### love.keypressed(key, scancode, isrepeat)
Callback function triggered when a key is pressed.
- Variant 2: love.keypressed(key, isrepeat)
  Key repeat needs to be enabled with love.keyboard.setKeyRepeat for repeat keypress events to be received.

### love.keyreleased(key, scancode)
Callback function triggered when a keyboard key is released.

### love.load(arg, unfilteredArg)
This function is called exactly once at the beginning of the game.

### love.lowmemory()
Callback function triggered when the system is running out of memory on mobile devices.

Mobile operating systems may forcefully kill the game if it uses too much memory, so any non-critical resource should be removed if possible (by setting all variables referencing the resources to '''nil'''), when this event is triggered. Sounds and images in particular tend to use the most memory.

### love.mousefocus(focus)
Callback function triggered when window receives or loses mouse focus.

### love.mousemoved(x, y, dx, dy, istouch)
Callback function triggered when the mouse is moved.

### love.mousepressed(x, y, button, istouch, presses)
Callback function triggered when a mouse button is pressed.

### love.mousereleased(x, y, button, istouch, presses)
Callback function triggered when a mouse button is released.

### love.quit() → r
Callback function triggered when the game is closed.

### love.resize(w, h)
Called when the window is resized, for example if the user resizes the window, or if love.window.setMode is called with an unsupported width or height in fullscreen and the window chooses the closest appropriate size.

### love.run() → mainLoop
The main function, containing the main loop. A sensible default is used when left out.

### love.textedited(text, start, length)
Called when the candidate text for an IME (Input Method Editor) has changed.

The candidate text is not the final text that the user will eventually choose. Use love.textinput for that.

### love.textinput(text)
Called when text has been entered by the user. For example if shift-2 is pressed on an American keyboard layout, the text '@' will be generated.

### love.threaderror(thread, errorstr)
Callback function triggered when a Thread encounters an error.

### love.touchmoved(id, x, y, dx, dy, pressure)
Callback function triggered when a touch press moves inside the touch screen.

### love.touchpressed(id, x, y, dx, dy, pressure)
Callback function triggered when the touch screen is touched.

### love.touchreleased(id, x, y, dx, dy, pressure)
Callback function triggered when the touch screen stops being touched.

### love.update(dt)
Callback function used to update the state of the game every frame.

### love.visible(visible)
Callback function triggered when window is minimized/hidden or unminimized by the user.

### love.wheelmoved(x, y)
Callback function triggered when the mouse wheel is moved.

---
## Global Types

### Data < Object
The superclass of all data.
- clone() → clone
  Creates a new copy of the Data object.
- getFFIPointer() → pointer
  Gets an FFI pointer to the Data.
  
  This function should be preferred instead of Data:getPointer because the latter uses light userdata which can't store more all possible memory addresses on some new ARM64 architectures, when LuaJIT is used.
- getPointer() → pointer
  Gets a pointer to the Data. Can be used with libraries such as LuaJIT's FFI.
- getSize() → size
  Gets the Data's size in bytes.
- getString() → data
  Gets the full Data as a string.

### Object
The superclass of all LÖVE types.
- release() → success
  Destroys the object's Lua reference. The object will be completely deleted if it's not referenced by any other LÖVE object or thread.
  
  This method can be used to immediately clean up resources without waiting for Lua's garbage collector.
- type() → type
  Gets the type of the object as a string.
- typeOf(name) → b
  Checks whether an object is of a certain type. If the object has the type with the specified name in its hierarchy, this function will return true.

---
## love.audio

Provides an interface to create noise with the user's speakers.

### DistanceModel
The different distance models.

Extended information can be found in the chapter "3.4. Attenuation By Distance" of the OpenAL 1.1 specification.
- none: Sources do not get attenuated.
- inverse: Inverse distance attenuation.
- inverseclamped: Inverse distance attenuation. Gain is clamped. In version 0.9.2 and older this is named '''inverse clamped'''.
- linear: Linear attenuation.
- linearclamped: Linear attenuation. Gain is clamped. In version 0.9.2 and older this is named '''linear clamped'''.
- exponent: Exponential attenuation.
- exponentclamped: Exponential attenuation. Gain is clamped. In version 0.9.2 and older this is named '''exponent clamped'''.

### EffectType
The different types of effects supported by love.audio.setEffect.
- chorus: Plays multiple copies of the sound with slight pitch and time variation. Used to make sounds sound "fuller" or "thicker".
- compressor: Decreases the dynamic range of the sound, making the loud and quiet parts closer in volume, producing a more uniform amplitude throughout time.
- distortion: Alters the sound by amplifying it until it clips, shearing off parts of the signal, leading to a compressed and distorted sound.
- echo: Decaying feedback based effect, on the order of seconds. Also known as delay; causes the sound to repeat at regular intervals at a decreasing volume.
- equalizer: Adjust the frequency components of the sound using a 4-band (low-shelf, two band-pass and a high-shelf) equalizer.
- flanger: Plays two copies of the sound; while varying the phase, or equivalently delaying one of them, by amounts on the order of milliseconds, resulting in phasing sounds.
- reverb: Decaying feedback based effect, on the order of milliseconds. Used to simulate the reflection off of the surroundings.
- ringmodulator: An implementation of amplitude modulation; multiplies the source signal with a simple waveform, to produce either volume changes, or inharmonic overtones.

### EffectWaveform
The different types of waveforms that can be used with the '''ringmodulator''' EffectType.
- sawtooth: A sawtooth wave, also known as a ramp wave. Named for its linear rise, and (near-)instantaneous fall along time.
- sine: A sine wave. Follows a trigonometric sine function.
- square: A square wave. Switches between high and low states (near-)instantaneously.
- triangle: A triangle wave. Follows a linear rise and fall that repeats periodically.

### FilterType
Types of filters for Sources.
- lowpass: Low-pass filter. High frequency sounds are attenuated.
- highpass: High-pass filter. Low frequency sounds are attenuated.
- bandpass: Band-pass filter. Both high and low frequency sounds are attenuated based on the given parameters.

### SourceType
Types of audio sources.

A good rule of thumb is to use stream for music files and static for all short sound effects. Basically, you want to avoid loading large files into memory at once.
- static: The whole audio is decoded.
- stream: The audio is decoded in chunks when needed.
- queue: The audio must be manually queued by the user.

### TimeUnit
Units that represent time.
- seconds: Regular seconds.
- samples: Audio samples.

### love.audio.getActiveEffects() → effects
Gets a list of the names of the currently enabled effects.

### love.audio.getActiveSourceCount() → count
Gets the current number of simultaneously playing sources.

### love.audio.getDistanceModel() → model
Returns the distance attenuation model.

### love.audio.getDopplerScale() → scale
Gets the current global scale factor for velocity-based doppler effects.

### love.audio.getEffect(name) → settings
Gets the settings associated with an effect.

### love.audio.getMaxSceneEffects() → maximum
Gets the maximum number of active effects supported by the system.

### love.audio.getMaxSourceEffects() → maximum
Gets the maximum number of active Effects in a single Source object, that the system can support.

### love.audio.getOrientation() → fx, fy, fz, ux, uy, uz
Returns the orientation of the listener.

### love.audio.getPosition() → x, y, z
Returns the position of the listener. Please note that positional audio only works for mono (i.e. non-stereo) sources.

### love.audio.getRecordingDevices() → devices
Gets a list of RecordingDevices on the system.

The first device in the list is the user's default recording device. The list may be empty if there are no microphones connected to the system.

Audio recording is currently not supported on iOS.

### love.audio.getVelocity() → x, y, z
Returns the velocity of the listener.

### love.audio.getVolume() → volume
Returns the master volume.

### love.audio.isEffectsSupported() → supported
Gets whether audio effects are supported in the system.

### love.audio.newQueueableSource(samplerate, bitdepth, channels, buffercount=0) → source
Creates a new Source usable for real-time generated sound playback with Source:queue.

### love.audio.newSource(filename, type) → source
Creates a new Source from a filepath, File, Decoder or SoundData.

Sources created from SoundData are always static.
- Variant 2: love.audio.newSource(file, type) → source
- Variant 3: love.audio.newSource(decoder, type) → source
- Variant 4: love.audio.newSource(data, type) → source
- Variant 5: love.audio.newSource(data) → source

### love.audio.pause() → Sources
Pauses specific or all currently played Sources.
- Variant 2: love.audio.pause(source, ...)
  Pauses the given Sources.
- Variant 3: love.audio.pause(sources)
  Pauses the given Sources.

### love.audio.play(source)
Plays the specified Source.
- Variant 2: love.audio.play(sources)
  Starts playing multiple Sources simultaneously.
- Variant 3: love.audio.play(source1, source2, ...)
  Starts playing multiple Sources simultaneously.

### love.audio.setDistanceModel(model)
Sets the distance attenuation model.

### love.audio.setDopplerScale(scale)
Sets a global scale factor for velocity-based doppler effects. The default scale value is 1.

### love.audio.setEffect(name, settings) → success
Defines an effect that can be applied to a Source.

Not all system supports audio effects. Use love.audio.isEffectsSupported to check.
- Variant 2: love.audio.setEffect(name, enabled=true) → success

### love.audio.setMixWithSystem(mix) → success
Sets whether the system should mix the audio with the system's audio.

### love.audio.setOrientation(fx, fy, fz, ux, uy, uz)
Sets the orientation of the listener.

### love.audio.setPosition(x, y, z)
Sets the position of the listener, which determines how sounds play.

### love.audio.setVelocity(x, y, z)
Sets the velocity of the listener.

### love.audio.setVolume(volume)
Sets the master volume.

### love.audio.stop()
Stops currently played sources.
- Variant 2: love.audio.stop(source)
  This function will only stop the specified source.
- Variant 3: love.audio.stop(source1, source2, ...)
  Simultaneously stops all given Sources.
- Variant 4: love.audio.stop(sources)
  Simultaneously stops all given Sources.

### RecordingDevice < Object
Represents an audio input device capable of recording sounds.
- getBitDepth() → bits
  Gets the number of bits per sample in the data currently being recorded.
- getChannelCount() → channels
  Gets the number of channels currently being recorded (mono or stereo).
- getData() → data
  Gets all recorded audio SoundData stored in the device's internal ring buffer.
  
  The internal ring buffer is cleared when this function is called, so calling it again will only get audio recorded after the previous call. If the device's internal ring buffer completely fills up before getData is called, the oldest data that doesn't fit into the buffer will be lost.
- getName() → name
  Gets the name of the recording device.
- getSampleCount() → samples
  Gets the number of currently recorded samples.
- getSampleRate() → rate
  Gets the number of samples per second currently being recorded.
- isRecording() → recording
  Gets whether the device is currently recording.
- start(samplecount, samplerate=8000, bitdepth=16, channels=1) → success
  Begins recording audio using this device.
- stop() → data
  Stops recording audio from this device. Any sound data currently in the device's buffer will be returned.

### Source < Object
A Source represents audio you can play back.

You can do interesting things with Sources, like set the volume, pitch, and its position relative to the listener. Please note that positional audio only works for mono (i.e. non-stereo) sources.

The Source controls (play/pause/stop) act according to the following state table.
Constructors: newQueueableSource, newSource
- clone() → source
  Creates an identical copy of the Source in the stopped state.
  
  Static Sources will use significantly less memory and take much less time to be created if Source:clone is used to create them instead of love.audio.newSource, so this method should be preferred when making multiple Sources which play the same sound.
- getActiveEffects() → effects
  Gets a list of the Source's active effect names.
- getAirAbsorption() → amount
  Gets the amount of air absorption applied to the Source.
  
  By default the value is set to 0 which means that air absorption effects are disabled. A value of 1 will apply high frequency attenuation to the Source at a rate of 0.05 dB per meter.
- getAttenuationDistances() → ref, max
  Gets the reference and maximum attenuation distances of the Source. The values, combined with the current DistanceModel, affect how the Source's volume attenuates based on distance from the listener.
- getChannelCount() → channels
  Gets the number of channels in the Source. Only 1-channel (mono) Sources can use directional and positional effects.
- getCone() → innerAngle, outerAngle, outerVolume
  Gets the Source's directional volume cones. Together with Source:setDirection, the cone angles allow for the Source's volume to vary depending on its direction.
- getDirection() → x, y, z
  Gets the direction of the Source.
- getDuration(unit='seconds') → duration
  Gets the duration of the Source. For streaming Sources it may not always be sample-accurate, and may return -1 if the duration cannot be determined at all.
- getEffect(name, filtersettings={}) → filtersettings
  Gets the filter settings associated to a specific effect.
  
  This function returns nil if the effect was applied with no filter settings associated to it.
- getFilter() → settings
  Gets the filter settings currently applied to the Source.
- getFreeBufferCount() → buffers
  Gets the number of free buffer slots in a queueable Source. If the queueable Source is playing, this value will increase up to the amount the Source was created with. If the queueable Source is stopped, it will process all of its internal buffers first, in which case this function will always return the amount it was created with.
- getPitch() → pitch
  Gets the current pitch of the Source.
- getPosition() → x, y, z
  Gets the position of the Source.
- getRolloff() → rolloff
  Returns the rolloff factor of the source.
- getType() → sourcetype
  Gets the type of the Source.
- getVelocity() → x, y, z
  Gets the velocity of the Source.
- getVolume() → volume
  Gets the current volume of the Source.
- getVolumeLimits() → min, max
  Returns the volume limits of the source.
- isLooping() → loop
  Returns whether the Source will loop.
- isPlaying() → playing
  Returns whether the Source is playing.
- isRelative() → relative
  Gets whether the Source's position, velocity, direction, and cone angles are relative to the listener.
- pause()
  Pauses the Source.
- play() → success
  Starts playing the Source.
- queue(sounddata) → success
  Queues SoundData for playback in a queueable Source.
  
  This method requires the Source to be created via love.audio.newQueueableSource.
- seek(offset, unit='seconds')
  Sets the currently playing position of the Source.
- setAirAbsorption(amount)
  Sets the amount of air absorption applied to the Source.
  
  By default the value is set to 0 which means that air absorption effects are disabled. A value of 1 will apply high frequency attenuation to the Source at a rate of 0.05 dB per meter.
  
  Air absorption can simulate sound transmission through foggy air, dry air, smoky atmosphere, etc. It can be used to simulate different atmospheric conditions within different locations in an area.
- setAttenuationDistances(ref, max)
  Sets the reference and maximum attenuation distances of the Source. The parameters, combined with the current DistanceModel, affect how the Source's volume attenuates based on distance.
  
  Distance attenuation is only applicable to Sources based on mono (rather than stereo) audio.
- setCone(innerAngle, outerAngle, outerVolume=0)
  Sets the Source's directional volume cones. Together with Source:setDirection, the cone angles allow for the Source's volume to vary depending on its direction.
- setDirection(x, y, z)
  Sets the direction vector of the Source. A zero vector makes the source non-directional.
- setEffect(name, enable=true) → success
  Applies an audio effect to the Source.
  
  The effect must have been previously defined using love.audio.setEffect.
- setFilter(settings) → success
  Sets a low-pass, high-pass, or band-pass filter to apply when playing the Source.
- setLooping(loop)
  Sets whether the Source should loop.
- setPitch(pitch)
  Sets the pitch of the Source.
- setPosition(x, y, z)
  Sets the position of the Source. Please note that this only works for mono (i.e. non-stereo) sound files!
- setRelative(enable=false)
  Sets whether the Source's position, velocity, direction, and cone angles are relative to the listener, or absolute.
  
  By default, all sources are absolute and therefore relative to the origin of love's coordinate system 0, 0. Only absolute sources are affected by the position of the listener. Please note that positional audio only works for mono (i.e. non-stereo) sources.
- setRolloff(rolloff)
  Sets the rolloff factor which affects the strength of the used distance attenuation.
  
  Extended information and detailed formulas can be found in the chapter '3.4. Attenuation By Distance' of OpenAL 1.1 specification.
- setVelocity(x, y, z)
  Sets the velocity of the Source.
  
  This does '''not''' change the position of the Source, but lets the application know how it has to calculate the doppler effect.
- setVolume(volume)
  Sets the current volume of the Source.
- setVolumeLimits(min, max)
  Sets the volume limits of the source. The limits have to be numbers from 0 to 1.
- stop()
  Stops a Source.
- tell(unit='seconds') → position
  Gets the currently playing position of the Source.

---
## love.data

Provides functionality for creating and transforming data.

### CompressedDataFormat
Compressed data formats.
- lz4: The LZ4 compression format. Compresses and decompresses very quickly, but the compression ratio is not the best. LZ4-HC is used when compression level 9 is specified. Some benchmarks are available here.
- zlib: The zlib format is DEFLATE-compressed data with a small bit of header data. Compresses relatively slowly and decompresses moderately quickly, and has a decent compression ratio.
- gzip: The gzip format is DEFLATE-compressed data with a slightly larger header than zlib. Since it uses DEFLATE it has the same compression characteristics as the zlib format.
- deflate: Raw DEFLATE-compressed data (no header).

### ContainerType
Return type of various data-returning functions.
- data: Return type is ByteData.
- string: Return type is string.

### EncodeFormat
Encoding format used to encode or decode data.
- base64: Encode/decode data as base64 binary-to-text encoding.
- hex: Encode/decode data as hexadecimal string.

### HashFunction
Hash algorithm of love.data.hash.
- md5: MD5 hash algorithm (16 bytes).
- sha1: SHA1 hash algorithm (20 bytes).
- sha224: SHA2 hash algorithm with message digest size of 224 bits (28 bytes).
- sha256: SHA2 hash algorithm with message digest size of 256 bits (32 bytes).
- sha384: SHA2 hash algorithm with message digest size of 384 bits (48 bytes).
- sha512: SHA2 hash algorithm with message digest size of 512 bits (64 bytes).

### love.data.compress(container, format, rawstring, level=-1) → compressedData
Compresses a string or data using a specific compression algorithm.
- Variant 2: love.data.compress(container, format, data, level=-1) → compressedData

### love.data.decode(container, format, sourceString) → decoded
Decode Data or a string from any of the EncodeFormats to Data or string.
- Variant 2: love.data.decode(container, format, sourceData) → decoded

### love.data.decompress(container, compressedData) → decompressedData
Decompresses a CompressedData or previously compressed string or Data object.
- Variant 2: love.data.decompress(container, format, compressedString) → decompressedData
- Variant 3: love.data.decompress(container, format, data) → decompressedData

### love.data.encode(container, format, sourceString, linelength=0) → encoded
Encode Data or a string to a Data or string in one of the EncodeFormats.
- Variant 2: love.data.encode(container, format, sourceData, linelength=0) → encoded

### love.data.getPackedSize(format) → size
Gets the size in bytes that a given format used with love.data.pack will use.

This function behaves the same as Lua 5.3's string.packsize.

### love.data.hash(hashFunction, string) → rawdigest
Compute the message digest of a string using a specified hash algorithm.
- Variant 2: love.data.hash(hashFunction, data) → rawdigest
  To return the hex string representation of the hash, use love.data.encode
  
  hexDigestString = love.data.encode('string', 'hex', love.data.hash(algo, data))

### love.data.newByteData(datastring) → bytedata
Creates a new Data object containing arbitrary bytes.

Data:getPointer along with LuaJIT's FFI can be used to manipulate the contents of the ByteData object after it has been created.
- Variant 2: love.data.newByteData(Data, offset=0, size=data:getSize()) → bytedata
  Creates a new ByteData by copying from an existing Data object.
- Variant 3: love.data.newByteData(size) → bytedata
  Creates a new empty ByteData with the specific size.

### love.data.newDataView(data, offset, size) → view
Creates a new Data referencing a subsection of an existing Data object.

### love.data.pack(container, format, v1, ...) → data
Packs (serializes) simple Lua values.

This function behaves the same as Lua 5.3's string.pack.

### love.data.unpack(format, datastring, pos=1) → v1, ..., index
Unpacks (deserializes) a byte-string or Data into simple Lua values.

This function behaves the same as Lua 5.3's string.unpack.
- Variant 2: love.data.unpack(format, data, pos=1) → v1, ..., index
  Unpacking integers with values greater than 2^52 is not supported, as Lua 5.1 cannot represent those values in its number type.

### ByteData < Object
Data object containing arbitrary bytes in an contiguous memory.

There are currently no LÖVE functions provided for manipulating the contents of a ByteData, but Data:getPointer can be used with LuaJIT's FFI to access and write to the contents directly.
Constructors: newByteData

### CompressedData < Data
Represents byte data compressed using a specific algorithm.

love.data.decompress can be used to de-compress the data (or love.math.decompress in 0.10.2 or earlier).
Constructors: compress
- getFormat() → format
  Gets the compression format of the CompressedData.

---
## love.event

Manages events, like keypresses.

### Event
Arguments to love.event.push() and the like.

Since 0.8.0, event names are no longer abbreviated.
- focus: Window focus gained or lost
- joystickpressed: Joystick pressed
- joystickreleased: Joystick released
- keypressed: Key pressed
- keyreleased: Key released
- mousepressed: Mouse pressed
- mousereleased: Mouse released
- quit: Quit
- resize: Window size changed by the user
- visible: Window is minimized or un-minimized by the user
- mousefocus: Window mouse focus gained or lost
- threaderror: A Lua error has occurred in a thread
- joystickadded: Joystick connected
- joystickremoved: Joystick disconnected
- joystickaxis: Joystick axis motion
- joystickhat: Joystick hat pressed
- gamepadpressed: Joystick's virtual gamepad button pressed
- gamepadreleased: Joystick's virtual gamepad button released
- gamepadaxis: Joystick's virtual gamepad axis moved
- textinput: User entered text
- mousemoved: Mouse position changed
- lowmemory: Running out of memory on mobile devices system
- textedited: Candidate text for an IME changed
- wheelmoved: Mouse wheel moved
- touchpressed: Touch screen touched
- touchreleased: Touch screen stop touching
- touchmoved: Touch press moved inside touch screen
- directorydropped: Directory is dragged and dropped onto the window
- filedropped: File is dragged and dropped onto the window.
- jp: Joystick pressed
- jr: Joystick released
- kp: Key pressed
- kr: Key released
- mp: Mouse pressed
- mr: Mouse released
- q: Quit
- f: Window focus gained or lost

### love.event.clear()
Clears the event queue.

### love.event.poll() → i
Returns an iterator for messages in the event queue.

### love.event.pump()
Pump events into the event queue.

This is a low-level function, and is usually not called by the user, but by love.run.

Note that this does need to be called for any OS to think you're still running,

and if you want to handle OS-generated events at all (think callbacks).

### love.event.push(n, a, b, c, d, e, f, ...)
Adds an event to the event queue.

From 0.10.0 onwards, you may pass an arbitrary amount of arguments with this function, though the default callbacks don't ever use more than six.

### love.event.quit(exitstatus=0)
Adds the quit event to the queue.

The quit event is a signal for the event handler to close LÖVE. It's possible to abort the exit process with the love.quit callback.
- Variant 2: love.event.quit('restart')
  Restarts the game without relaunching the executable. This cleanly shuts down the main Lua state instance and creates a brand new one.

### love.event.wait() → n, a, b, c, d, e, f, ...
Like love.event.poll(), but blocks until there is an event in the queue.

---
## love.filesystem

Provides an interface to the user's filesystem.

### BufferMode
Buffer modes for File objects.
- none: No buffering. The result of write and append operations appears immediately.
- line: Line buffering. Write and append operations are buffered until a newline is output or the buffer size limit is reached.
- full: Full buffering. Write and append operations are always buffered until the buffer size limit is reached.

### FileDecoder
How to decode a given FileData.
- file: The data is unencoded.
- base64: The data is base64-encoded.

### FileMode
The different modes you can open a File in.
- r: Open a file for read.
- w: Open a file for write.
- a: Open a file for append.
- c: Do not open a file (represents a closed file.)

### FileType
The type of a file.
- file: Regular file.
- directory: Directory.
- symlink: Symbolic link.
- other: Something completely different like a device.

### love.filesystem.append(name, data, size=all) → success, errormsg
Append data to an existing file.
- Variant 2: love.filesystem.append(name, data, size=all) → success, errormsg

### love.filesystem.areSymlinksEnabled() → enable
Gets whether love.filesystem follows symbolic links.

### love.filesystem.createDirectory(name) → success
Recursively creates a directory.

When called with 'a/b' it creates both 'a' and 'a/b', if they don't exist already.

### love.filesystem.getAppdataDirectory() → path
Returns the application data directory (could be the same as getUserDirectory)

### love.filesystem.getCRequirePath() → paths
Gets the filesystem paths that will be searched for c libraries when require is called.

The paths string returned by this function is a sequence of path templates separated by semicolons. The argument passed to ''require'' will be inserted in place of any question mark ('?') character in each template (after the dot characters in the argument passed to ''require'' are replaced by directory separators.) Additionally, any occurrence of a double question mark ('??') will be replaced by the name passed to require and the default library extension for the platform.

The paths are relative to the game's source and save directories, as well as any paths mounted with love.filesystem.mount.

### love.filesystem.getDirectoryItems(dir) → files
Returns a table with the names of files and subdirectories in the specified path. The table is not sorted in any way; the order is undefined.

If the path passed to the function exists in the game and the save directory, it will list the files and directories from both places.
- Variant 2: love.filesystem.getDirectoryItems(dir, callback) → files

### love.filesystem.getIdentity() → name
Gets the write directory name for your game. 

Note that this only returns the name of the folder to store your files in, not the full path.

### love.filesystem.getInfo(path, filtertype) → info
Gets information about the specified file or directory.
- Variant 2: love.filesystem.getInfo(path, info) → info
  This variant accepts an existing table to fill in, instead of creating a new one.
- Variant 3: love.filesystem.getInfo(path, filtertype, info) → info
  This variant only returns info if the item at the given path is the same file type as specified in the filtertype argument, and accepts an existing table to fill in, instead of creating a new one.

### love.filesystem.getRealDirectory(filepath) → realdir
Gets the platform-specific absolute path of the directory containing a filepath.

This can be used to determine whether a file is inside the save directory or the game's source .love.

### love.filesystem.getRequirePath() → paths
Gets the filesystem paths that will be searched when require is called.

The paths string returned by this function is a sequence of path templates separated by semicolons. The argument passed to ''require'' will be inserted in place of any question mark ('?') character in each template (after the dot characters in the argument passed to ''require'' are replaced by directory separators.)

The paths are relative to the game's source and save directories, as well as any paths mounted with love.filesystem.mount.

### love.filesystem.getSaveDirectory() → dir
Gets the full path to the designated save directory.

This can be useful if you want to use the standard io library (or something else) to

read or write in the save directory.

### love.filesystem.getSource() → path
Returns the full path to the the .love file or directory. If the game is fused to the LÖVE executable, then the executable is returned.

### love.filesystem.getSourceBaseDirectory() → path
Returns the full path to the directory containing the .love file. If the game is fused to the LÖVE executable, then the directory containing the executable is returned.

If love.filesystem.isFused is true, the path returned by this function can be passed to love.filesystem.mount, which will make the directory containing the main game (e.g. C:\Program Files\coolgame\) readable by love.filesystem.

### love.filesystem.getUserDirectory() → path
Returns the path of the user's directory

### love.filesystem.getWorkingDirectory() → cwd
Gets the current working directory.

### love.filesystem.init(appname)
Initializes love.filesystem, will be called internally, so should not be used explicitly.

### love.filesystem.isFused() → fused
Gets whether the game is in fused mode or not.

If a game is in fused mode, its save directory will be directly in the Appdata directory instead of Appdata/LOVE/. The game will also be able to load C Lua dynamic libraries which are located in the save directory.

A game is in fused mode if the source .love has been fused to the executable (see Game Distribution), or if '--fused' has been given as a command-line argument when starting the game.

### love.filesystem.lines(name) → iterator
Iterate over the lines in a file.

### love.filesystem.load(name) → chunk, errormsg
Loads a Lua file (but does not run it).

### love.filesystem.mount(archive, mountpoint, appendToPath=false) → success
Mounts a zip file or folder in the game's save directory for reading.

It is also possible to mount love.filesystem.getSourceBaseDirectory if the game is in fused mode.
- Variant 2: love.filesystem.mount(filedata, mountpoint, appendToPath=false) → success
  Mounts the contents of the given FileData in memory. The FileData's data must contain a zipped directory structure.
- Variant 3: love.filesystem.mount(data, archivename, mountpoint, appendToPath=false) → success
  Mounts the contents of the given Data object in memory. The data must contain a zipped directory structure.

### love.filesystem.newFile(filename) → file
Creates a new File object. 

It needs to be opened before it can be accessed.
- Variant 2: love.filesystem.newFile(filename, mode) → file, errorstr
  Creates a File object and opens it for reading, writing, or appending.

### love.filesystem.newFileData(contents, name) → data
Creates a new FileData object from a file on disk, or from a string in memory.
- Variant 2: love.filesystem.newFileData(originaldata, name) → data
  Creates a new FileData object from a Data object in memory.
- Variant 3: love.filesystem.newFileData(filepath) → data, err
  Creates a new FileData from a file on the storage device.

### love.filesystem.read(name, size=all) → contents, size, contents, error
Read the contents of a file.
- Variant 2: love.filesystem.read(container, name, size=all) → contents, size, contents, error
  Reads the contents of a file into either a string or a FileData object.

### love.filesystem.remove(name) → success
Removes a file or empty directory.

### love.filesystem.setCRequirePath(paths)
Sets the filesystem paths that will be searched for c libraries when require is called.

The paths string returned by this function is a sequence of path templates separated by semicolons. The argument passed to ''require'' will be inserted in place of any question mark ('?') character in each template (after the dot characters in the argument passed to ''require'' are replaced by directory separators.) Additionally, any occurrence of a double question mark ('??') will be replaced by the name passed to require and the default library extension for the platform.

The paths are relative to the game's source and save directories, as well as any paths mounted with love.filesystem.mount.

### love.filesystem.setIdentity(name)
Sets the write directory for your game. 

Note that you can only set the name of the folder to store your files in, not the location.
- Variant 2: love.filesystem.setIdentity(name)

### love.filesystem.setRequirePath(paths)
Sets the filesystem paths that will be searched when require is called.

The paths string given to this function is a sequence of path templates separated by semicolons. The argument passed to ''require'' will be inserted in place of any question mark ('?') character in each template (after the dot characters in the argument passed to ''require'' are replaced by directory separators.)

The paths are relative to the game's source and save directories, as well as any paths mounted with love.filesystem.mount.

### love.filesystem.setSource(path)
Sets the source of the game, where the code is present. This function can only be called once, and is normally automatically done by LÖVE.

### love.filesystem.setSymlinksEnabled(enable)
Sets whether love.filesystem follows symbolic links. It is enabled by default in version 0.10.0 and newer, and disabled by default in 0.9.2.

### love.filesystem.unmount(archive) → success
Unmounts a zip file or folder previously mounted for reading with love.filesystem.mount.

### love.filesystem.write(name, data, size=all) → success, message
Write data to a file in the save directory. If the file existed already, it will be completely replaced by the new contents.
- Variant 2: love.filesystem.write(name, data, size=all) → success, message
  If you are getting the error message 'Could not set write directory', try setting the save directory. This is done either with love.filesystem.setIdentity or by setting the identity field in love.conf.
  
  '''Writing to multiple lines''': In Windows, some text editors (e.g. Notepad) only treat CRLF ('\r\n') as a new line.

### DroppedFile < File
Represents a file dropped onto the window.

Note that the DroppedFile type can only be obtained from love.filedropped callback, and can't be constructed manually by the user.

### File < Object
Represents a file on the filesystem. A function that takes a file path can also take a File.
Constructors: newFile
- close() → success
  Closes a File.
- flush() → success, err
  Flushes any buffered written data in the file to the disk.
- getBuffer() → mode, size
  Gets the buffer mode of a file.
- getFilename() → filename
  Gets the filename that the File object was created with. If the file object originated from the love.filedropped callback, the filename will be the full platform-dependent file path.
- getMode() → mode
  Gets the FileMode the file has been opened with.
- getSize() → size
  Returns the file size.
- isEOF() → eof
  Gets whether end-of-file has been reached.
- isOpen() → open
  Gets whether the file is open.
- lines() → iterator
  Iterate over all the lines in a file.
- open(mode) → ok, err
  Open the file for write, read or append.
- read(bytes=all) → contents, size
  Read a number of bytes from a file.
- seek(pos) → success
  Seek to a position in a file
- setBuffer(mode, size=0) → success, errorstr
  Sets the buffer mode for a file opened for writing or appending. Files with buffering enabled will not write data to the disk until the buffer size limit is reached, depending on the buffer mode.
  
  File:flush will force any buffered data to be written to the disk.
- tell() → pos
  Returns the position in the file.
- write(data, size=all) → success, err
  Write data to a file.

### FileData < Data
Data representing the contents of a file.
Constructors: newFileData
- getExtension() → ext
  Gets the extension of the FileData.
- getFilename() → name
  Gets the filename of the FileData.

---
## love.font

Allows you to work with fonts.

### HintingMode
True Type hinting mode.
- normal: Default hinting. Should be preferred for typical antialiased fonts.
- light: Results in fuzzier text but can sometimes preserve the original glyph shapes of the text better than normal hinting.
- mono: Results in aliased / unsmoothed text with either full opacity or completely transparent pixels. Should be used when antialiasing is not desired for the font.
- none: Disables hinting for the font. Results in fuzzier text.

### love.font.newBMFontRasterizer(imageData, glyphs, dpiscale=1) → rasterizer
Creates a new BMFont Rasterizer.
- Variant 2: love.font.newBMFontRasterizer(fileName, glyphs, dpiscale=1) → rasterizer

### love.font.newGlyphData(rasterizer, glyph)
Creates a new GlyphData.

### love.font.newImageRasterizer(imageData, glyphs, extraSpacing=0, dpiscale=1) → rasterizer
Creates a new Image Rasterizer.

### love.font.newRasterizer(filename) → rasterizer
Creates a new Rasterizer.
- Variant 2: love.font.newRasterizer(data) → rasterizer
- Variant 3: love.font.newRasterizer(size=12, hinting='normal', dpiscale=love.window.getDPIScale()) → rasterizer
  Create a TrueTypeRasterizer with the default font.
- Variant 4: love.font.newRasterizer(fileName, size=12, hinting='normal', dpiscale=love.window.getDPIScale()) → rasterizer
  Create a TrueTypeRasterizer with custom font.
- Variant 5: love.font.newRasterizer(fileData, size=12, hinting='normal', dpiscale=love.window.getDPIScale()) → rasterizer
  Create a TrueTypeRasterizer with custom font.
- Variant 6: love.font.newRasterizer(imageData, glyphs, dpiscale=1) → rasterizer
  Creates a new BMFont Rasterizer.
- Variant 7: love.font.newRasterizer(fileName, glyphs, dpiscale=1) → rasterizer
  Creates a new BMFont Rasterizer.

### love.font.newTrueTypeRasterizer(size=12, hinting='normal', dpiscale=love.window.getDPIScale()) → rasterizer
Creates a new TrueType Rasterizer.
- Variant 2: love.font.newTrueTypeRasterizer(fileName, size=12, hinting='normal', dpiscale=love.window.getDPIScale()) → rasterizer
  Create a TrueTypeRasterizer with custom font.
- Variant 3: love.font.newTrueTypeRasterizer(fileData, size=12, hinting='normal', dpiscale=love.window.getDPIScale()) → rasterizer
  Create a TrueTypeRasterizer with custom font.

### GlyphData < Data
A GlyphData represents a drawable symbol of a font Rasterizer.
- getAdvance() → advance
  Gets glyph advance.
- getBearing() → bx, by
  Gets glyph bearing.
- getBoundingBox() → x, y, width, height
  Gets glyph bounding box.
- getDimensions() → width, height
  Gets glyph dimensions.
- getFormat() → format
  Gets glyph pixel format.
- getGlyph() → glyph
  Gets glyph number.
- getGlyphString() → glyph
  Gets glyph string.
- getHeight() → height
  Gets glyph height.
- getWidth() → width
  Gets glyph width.

### Rasterizer < Object
A Rasterizer handles font rendering, containing the font data (image or TrueType font) and drawable glyphs.
Constructors: newTrueTypeRasterizer, newRasterizer, newImageRasterizer, newBMFontRasterizer
- getAdvance() → advance
  Gets font advance.
- getAscent() → height
  Gets ascent height.
- getDescent() → height
  Gets descent height.
- getGlyphCount() → count
  Gets number of glyphs in font.
- getGlyphData(glyph) → glyphData
  Gets glyph data of a specified glyph.
- getHeight() → height
  Gets font height.
- getLineHeight() → height
  Gets line height of a font.
- hasGlyphs(glyph1, ...) → hasGlyphs
  Checks if font contains specified glyphs.

---
## love.graphics

The primary responsibility for the love.graphics module is the drawing of lines, shapes, text, Images and other Drawable objects onto the screen. Its secondary responsibilities include loading external files (including Images and Fonts) into memory, creating specialized objects (such as ParticleSystems or Canvases) and managing screen geometry.

LÖVE's coordinate system is rooted in the upper-left corner of the screen, which is at location (0, 0). The x axis is horizontal: larger values are further to the right. The y axis is vertical: larger values are further towards the bottom.

In many cases, you draw images or shapes in terms of their upper-left corner.

Many of the functions are used to manipulate the graphics coordinate system, which is essentially the way coordinates are mapped to the display. You can change the position, scale, and even rotation in this way.

### AlignMode
Text alignment.
- center: Align text center.
- left: Align text left.
- right: Align text right.
- justify: Align text both left and right.

### ArcType
Different types of arcs that can be drawn.
- pie: The arc is drawn like a slice of pie, with the arc circle connected to the center at its end-points.
- open: The arc circle's two end-points are unconnected when the arc is drawn as a line. Behaves like the "closed" arc type when the arc is drawn in filled mode.
- closed: The arc circle's two end-points are connected to each other.

### AreaSpreadDistribution
Types of particle area spread distribution.
- uniform: Uniform distribution.
- normal: Normal (gaussian) distribution.
- ellipse: Uniform distribution in an ellipse.
- borderellipse: Distribution in an ellipse with particles spawning at the edges of the ellipse.
- borderrectangle: Distribution in a rectangle with particles spawning at the edges of the rectangle.
- none: No distribution - area spread is disabled.

### BlendAlphaMode
Different ways alpha affects color blending. See BlendMode and the BlendMode Formulas for additional notes.
- alphamultiply: The RGB values of what's drawn are multiplied by the alpha values of those colors during blending. This is the default alpha mode.
- premultiplied: The RGB values of what's drawn are '''not''' multiplied by the alpha values of those colors during blending. For most blend modes to work correctly with this alpha mode, the colors of a drawn object need to have had their RGB values multiplied by their alpha values at some point previously ("premultiplied alpha").

### BlendMode
Different ways to do color blending. See BlendAlphaMode and the BlendMode Formulas for additional notes.
- alpha: Alpha blending (normal). The alpha of what's drawn determines its opacity.
- replace: The colors of what's drawn completely replace what was on the screen, with no additional blending. The BlendAlphaMode specified in love.graphics.setBlendMode still affects what happens.
- screen: 'Screen' blending.
- add: The pixel colors of what's drawn are added to the pixel colors already on the screen. The alpha of the screen is not modified.
- subtract: The pixel colors of what's drawn are subtracted from the pixel colors already on the screen. The alpha of the screen is not modified.
- multiply: The pixel colors of what's drawn are multiplied with the pixel colors already on the screen (darkening them). The alpha of drawn objects is multiplied with the alpha of the screen rather than determining how much the colors on the screen are affected, even when the "alphamultiply" BlendAlphaMode is used.
- lighten: The pixel colors of what's drawn are compared to the existing pixel colors, and the larger of the two values for each color component is used. Only works when the "premultiplied" BlendAlphaMode is used in love.graphics.setBlendMode.
- darken: The pixel colors of what's drawn are compared to the existing pixel colors, and the smaller of the two values for each color component is used. Only works when the "premultiplied" BlendAlphaMode is used in love.graphics.setBlendMode.
- additive: Additive blend mode.
- subtractive: Subtractive blend mode.
- multiplicative: Multiply blend mode.
- premultiplied: Premultiplied alpha blend mode.

### CompareMode
Different types of per-pixel stencil test and depth test comparisons. The pixels of an object will be drawn if the comparison succeeds, for each pixel that the object touches.
- equal: * stencil tests: the stencil value of the pixel must be equal to the supplied value.
* depth tests: the depth value of the drawn object at that pixel must be equal to the existing depth value of that pixel.
- notequal: * stencil tests: the stencil value of the pixel must not be equal to the supplied value.
* depth tests: the depth value of the drawn object at that pixel must not be equal to the existing depth value of that pixel.
- less: * stencil tests: the stencil value of the pixel must be less than the supplied value.
* depth tests: the depth value of the drawn object at that pixel must be less than the existing depth value of that pixel.
- lequal: * stencil tests: the stencil value of the pixel must be less than or equal to the supplied value.
* depth tests: the depth value of the drawn object at that pixel must be less than or equal to the existing depth value of that pixel.
- gequal: * stencil tests: the stencil value of the pixel must be greater than or equal to the supplied value.
* depth tests: the depth value of the drawn object at that pixel must be greater than or equal to the existing depth value of that pixel.
- greater: * stencil tests: the stencil value of the pixel must be greater than the supplied value.
* depth tests: the depth value of the drawn object at that pixel must be greater than the existing depth value of that pixel.
- never: Objects will never be drawn.
- always: Objects will always be drawn. Effectively disables the depth or stencil test.

### CullMode
How Mesh geometry is culled when rendering.
- back: Back-facing triangles in Meshes are culled (not rendered). The vertex order of a triangle determines whether it is back- or front-facing.
- front: Front-facing triangles in Meshes are culled.
- none: Both back- and front-facing triangles in Meshes are rendered.

### DrawMode
Controls whether shapes are drawn as an outline, or filled.
- fill: Draw filled shape.
- line: Draw outlined shape.

### FilterMode
How the image is filtered when scaling.
- linear: Scale image with linear interpolation.
- nearest: Scale image with nearest neighbor interpolation.

### GraphicsFeature
Graphics features that can be checked for with love.graphics.getSupported.
- clampzero: Whether the "clampzero" WrapMode is supported.
- lighten: Whether the "lighten" and "darken" BlendModes are supported.
- multicanvasformats: Whether multiple formats can be used in the same love.graphics.setCanvas call.
- glsl3: Whether GLSL 3 Shaders can be used.
- instancing: Whether mesh instancing is supported.
- fullnpot: Whether textures with non-power-of-two dimensions can use mipmapping and the 'repeat' WrapMode.
- pixelshaderhighp: Whether pixel shaders can use "highp" 32 bit floating point numbers (as opposed to just 16 bit or lower precision).
- shaderderivatives: Whether shaders can use the dFdx, dFdy, and fwidth functions for computing derivatives.

### GraphicsLimit
Types of system-dependent graphics limits checked for using love.graphics.getSystemLimits.
- pointsize: The maximum size of points.
- texturesize: The maximum width or height of Images and Canvases.
- multicanvas: The maximum number of simultaneously active canvases (via love.graphics.setCanvas.)
- canvasmsaa: The maximum number of antialiasing samples for a Canvas.
- texturelayers: The maximum number of layers in an Array texture.
- volumetexturesize: The maximum width, height, or depth of a Volume texture.
- cubetexturesize: The maximum width or height of a Cubemap texture.
- anisotropy: The maximum amount of anisotropic filtering. Texture:setMipmapFilter internally clamps the given anisotropy value to the system's limit.

### IndexDataType
Vertex map datatype for Data variant of Mesh:setVertexMap.
- uint16: The vertex map is array of unsigned word (16-bit).
- uint32: The vertex map is array of unsigned dword (32-bit).

### LineJoin
Line join style.
- miter: The ends of the line segments beveled in an angle so that they join seamlessly.
- none: No cap applied to the ends of the line segments.
- bevel: Flattens the point where line segments join together.

### LineStyle
The styles in which lines are drawn.
- rough: Draw rough lines.
- smooth: Draw smooth lines.

### MeshDrawMode
How a Mesh's vertices are used when drawing.
- fan: The vertices create a "fan" shape with the first vertex acting as the hub point. Can be easily used to draw simple convex polygons.
- strip: The vertices create a series of connected triangles using vertices 1, 2, 3, then 3, 2, 4 (note the order), then 3, 4, 5, and so on.
- triangles: The vertices create unconnected triangles.
- points: The vertices are drawn as unconnected points (see love.graphics.setPointSize.)

### MipmapMode
Controls whether a Canvas has mipmaps, and its behaviour when it does.
- none: The Canvas has no mipmaps.
- auto: The Canvas has mipmaps. love.graphics.setCanvas can be used to render to a specific mipmap level, or Canvas:generateMipmaps can (re-)compute all mipmap levels based on the base level.
- manual: The Canvas has mipmaps, and all mipmap levels will automatically be recomputed when switching away from the Canvas with love.graphics.setCanvas.

### ParticleInsertMode
How newly created particles are added to the ParticleSystem.
- top: Particles are inserted at the top of the ParticleSystem's list of particles.
- bottom: Particles are inserted at the bottom of the ParticleSystem's list of particles.
- random: Particles are inserted at random positions in the ParticleSystem's list of particles.

### SpriteBatchUsage
Usage hints for SpriteBatches and Meshes to optimize data storage and access.
- dynamic: The object's data will change occasionally during its lifetime.
- static: The object will not be modified after initial sprites or vertices are added.
- stream: The object data will always change between draws.

### StackType
Graphics state stack types used with love.graphics.push.
- transform: The transformation stack (love.graphics.translate, love.graphics.rotate, etc.)
- all: All love.graphics state, including transform state.

### StencilAction
How a stencil function modifies the stencil values of pixels it touches.
- replace: The stencil value of a pixel will be replaced by the value specified in love.graphics.stencil, if any object touches the pixel.
- increment: The stencil value of a pixel will be incremented by 1 for each object that touches the pixel. If the stencil value reaches 255 it will stay at 255.
- decrement: The stencil value of a pixel will be decremented by 1 for each object that touches the pixel. If the stencil value reaches 0 it will stay at 0.
- incrementwrap: The stencil value of a pixel will be incremented by 1 for each object that touches the pixel. If a stencil value of 255 is incremented it will be set to 0.
- decrementwrap: The stencil value of a pixel will be decremented by 1 for each object that touches the pixel. If the stencil value of 0 is decremented it will be set to 255.
- invert: The stencil value of a pixel will be bitwise-inverted for each object that touches the pixel. If a stencil value of 0 is inverted it will become 255.

### TextureType
Types of textures (2D, cubemap, etc.)
- 2d: Regular 2D texture with width and height.
- array: Several same-size 2D textures organized into a single object. Similar to a texture atlas / sprite sheet, but avoids sprite bleeding and other issues.
- cube: Cubemap texture with 6 faces. Requires a custom shader (and Shader:send) to use. Sampling from a cube texture in a shader takes a 3D direction vector instead of a texture coordinate.
- volume: 3D texture with width, height, and depth. Requires a custom shader to use. Volume textures can have texture filtering applied along the 3rd axis.

### VertexAttributeStep
The frequency at which a vertex shader fetches the vertex attribute's data from the Mesh when it's drawn.

Per-instance attributes can be used to render a Mesh many times with different positions, colors, or other attributes via a single love.graphics.drawInstanced call, without using the love_InstanceID vertex shader variable.
- pervertex: The vertex attribute will have a unique value for each vertex in the Mesh.
- perinstance: The vertex attribute will have a unique value for each instance of the Mesh.

### VertexWinding
How Mesh geometry vertices are ordered.
- cw: Clockwise.
- ccw: Counter-clockwise.

### WrapMode
How the image wraps inside a Quad with a larger quad size than image size. This also affects how Meshes with texture coordinates which are outside the range of 1 are drawn, and the color returned by the Texel Shader function when using it to sample from texture coordinates outside of the range of 1.
- clamp: Clamp the texture. Appears only once. The area outside the texture's normal range is colored based on the edge pixels of the texture.
- repeat: Repeat the texture. Fills the whole available extent.
- mirroredrepeat: Repeat the texture, flipping it each time it repeats. May produce better visual results than the repeat mode when the texture doesn't seamlessly tile.
- clampzero: Clamp the texture. Fills the area outside the texture's normal range with transparent black (or opaque black for textures with no alpha channel.)

### love.graphics.applyTransform(transform)
Applies the given Transform object to the current coordinate transformation.

This effectively multiplies the existing coordinate transformation's matrix with the Transform object's internal matrix to produce the new coordinate transformation.

### love.graphics.arc(drawmode, x, y, radius, angle1, angle2, segments=10)
Draws a filled or unfilled arc at position (x, y). The arc is drawn from angle1 to angle2 in radians. The segments parameter determines how many segments are used to draw the arc. The more segments, the smoother the edge.
- Variant 2: love.graphics.arc(drawmode, arctype, x, y, radius, angle1, angle2, segments=10)

### love.graphics.captureScreenshot(filename)
Creates a screenshot once the current frame is done (after love.draw has finished).

Since this function enqueues a screenshot capture rather than executing it immediately, it can be called from an input callback or love.update and it will still capture all of what's drawn to the screen in that frame.
- Variant 2: love.graphics.captureScreenshot(callback)
  Capture a screenshot and call a callback with the generated ImageData at the end of the current frame.
- Variant 3: love.graphics.captureScreenshot(channel)
  Capture a screenshot and push the generated ImageData to a Channel at the end of the current frame.

### love.graphics.circle(mode, x, y, radius)
Draws a circle.
- Variant 2: love.graphics.circle(mode, x, y, radius, segments)

### love.graphics.clear()
Clears the screen or active Canvas to the specified color.

This function is called automatically before love.draw in the default love.run function. See the example in love.run for a typical use of this function.

Note that the scissor area bounds the cleared region.

In versions prior to 11.0, color component values were within the range of 0 to 255 instead of 0 to 1.

In versions prior to background color instead.
- Variant 2: love.graphics.clear(r, g, b, a=1, clearstencil=true, cleardepth=true)
  Clears the screen or active Canvas to the specified color.
- Variant 3: love.graphics.clear(color, ..., clearstencil=true, cleardepth=true)
  Clears multiple active Canvases to different colors, if multiple Canvases are active at once via love.graphics.setCanvas.
  
  A color must be specified for each active Canvas, when this function variant is used.
- Variant 4: love.graphics.clear(clearcolor, clearstencil, cleardepth)
  Clears the stencil or depth buffers without having to clear the color canvas as well.

### love.graphics.discard(discardcolor=true, discardstencil=true)
Discards (trashes) the contents of the screen or active Canvas. This is a performance optimization function with niche use cases.

If the active Canvas has just been changed and the 'replace' BlendMode is about to be used to draw something which covers the entire screen, calling love.graphics.discard rather than calling love.graphics.clear or doing nothing may improve performance on mobile devices.

On some desktop systems this function may do nothing.
- Variant 2: love.graphics.discard(discardcolors, discardstencil=true)

### love.graphics.draw(drawable, x=0, y=0, r=0, sx=1, sy=sx, ox=0, oy=0, kx=0, ky=0)
Draws a Drawable object (an Image, Canvas, SpriteBatch, ParticleSystem, Mesh, Text object, or Video) on the screen with optional rotation, scaling and shearing.

Objects are drawn relative to their local coordinate system. The origin is by default located at the top left corner of Image and Canvas. All scaling, shearing, and rotation arguments transform the object relative to that point. Also, the position of the origin can be specified on the screen coordinate system.

It's possible to rotate an object about its center by offsetting the origin to the center. Angles must be given in radians for rotation. One can also use a negative scaling factor to flip about its centerline. 

Note that the offsets are applied before rotation, scaling, or shearing; scaling and shearing are applied before rotation.

The right and bottom edges of the object are shifted at an angle defined by the shearing factors.

When using the default shader anything drawn with this function will be tinted according to the currently selected color.  Set it to pure white to preserve the object's original colors.
- Variant 2: love.graphics.draw(texture, quad, x, y, r=0, sx=1, sy=sx, ox=0, oy=0, kx=0, ky=0)
- Variant 3: love.graphics.draw(drawable, transform)
- Variant 4: love.graphics.draw(texture, quad, transform)

### love.graphics.drawInstanced(mesh, instancecount, x=0, y=0, r=0, sx=1, sy=sx, ox=0, oy=0, kx=0, ky=0)
Draws many instances of a Mesh with a single draw call, using hardware geometry instancing.

Each instance can have unique properties (positions, colors, etc.) but will not by default unless a custom per-instance vertex attributes or the love_InstanceID GLSL 3 vertex shader variable is used, otherwise they will all render at the same position on top of each other.

Instancing is not supported by some older GPUs that are only capable of using OpenGL ES 2 or OpenGL 2. Use love.graphics.getSupported to check.
- Variant 2: love.graphics.drawInstanced(mesh, instancecount, transform)

### love.graphics.drawLayer(texture, layerindex, x=0, y=0, r=0, sx=1, sy=sx, ox=0, oy=0, kx=0, ky=0)
Draws a layer of an Array Texture.
- Variant 2: love.graphics.drawLayer(texture, layerindex, quad, x=0, y=0, r=0, sx=1, sy=sx, ox=0, oy=0, kx=0, ky=0)
  Draws a layer of an Array Texture using the specified Quad.
  
  The specified layer index overrides any layer index set on the Quad via Quad:setLayer.
- Variant 3: love.graphics.drawLayer(texture, layerindex, transform)
  Draws a layer of an Array Texture using the specified Transform.
- Variant 4: love.graphics.drawLayer(texture, layerindex, quad, transform)
  Draws a layer of an Array Texture using the specified Quad and Transform.
  
  In order to use an Array Texture or other non-2D texture types as the main texture in a custom void effect() variant must be used in the pixel shader, and MainTex must be declared as an ArrayImage or sampler2DArray like so: uniform ArrayImage MainTex;.

### love.graphics.ellipse(mode, x, y, radiusx, radiusy)
Draws an ellipse.
- Variant 2: love.graphics.ellipse(mode, x, y, radiusx, radiusy, segments)

### love.graphics.flushBatch()
Immediately renders any pending automatically batched draws.

LÖVE will call this function internally as needed when most state is changed, so it is not necessary to manually call it.

The current batch will be automatically flushed by love.graphics state changes (except for the transform stack and the current color), as well as Shader:send and methods on Textures which change their state. Using a different Image in consecutive love.graphics.draw calls will also flush the current batch.

SpriteBatches, ParticleSystems, Meshes, and Text objects do their own batching and do not affect automatic batching of other draws, aside from flushing the current batch when they're drawn.

### love.graphics.getBackgroundColor() → r, g, b, a
Gets the current background color.

In versions prior to 11.0, color component values were within the range of 0 to 255 instead of 0 to 1.

### love.graphics.getBlendMode() → mode, alphamode
Gets the blending mode.

### love.graphics.getCanvas() → canvas
Gets the current target Canvas.

### love.graphics.getCanvasFormats() → formats
Gets the available Canvas formats, and whether each is supported.
- Variant 2: love.graphics.getCanvasFormats(readable) → formats

### love.graphics.getColor() → r, g, b, a
Gets the current color.

In versions prior to 11.0, color component values were within the range of 0 to 255 instead of 0 to 1.

### love.graphics.getColorMask() → r, g, b, a
Gets the active color components used when drawing. Normally all 4 components are active unless love.graphics.setColorMask has been used.

The color mask determines whether individual components of the colors of drawn objects will affect the color of the screen. They affect love.graphics.clear and Canvas:clear as well.

### love.graphics.getDPIScale() → scale
Gets the DPI scale factor of the window.

The DPI scale factor represents relative pixel density. The pixel density inside the window might be greater (or smaller) than the 'size' of the window. For example on a retina screen in Mac OS X with the highdpi window flag enabled, the window may take up the same physical size as an 800x600 window, but the area inside the window uses 1600x1200 pixels. love.graphics.getDPIScale() would return 2 in that case.

The love.window.fromPixels and love.window.toPixels functions can also be used to convert between units.

The highdpi window flag must be enabled to use the full pixel density of a Retina screen on Mac OS X and iOS. The flag currently does nothing on Windows and Linux, and on Android it is effectively always enabled.

### love.graphics.getDefaultFilter() → min, mag, anisotropy
Returns the default scaling filters used with Images, Canvases, and Fonts.

### love.graphics.getDepthMode() → comparemode, write
Gets the current depth test mode and whether writing to the depth buffer is enabled.

This is low-level functionality designed for use with custom vertex shaders and Meshes with custom vertex attributes. No higher level APIs are provided to set the depth of 2D graphics such as shapes, lines, and Images.

### love.graphics.getDimensions() → width, height
Gets the width and height in pixels of the window.

### love.graphics.getFont() → font
Gets the current Font object.

### love.graphics.getFrontFaceWinding() → winding
Gets whether triangles with clockwise- or counterclockwise-ordered vertices are considered front-facing.

This is designed for use in combination with Mesh face culling. Other love.graphics shapes, lines, and sprites are not guaranteed to have a specific winding order to their internal vertices.

### love.graphics.getHeight() → height
Gets the height in pixels of the window.

### love.graphics.getImageFormats() → formats
Gets the raw and compressed pixel formats usable for Images, and whether each is supported.

### love.graphics.getLineJoin() → join
Gets the line join style.

### love.graphics.getLineStyle() → style
Gets the line style.

### love.graphics.getLineWidth() → width
Gets the current line width.

### love.graphics.getMeshCullMode() → mode
Gets whether back-facing triangles in a Mesh are culled.

Mesh face culling is designed for use with low level custom hardware-accelerated 3D rendering via custom vertex attributes on Meshes, custom vertex shaders, and depth testing with a depth buffer.

### love.graphics.getPixelDimensions() → pixelwidth, pixelheight
Gets the width and height in pixels of the window.

love.graphics.getDimensions gets the dimensions of the window in units scaled by the screen's DPI scale factor, rather than pixels. Use getDimensions for calculations related to drawing to the screen and using the graphics coordinate system (calculating the center of the screen, for example), and getPixelDimensions only when dealing specifically with underlying pixels (pixel-related calculations in a pixel Shader, for example).

### love.graphics.getPixelHeight() → pixelheight
Gets the height in pixels of the window.

The graphics coordinate system and DPI scale factor, rather than raw pixels. Use getHeight for calculations related to drawing to the screen and using the coordinate system (calculating the center of the screen, for example), and getPixelHeight only when dealing specifically with underlying pixels (pixel-related calculations in a pixel Shader, for example).

### love.graphics.getPixelWidth() → pixelwidth
Gets the width in pixels of the window.

The graphics coordinate system and DPI scale factor, rather than raw pixels. Use getWidth for calculations related to drawing to the screen and using the coordinate system (calculating the center of the screen, for example), and getPixelWidth only when dealing specifically with underlying pixels (pixel-related calculations in a pixel Shader, for example).

### love.graphics.getPointSize() → size
Gets the point size.

### love.graphics.getRendererInfo() → name, version, vendor, device
Gets information about the system's video card and drivers.

### love.graphics.getScissor() → x, y, width, height
Gets the current scissor box.

### love.graphics.getShader() → shader
Gets the current Shader. Returns nil if none is set.

### love.graphics.getStackDepth() → depth
Gets the current depth of the transform / state stack (the number of pushes without corresponding pops).

### love.graphics.getStats() → stats
Gets performance-related rendering statistics.
- Variant 2: love.graphics.getStats(stats) → stats
  This variant accepts an existing table to fill in, instead of creating a new one.

### love.graphics.getStencilTest() → comparemode, comparevalue
Gets the current stencil test configuration.

When stencil testing is enabled, the geometry of everything that is drawn afterward will be clipped / stencilled out based on a comparison between the arguments of this function and the stencil value of each pixel that the geometry touches. The stencil values of pixels are affected via love.graphics.stencil.

Each Canvas has its own per-pixel stencil values.

### love.graphics.getSupported() → features
Gets the optional graphics features and whether they're supported on the system.

Some older or low-end systems don't always support all graphics features.

### love.graphics.getSystemLimits() → limits
Gets the system-dependent maximum values for love.graphics features.

### love.graphics.getTextureTypes() → texturetypes
Gets the available texture types, and whether each is supported.

### love.graphics.getWidth() → width
Gets the width in pixels of the window.

### love.graphics.intersectScissor(x, y, width, height)
Sets the scissor to the rectangle created by the intersection of the specified rectangle with the existing scissor.  If no scissor is active yet, it behaves like love.graphics.setScissor.

The scissor limits the drawing area to a specified rectangle. This affects all graphics calls, including love.graphics.clear.

The dimensions of the scissor is unaffected by graphical transformations (translate, scale, ...).

### love.graphics.inverseTransformPoint(screenX, screenY) → globalX, globalY
Converts the given 2D position from screen-space into global coordinates.

This effectively applies the reverse of the current graphics transformations to the given position. A similar Transform:inverseTransformPoint method exists for Transform objects.

### love.graphics.isActive() → active
Gets whether the graphics module is able to be used. If it is not active, love.graphics function and method calls will not work correctly and may cause the program to crash.
The graphics module is inactive if a window is not open, or if the app is in the background on iOS. Typically the app's execution will be automatically paused by the system, in the latter case.

### love.graphics.isGammaCorrect() → gammacorrect
Gets whether gamma-correct rendering is supported and enabled. It can be enabled by setting t.gammacorrect = true in love.conf.

Not all devices support gamma-correct rendering, in which case it will be automatically disabled and this function will return false. It is supported on desktop systems which have graphics cards that are capable of using OpenGL 3 / DirectX 10, and iOS devices that can use OpenGL ES 3.

### love.graphics.isWireframe() → wireframe
Gets whether wireframe mode is used when drawing.

### love.graphics.line(x1, y1, x2, y2, ...)
Draws lines between points.
- Variant 2: love.graphics.line(points)

### love.graphics.newArrayImage(slices, settings) → image
Creates a new array Image.

An array image / array texture is a single object which contains multiple 'layers' or 'slices' of 2D sub-images. It can be thought of similarly to a texture atlas or sprite sheet, but it doesn't suffer from the same tile / quad bleeding artifacts that texture atlases do – although every sub-image must have the same dimensions.

A specific layer of an array image can be drawn with love.graphics.drawLayer / SpriteBatch:addLayer, or with the Quad variant of love.graphics.draw and Quad:setLayer, or via a custom Shader.

To use an array image in a Shader, it must be declared as a ArrayImage or sampler2DArray type (instead of Image or sampler2D). The Texel(ArrayImage image, vec3 texturecoord) shader function must be used to get pixel colors from a slice of the array image. The vec3 argument contains the texture coordinate in the first two components, and the 0-based slice index in the third component.

### love.graphics.newCanvas() → canvas
Creates a new Canvas object for offscreen rendering.
- Variant 2: love.graphics.newCanvas(width, height) → canvas
- Variant 3: love.graphics.newCanvas(width, height, settings) → canvas
  Creates a 2D or cubemap Canvas using the given settings.
  
  Some Canvas formats have higher system requirements than the default format. Use love.graphics.getCanvasFormats to check for support.
- Variant 4: love.graphics.newCanvas(width, height, layers, settings) → canvas
  Creates a volume or array texture-type Canvas.

### love.graphics.newCubeImage(filename, settings) → image
Creates a new cubemap Image.

Cubemap images have 6 faces (sides) which represent a cube. They can't be rendered directly, they can only be used in Shader code (and sent to the shader via Shader:send).

To use a cubemap image in a Shader, it must be declared as a CubeImage or samplerCube type (instead of Image or sampler2D). The Texel(CubeImage image, vec3 direction) shader function must be used to get pixel colors from the cubemap. The vec3 argument is a normalized direction from the center of the cube, rather than explicit texture coordinates.

Each face in a cubemap image must have square dimensions.

For variants of this function which accept a single image containing multiple cubemap faces, they must be laid out in one of the following forms in the image:

   +y

+z +x -z

   -y

   -x

or:

   +y

-x +z +x -z

   -y

or:

+x

-x

+y

-y

+z

-z

or:

+x -x +y -y +z -z
- Variant 2: love.graphics.newCubeImage(faces, settings) → image
  Creates a cubemap Image given a different image file for each cube face.

### love.graphics.newFont(filename) → font
Creates a new Font from a TrueType Font or BMFont file. Created fonts are not cached, in that calling this function with the same arguments will always create a new Font object.

All variants which accept a filename can also accept a Data object instead.
- Variant 2: love.graphics.newFont(filename, size, hinting='normal', dpiscale=love.graphics.getDPIScale()) → font
  Create a new TrueType font.
- Variant 3: love.graphics.newFont(filename, imagefilename) → font
  Create a new BMFont.
- Variant 4: love.graphics.newFont(size=12, hinting='normal', dpiscale=love.graphics.getDPIScale()) → font
  Create a new instance of the default font (Vera Sans) with a custom size.

### love.graphics.newImage(filename, settings) → image
Creates a new Image from a filepath, FileData, an ImageData, or a CompressedImageData, and optionally generates or specifies mipmaps for the image.
- Variant 2: love.graphics.newImage(fileData, settings) → image
- Variant 3: love.graphics.newImage(imageData, settings) → image
- Variant 4: love.graphics.newImage(compressedImageData, settings) → image

### love.graphics.newImageFont(filename, glyphs, extraspacing=0) → font
Creates a new specifically formatted image.

In versions prior to 0.9.0, LÖVE expects ISO 8859-1 encoding for the glyphs string.
- Variant 2: love.graphics.newImageFont(imageData, glyphs, extraspacing=0) → font

### love.graphics.newMesh(vertices, mode='fan', usage='dynamic') → mesh
Creates a new Mesh.

Use Mesh:setTexture if the Mesh should be textured with an Image or Canvas when it's drawn.

In versions prior to 11.0, color and byte component values were within the range of 0 to 255 instead of 0 to 1.
- Variant 2: love.graphics.newMesh(vertexcount, mode='fan', usage='dynamic') → mesh
  Creates a standard Mesh with the specified number of vertices.
  
  Mesh:setVertices or Mesh:setVertex and Mesh:setDrawRange can be used to specify vertex information once the Mesh is created.
- Variant 3: love.graphics.newMesh(vertexformat, vertices, mode='fan', usage='dynamic') → mesh
  Creates a Mesh with custom vertex attributes and the specified vertex data.
  
  The values in each vertex table are in the same order as the vertex attributes in the specified vertex format. If no value is supplied for a specific vertex attribute component, it will be set to a default value of 0 if its data type is 'float', or 1 if its data type is 'byte'.
  
  If the data type of an attribute is 'float', components can be in the range 1 to 4, if the data type is 'byte' it must be 4.
  
  If a custom vertex attribute uses the name 'VertexPosition', 'VertexTexCoord', or 'VertexColor', then the vertex data for that vertex attribute will be used for the standard vertex positions, texture coordinates, or vertex colors respectively, when drawing the Mesh. Otherwise a Vertex Shader is required in order to make use of the vertex attribute when the Mesh is drawn.
  
  A Mesh '''must''' have a 'VertexPosition' attribute in order to be drawn, but it can be attached from a different Mesh via Mesh:attachAttribute.
  
  To use a custom named vertex attribute in a Vertex Shader, it must be declared as an attribute variable of the same name. Variables can be sent from Vertex Shader code to Pixel Shader code by making a varying variable. For example:
  
  ''Vertex Shader code''
  
  attribute vec2 CoolVertexAttribute;
  
  varying vec2 CoolVariable;
  
  vec4 position(mat4 transform_projection, vec4 vertex_position)
  
  {
  
      CoolVariable = CoolVertexAttribute;
  
      return transform_projection * vertex_position;
  
  }
  
  ''Pixel Shader code''
  
  varying vec2 CoolVariable;
  
  vec4 effect(vec4 color, Image tex, vec2 texcoord, vec2 pixcoord)
  
  {
  
      vec4 texcolor = Texel(tex, texcoord + CoolVariable);
  
      return texcolor * color;
  
  }
- Variant 4: love.graphics.newMesh(vertexformat, vertexcount, mode='fan', usage='dynamic') → mesh
  Creates a Mesh with custom vertex attributes and the specified number of vertices.
  
  Each vertex attribute component is initialized to 0 if its data type is 'float', or 1 if its data type is 'byte'. Vertex Shader is required in order to make use of the vertex attribute when the Mesh is drawn.
  
  A Mesh '''must''' have a 'VertexPosition' attribute in order to be drawn, but it can be attached from a different Mesh via Mesh:attachAttribute.
- Variant 5: love.graphics.newMesh(vertexcount, texture, mode='fan') → mesh
  Mesh:setVertices or Mesh:setVertex and Mesh:setDrawRange can be used to specify vertex information once the Mesh is created.

### love.graphics.newParticleSystem(image, buffer=1000) → system
Creates a new ParticleSystem.
- Variant 2: love.graphics.newParticleSystem(texture, buffer=1000) → system

### love.graphics.newQuad(x, y, width, height, sw, sh) → quad
Creates a new Quad.

The purpose of a Quad is to use a fraction of an image to draw objects, as opposed to drawing entire image. It is most useful for sprite sheets and atlases: in a sprite atlas, multiple sprites reside in same image, quad is used to draw a specific sprite from that image; in animated sprites with all frames residing in the same image, quad is used to draw specific frame from the animation.
- Variant 2: love.graphics.newQuad(x, y, width, height, texture) → quad

### love.graphics.newShader(code) → shader
Creates a new Shader object for hardware-accelerated vertex and pixel effects. A Shader contains either vertex shader code, pixel shader code, or both.

Shaders are small programs which are run on the graphics card when drawing. Vertex shaders are run once for each vertex (for example, an image has 4 vertices - one at each corner. A Mesh might have many more.) Pixel shaders are run once for each pixel on the screen which the drawn object touches. Pixel shader code is executed after all the object's vertices have been processed by the vertex shader.
- Variant 2: love.graphics.newShader(pixelcode, vertexcode) → shader

### love.graphics.newSpriteBatch(image, maxsprites=1000) → spriteBatch
Creates a new SpriteBatch object.
- Variant 2: love.graphics.newSpriteBatch(image, maxsprites=1000, usage='dynamic') → spriteBatch
- Variant 3: love.graphics.newSpriteBatch(texture, maxsprites=1000, usage='dynamic') → spriteBatch

### love.graphics.newText(font, textstring) → text
Creates a new drawable Text object.
- Variant 2: love.graphics.newText(font, coloredtext) → text

### love.graphics.newVideo(filename) → video
Creates a new drawable Video. Currently only Ogg Theora video files are supported.
- Variant 2: love.graphics.newVideo(videostream) → video
- Variant 3: love.graphics.newVideo(filename, settings) → video
- Variant 4: love.graphics.newVideo(filename, loadaudio) → video
- Variant 5: love.graphics.newVideo(videostream, loadaudio) → video

### love.graphics.newVolumeImage(layers, settings) → image
Creates a new volume (3D) Image.

Volume images are 3D textures with width, height, and depth. They can't be rendered directly, they can only be used in Shader code (and sent to the shader via Shader:send).

To use a volume image in a Shader, it must be declared as a VolumeImage or sampler3D type (instead of Image or sampler2D). The Texel(VolumeImage image, vec3 texcoords) shader function must be used to get pixel colors from the volume image. The vec3 argument is a normalized texture coordinate with the z component representing the depth to sample at (ranging from 1).

Volume images are typically used as lookup tables in shaders for color grading, for example, because sampling using a texture coordinate that is partway in between two pixels can interpolate across all 3 dimensions in the volume image, resulting in a smooth gradient even when a small-sized volume image is used as the lookup table.

Array images are a much better choice than volume images for storing multiple different sprites in a single array image for directly drawing them.

### love.graphics.origin()
Resets the current coordinate transformation.

This function is always used to reverse any previous calls to love.graphics.rotate, love.graphics.scale, love.graphics.shear or love.graphics.translate. It returns the current transformation state to its defaults.

### love.graphics.points(x, y, ...)
Draws one or more points.
- Variant 2: love.graphics.points(points)
- Variant 3: love.graphics.points(points)
  Draws one or more individually colored points.
  
  In versions prior to 11.0, color component values were within the range of 0 to 255 instead of 0 to 1.
  
  The pixel grid is actually offset to the center of each pixel. So to get clean pixels drawn use 0.5 + integer increments.
  
  Points are not affected by size is always in pixels.

### love.graphics.polygon(mode, ...)
Draw a polygon.

Following the mode argument, this function can accept multiple numeric arguments or a single table of numeric arguments. In either case the arguments are interpreted as alternating x and y coordinates of the polygon's vertices.
- Variant 2: love.graphics.polygon(mode, vertices)

### love.graphics.pop()
Pops the current coordinate transformation from the transformation stack.

This function is always used to reverse a previous push operation. It returns the current transformation state to what it was before the last preceding push.

### love.graphics.present()
Displays the results of drawing operations on the screen.

This function is used when writing your own love.run function. It presents all the results of your drawing operations on the screen. See the example in love.run for a typical use of this function.

### love.graphics.print(text, x=0, y=0, r=0, sx=1, sy=sx, ox=0, oy=0, kx=0, ky=0)
Draws text on screen. If no Font is set, one will be created and set (once) if needed.

As of LOVE 0.7.1, when using translation and scaling functions while drawing text, this function assumes the scale occurs first.  If you don't script with this in mind, the text won't be in the right position, or possibly even on screen.

love.graphics.print and love.graphics.printf both support UTF-8 encoding. You'll also need a proper Font for special characters.

In versions prior to 11.0, color and byte component values were within the range of 0 to 255 instead of 0 to 1.
- Variant 2: love.graphics.print(coloredtext, x=0, y=0, angle=0, sx=1, sy=sx, ox=0, oy=0, kx=0, ky=0)
  The color set by love.graphics.setColor will be combined (multiplied) with the colors of the text.
- Variant 3: love.graphics.print(text, transform)
- Variant 4: love.graphics.print(coloredtext, transform)
  The color set by love.graphics.setColor will be combined (multiplied) with the colors of the text.
- Variant 5: love.graphics.print(text, font, transform)
- Variant 6: love.graphics.print(coloredtext, font, transform)

### love.graphics.printf(text, x, y, limit, align='left', r=0, sx=1, sy=sx, ox=0, oy=0, kx=0, ky=0)
Draws formatted text, with word wrap and alignment.

See additional notes in love.graphics.print.

The word wrap limit is applied before any scaling, rotation, and other coordinate transformations. Therefore the amount of text per line stays constant given the same wrap limit, even if the scale arguments change.

In version 0.9.2 and earlier, wrapping was implemented by breaking up words by spaces and putting them back together to make sure things fit nicely within the limit provided. However, due to the way this is done, extra spaces between words would end up missing when printed on the screen, and some lines could overflow past the provided wrap limit. In version 0.10.0 and newer this is no longer the case.

In versions prior to 11.0, color and byte component values were within the range of 0 to 255 instead of 0 to 1.
- Variant 2: love.graphics.printf(text, font, x, y, limit, align='left', r=0, sx=1, sy=sx, ox=0, oy=0, kx=0, ky=0)
- Variant 3: love.graphics.printf(text, transform, limit, align='left')
- Variant 4: love.graphics.printf(text, font, transform, limit, align='left')
- Variant 5: love.graphics.printf(coloredtext, x, y, limit, align, angle=0, sx=1, sy=sx, ox=0, oy=0, kx=0, ky=0)
  The color set by love.graphics.setColor will be combined (multiplied) with the colors of the text.
- Variant 6: love.graphics.printf(coloredtext, font, x, y, limit, align='left', angle=0, sx=1, sy=sx, ox=0, oy=0, kx=0, ky=0)
  The color set by love.graphics.setColor will be combined (multiplied) with the colors of the text.
- Variant 7: love.graphics.printf(coloredtext, transform, limit, align='left')
  The color set by love.graphics.setColor will be combined (multiplied) with the colors of the text.
- Variant 8: love.graphics.printf(coloredtext, font, transform, limit, align='left')

### love.graphics.push()
Copies and pushes the current coordinate transformation to the transformation stack.

This function is always used to prepare for a corresponding pop operation later. It stores the current coordinate transformation state into the transformation stack and keeps it active. Later changes to the transformation can be undone by using the pop operation, which returns the coordinate transform to the state it was in before calling push.
- Variant 2: love.graphics.push(stack)
  Pushes a specific type of state to the stack.

### love.graphics.rectangle(mode, x, y, width, height)
Draws a rectangle.
- Variant 2: love.graphics.rectangle(mode, x, y, width, height, rx, ry=rx, segments)
  Draws a rectangle with rounded corners.

### love.graphics.replaceTransform(transform)
Replaces the current coordinate transformation with the given Transform object.

### love.graphics.reset()
Resets the current graphics settings.

Calling reset makes the current drawing color white, the current background color black, disables any active color component masks, disables wireframe mode and resets the current graphics transformation to the origin. It also sets both the point and line drawing modes to smooth and their sizes to 1.0.

### love.graphics.rotate(angle)
Rotates the coordinate system in two dimensions.

Calling this function affects all future drawing operations by rotating the coordinate system around the origin by the given amount of radians. This change lasts until love.draw() exits.

### love.graphics.scale(sx, sy=sx)
Scales the coordinate system in two dimensions.

By default the coordinate system in LÖVE corresponds to the display pixels in horizontal and vertical directions one-to-one, and the x-axis increases towards the right while the y-axis increases downwards. Scaling the coordinate system changes this relation.

After scaling by sx and sy, all coordinates are treated as if they were multiplied by sx and sy. Every result of a drawing operation is also correspondingly scaled, so scaling by (2, 2) for example would mean making everything twice as large in both x- and y-directions. Scaling by a negative value flips the coordinate system in the corresponding direction, which also means everything will be drawn flipped or upside down, or both. Scaling by zero is not a useful operation.

Scale and translate are not commutative operations, therefore, calling them in different orders will change the outcome.

Scaling lasts until love.draw() exits.

### love.graphics.setBackgroundColor(red, green, blue, alpha=1)
Sets the background color.
- Variant 2: love.graphics.setBackgroundColor(rgba)

### love.graphics.setBlendMode(mode)
Sets the blending mode.
- Variant 2: love.graphics.setBlendMode(mode, alphamode='alphamultiply')
  The default 'alphamultiply' alpha mode should normally be preferred except when drawing content with pre-multiplied alpha. If content is drawn to a Canvas using the 'alphamultiply' mode, the Canvas texture will have pre-multiplied alpha afterwards, so the 'premultiplied' alpha mode should generally be used when drawing a Canvas to the screen.

### love.graphics.setCanvas(canvas, mipmap=1)
Captures drawing operations to a Canvas.
- Variant 2: love.graphics.setCanvas()
  Resets the render target to the screen, i.e. re-enables drawing to the screen.
- Variant 3: love.graphics.setCanvas(canvas1, canvas2, ...)
  Sets the render target to multiple simultaneous 2D Canvases. All drawing operations until the next ''love.graphics.setCanvas'' call will be redirected to the specified canvases and not shown on the screen.
  
  Normally all drawing operations will draw only to the first canvas passed to the function, but that can be changed if a pixel shader is used with the void effect function instead of the regular vec4 effect.
  
  All canvas arguments must have the same widths and heights and the same texture type. Not all computers which support Canvases will support multiple render targets. If love.graphics.isSupported('multicanvas') returns true, at least 4 simultaneously active canvases are supported.
- Variant 4: love.graphics.setCanvas(canvas, slice, mipmap=1)
  Sets the render target to the specified layer/slice and mipmap level of the given non-2D Canvas. All drawing operations until the next ''love.graphics.setCanvas'' call will be redirected to the Canvas and not shown on the screen.
- Variant 5: love.graphics.setCanvas(setup)
  Sets the active render target(s) and active stencil and depth buffers based on the specified setup information. All drawing operations until the next ''love.graphics.setCanvas'' call will be redirected to the specified Canvases and not shown on the screen.
  
  The RenderTargetSetup parameters can either be a Canvas|[1]|The Canvas to use for this active render target.}}
  
  {{param|number|mipmap (1)|The mipmap level to render to, for Canvases with [[Texture:getMipmapCount|mipmaps.}}
  
  {{param|number|layer (1)|Only used for Volume and Array-type Canvases. For Array textures this is the array layer to render to. For volume textures this is the depth slice.}}
  
  {{param|number|face (1)|Only used for Cubemap-type Canvases. The cube face index to render to (between 1 and 6)}}

### love.graphics.setColor(red, green, blue, alpha=1)
Sets the color used for drawing.

In versions prior to 11.0, color component values were within the range of 0 to 255 instead of 0 to 1.
- Variant 2: love.graphics.setColor(rgba)

### love.graphics.setColorMask(red, green, blue, alpha)
Sets the color mask. Enables or disables specific color components when rendering and clearing the screen. For example, if '''red''' is set to '''false''', no further changes will be made to the red component of any pixels.
- Variant 2: love.graphics.setColorMask()
  Disables color masking.

### love.graphics.setDefaultFilter(min, mag=min, anisotropy=1)
Sets the default scaling filters used with Images, Canvases, and Fonts.

### love.graphics.setDepthMode(comparemode, write)
Configures depth testing and writing to the depth buffer.

This is low-level functionality designed for use with custom vertex shaders and Meshes with custom vertex attributes. No higher level APIs are provided to set the depth of 2D graphics such as shapes, lines, and Images.
- Variant 2: love.graphics.setDepthMode()
  Disables depth testing and depth writes.

### love.graphics.setFont(font)
Set an already-loaded Font as the current font or create and load a new one from the file and size.

It's recommended that Font objects are created with love.graphics.newFont in the loading stage and then passed to this function in the drawing stage.

### love.graphics.setFrontFaceWinding(winding)
Sets whether triangles with clockwise- or counterclockwise-ordered vertices are considered front-facing.

This is designed for use in combination with Mesh face culling. Other love.graphics shapes, lines, and sprites are not guaranteed to have a specific winding order to their internal vertices.

### love.graphics.setLineJoin(join)
Sets the line join style. See LineJoin for the possible options.

### love.graphics.setLineStyle(style)
Sets the line style.

### love.graphics.setLineWidth(width)
Sets the line width.

### love.graphics.setMeshCullMode(mode)
Sets whether back-facing triangles in a Mesh are culled.

This is designed for use with low level custom hardware-accelerated 3D rendering via custom vertex attributes on Meshes, custom vertex shaders, and depth testing with a depth buffer.

By default, both front- and back-facing triangles in Meshes are rendered.

### love.graphics.setNewFont(size=12) → font
Creates and sets a new Font.
- Variant 2: love.graphics.setNewFont(filename, size=12) → font
- Variant 3: love.graphics.setNewFont(file, size=12) → font
- Variant 4: love.graphics.setNewFont(data, size=12) → font
- Variant 5: love.graphics.setNewFont(rasterizer) → font

### love.graphics.setPointSize(size)
Sets the point size.

### love.graphics.setScissor(x, y, width, height)
Sets or disables scissor.

The scissor limits the drawing area to a specified rectangle. This affects all graphics calls, including love.graphics.clear. 

The dimensions of the scissor is unaffected by graphical transformations (translate, scale, ...).
- Variant 2: love.graphics.setScissor()
  Disables scissor.

### love.graphics.setShader(shader)
Sets or resets a Shader as the current pixel effect or vertex shaders. All drawing operations until the next ''love.graphics.setShader'' will be drawn using the Shader object specified.
- Variant 2: love.graphics.setShader()
  Disables shaders, allowing unfiltered drawing operations.

### love.graphics.setStencilTest(comparemode, comparevalue)
Configures or disables stencil testing.

When stencil testing is enabled, the geometry of everything that is drawn afterward will be clipped / stencilled out based on a comparison between the arguments of this function and the stencil value of each pixel that the geometry touches. The stencil values of pixels are affected via love.graphics.stencil.
- Variant 2: love.graphics.setStencilTest()
  Disables stencil testing.

### love.graphics.setWireframe(enable)
Sets whether wireframe lines will be used when drawing.

### love.graphics.shear(kx, ky)
Shears the coordinate system.

### love.graphics.stencil(stencilfunction, action='replace', value=1, keepvalues=false)
Draws geometry as a stencil.

The geometry drawn by the supplied function sets invisible stencil values of pixels, instead of setting pixel colors. The stencil buffer (which contains those stencil values) can act like a mask / stencil - love.graphics.setStencilTest can be used afterward to determine how further rendering is affected by the stencil values in each pixel.

Stencil values are integers within the range of 255.

### love.graphics.transformPoint(globalX, globalY) → screenX, screenY
Converts the given 2D position from global coordinates into screen-space.

This effectively applies the current graphics transformations to the given position. A similar Transform:transformPoint method exists for Transform objects.

### love.graphics.translate(dx, dy)
Translates the coordinate system in two dimensions.

When this function is called with two numbers, dx, and dy, all the following drawing operations take effect as if their x and y coordinates were x+dx and y+dy. 

Scale and translate are not commutative operations, therefore, calling them in different orders will change the outcome.

This change lasts until love.draw() exits or else a love.graphics.pop reverts to a previous love.graphics.push.

Translating using whole numbers will prevent tearing/blurring of images and fonts draw after translating.

### love.graphics.validateShader(gles, code) → status, message
Validates shader code. Check if specified shader code does not contain any errors.
- Variant 2: love.graphics.validateShader(gles, pixelcode, vertexcode) → status, message

### Canvas < Texture
A Canvas is used for off-screen rendering. Think of it as an invisible screen that you can draw to, but that will not be visible until you draw it to the actual visible screen. It is also known as "render to texture".

By drawing things that do not change position often (such as background items) to the Canvas, and then drawing the entire Canvas instead of each item,  you can reduce the number of draw operations performed each frame.

In versions prior to love.graphics.isSupported("canvas") could be used to check for support at runtime.
Constructors: newCanvas, getCanvas
- generateMipmaps()
  Generates mipmaps for the Canvas, based on the contents of the highest-resolution mipmap level.
  
  The Canvas must be created with mipmaps set to a MipmapMode other than 'none' for this function to work. It should only be called while the Canvas is not the active render target.
  
  If the mipmap mode is set to 'auto', this function is automatically called inside love.graphics.setCanvas when switching from this Canvas to another Canvas or to the main screen.
- getMSAA() → samples
  Gets the number of multisample antialiasing (MSAA) samples used when drawing to the Canvas.
  
  This may be different than the number used as an argument to love.graphics.newCanvas if the system running LÖVE doesn't support that number.
- getMipmapMode() → mode
  Gets the MipmapMode this Canvas was created with.
- newImageData() → data
  Generates ImageData from the contents of the Canvas.
- renderTo(func, ...)
  Render to the Canvas using a function.
  
  This is a shortcut to love.graphics.setCanvas:
  
  canvas:renderTo( func )
  
  is the same as
  
  love.graphics.setCanvas( canvas )
  
  func()
  
  love.graphics.setCanvas()

### Drawable < Object
Superclass for all things that can be drawn on screen. This is an abstract type that can't be created directly.

### Font < Object
Defines the shape of characters that can be drawn onto the screen.
Constructors: getFont, newFont, setNewFont, newImageFont
- getAscent() → ascent
  Gets the ascent of the Font.
  
  The ascent spans the distance between the baseline and the top of the glyph that reaches farthest from the baseline.
- getBaseline() → baseline
  Gets the baseline of the Font.
  
  Most scripts share the notion of a baseline: an imaginary horizontal line on which characters rest. In some scripts, parts of glyphs lie below the baseline.
- getDPIScale() → dpiscale
  Gets the DPI scale factor of the Font.
  
  The DPI scale factor represents relative pixel density. A DPI scale factor of 2 means the font's glyphs have twice the pixel density in each dimension (4 times as many pixels in the same area) compared to a font with a DPI scale factor of 1.
  
  The font size of TrueType fonts is scaled internally by the font's specified DPI scale factor. By default, LÖVE uses the screen's DPI scale factor when creating TrueType fonts.
- getDescent() → descent
  Gets the descent of the Font.
  
  The descent spans the distance between the baseline and the lowest descending glyph in a typeface.
- getFilter() → min, mag, anisotropy
  Gets the filter mode for a font.
- getHeight() → height
  Gets the height of the Font.
  
  The height of the font is the size including any spacing; the height which it will need.
- getKerning(leftchar, rightchar) → kerning
  Gets the kerning between two characters in the Font.
  
  Kerning is normally handled automatically in love.graphics.print, Text objects, Font:getWidth, Font:getWrap, etc. This function is useful when stitching text together manually.
- getLineHeight() → height
  Gets the line height.
  
  This will be the value previously set by Font:setLineHeight, or 1.0 by default.
- getWidth(text) → width
  Determines the maximum width (accounting for newlines) taken by the given string.
- getWrap(text, wraplimit) → width, wrappedtext
  Gets formatting information for text, given a wrap limit.
  
  This function accounts for newlines correctly (i.e. '\n').
- hasGlyphs(text) → hasglyph
  Gets whether the Font can render a character or string.
- setFallbacks(fallbackfont1, ...)
  Sets the fallback fonts. When the Font doesn't contain a glyph, it will substitute the glyph from the next subsequent fallback Fonts. This is akin to setting a 'font stack' in Cascading Style Sheets (CSS).
- setFilter(min, mag, anisotropy=1)
  Sets the filter mode for a font.
- setLineHeight(height)
  Sets the line height.
  
  When rendering the font in lines the actual height will be determined by the line height multiplied by the height of the font. The default is 1.0.

### Image < Texture
Drawable image type.
Constructors: newImage, newVolumeImage, newCubeImage, newArrayImage
- isCompressed() → compressed
  Gets whether the Image was created from CompressedData.
  
  Compressed images take up less space in VRAM, and drawing a compressed image will generally be more efficient than drawing one created from raw pixel data.
- isFormatLinear() → linear
  Gets whether the Image was created with the linear (non-gamma corrected) flag set to true.
  
  This method always returns false when gamma-correct rendering is not enabled.
- replacePixels(data, slice=1, mipmap=1, x=0, y=0, reloadmipmaps=false)
  Replace the contents of an Image.

### Mesh < Drawable
A 2D polygon mesh used for drawing arbitrary textured shapes.
Constructors: newMesh
- attachAttribute(name, mesh)
  Attaches a vertex attribute from a different Mesh onto this Mesh, for use when drawing. This can be used to share vertex attribute data between several different Meshes.
- detachAttribute(name) → success
  Removes a previously attached vertex attribute from this Mesh.
- flush()
  Immediately sends all modified vertex data in the Mesh to the graphics card.
  
  Normally it isn't necessary to call this method as love.graphics.draw(mesh, ...) will do it automatically if needed, but explicitly using **Mesh:flush** gives more control over when the work happens.
  
  If this method is used, it generally shouldn't be called more than once (at most) between love.graphics.draw(mesh, ...) calls.
- getDrawMode() → mode
  Gets the mode used when drawing the Mesh.
- getDrawRange() → min, max
  Gets the range of vertices used when drawing the Mesh.
- getTexture() → texture
  Gets the texture (Image or Canvas) used when drawing the Mesh.
- getVertex(index) → attributecomponent, ...
  Gets the properties of a vertex in the Mesh.
  
  In versions prior to 11.0, color and byte component values were within the range of 0 to 255 instead of 0 to 1.
- getVertexAttribute(vertexindex, attributeindex) → value1, value2, ...
  Gets the properties of a specific attribute within a vertex in the Mesh.
  
  Meshes without a custom vertex format specified in love.graphics.newMesh have position as their first attribute, texture coordinates as their second attribute, and color as their third attribute.
- getVertexCount() → count
  Gets the total number of vertices in the Mesh.
- getVertexFormat() → format
  Gets the vertex format that the Mesh was created with.
- getVertexMap() → map
  Gets the vertex map for the Mesh. The vertex map describes the order in which the vertices are used when the Mesh is drawn. The vertices, vertex map, and mesh draw mode work together to determine what exactly is displayed on the screen.
  
  If no vertex map has been set previously via Mesh:setVertexMap, then this function will return nil in LÖVE 0.10.0+, or an empty table in 0.9.2 and older.
- isAttributeEnabled(name) → enabled
  Gets whether a specific vertex attribute in the Mesh is enabled. Vertex data from disabled attributes is not used when drawing the Mesh.
- setAttributeEnabled(name, enable)
  Enables or disables a specific vertex attribute in the Mesh. Vertex data from disabled attributes is not used when drawing the Mesh.
- setDrawMode(mode)
  Sets the mode used when drawing the Mesh.
- setDrawRange(start, count)
  Restricts the drawn vertices of the Mesh to a subset of the total.
- setTexture(texture)
  Sets the texture (Image or Canvas) used when drawing the Mesh.
- setVertex(index, attributecomponent, ...)
  Sets the properties of a vertex in the Mesh.
  
  In versions prior to 11.0, color and byte component values were within the range of 0 to 255 instead of 0 to 1.
- setVertexAttribute(vertexindex, attributeindex, value1, value2, ...)
  Sets the properties of a specific attribute within a vertex in the Mesh.
  
  Meshes without a custom vertex format specified in love.graphics.newMesh have position as their first attribute, texture coordinates as their second attribute, and color as their third attribute.
- setVertexMap(map)
  Sets the vertex map for the Mesh. The vertex map describes the order in which the vertices are used when the Mesh is drawn. The vertices, vertex map, and mesh draw mode work together to determine what exactly is displayed on the screen.
  
  The vertex map allows you to re-order or reuse vertices when drawing without changing the actual vertex parameters or duplicating vertices. It is especially useful when combined with different Mesh Draw Modes.
- setVertices(vertices, startvertex=1, count=all)
  Replaces a range of vertices in the Mesh with new ones. The total number of vertices in a Mesh cannot be changed after it has been created. This is often more efficient than calling Mesh:setVertex in a loop.

### ParticleSystem < Drawable
A ParticleSystem can be used to create particle effects like fire or smoke.

The particle system has to be created using update it in the update callback to see any changes in the particles emitted.

The particle system won't create any particles unless you call setParticleLifetime and setEmissionRate.
Constructors: newParticleSystem
- clone() → particlesystem
  Creates an identical copy of the ParticleSystem in the stopped state.
- emit(numparticles)
  Emits a burst of particles from the particle emitter.
- getBufferSize() → size
  Gets the maximum number of particles the ParticleSystem can have at once.
- getColors() → r1, g1, b1, a1, r2, g2, b2, a2, r8, g8, b8, a8
  Gets the series of colors applied to the particle sprite.
  
  In versions prior to 11.0, color component values were within the range of 0 to 255 instead of 0 to 1.
- getCount() → count
  Gets the number of particles that are currently in the system.
- getDirection() → direction
  Gets the direction of the particle emitter (in radians).
- getEmissionArea() → distribution, dx, dy, angle, directionRelativeToCenter
  Gets the area-based spawn parameters for the particles.
- getEmissionRate() → rate
  Gets the amount of particles emitted per second.
- getEmitterLifetime() → life
  Gets how long the particle system will emit particles (if -1 then it emits particles forever).
- getInsertMode() → mode
  Gets the mode used when the ParticleSystem adds new particles.
- getLinearAcceleration() → xmin, ymin, xmax, ymax
  Gets the linear acceleration (acceleration along the x and y axes) for particles.
  
  Every particle created will accelerate along the x and y axes between xmin,ymin and xmax,ymax.
- getLinearDamping() → min, max
  Gets the amount of linear damping (constant deceleration) for particles.
- getOffset() → ox, oy
  Gets the particle image's draw offset.
- getParticleLifetime() → min, max
  Gets the lifetime of the particles.
- getPosition() → x, y
  Gets the position of the emitter.
- getQuads() → quads
  Gets the series of Quads used for the particle sprites.
- getRadialAcceleration() → min, max
  Gets the radial acceleration (away from the emitter).
- getRotation() → min, max
  Gets the rotation of the image upon particle creation (in radians).
- getSizeVariation() → variation
  Gets the amount of size variation (0 meaning no variation and 1 meaning full variation between start and end).
- getSizes() → size1, size2, size8
  Gets the series of sizes by which the sprite is scaled. 1.0 is normal size. The particle system will interpolate between each size evenly over the particle's lifetime.
- getSpeed() → min, max
  Gets the speed of the particles.
- getSpin() → min, max, variation
  Gets the spin of the sprite.
- getSpinVariation() → variation
  Gets the amount of spin variation (0 meaning no variation and 1 meaning full variation between start and end).
- getSpread() → spread
  Gets the amount of directional spread of the particle emitter (in radians).
- getTangentialAcceleration() → min, max
  Gets the tangential acceleration (acceleration perpendicular to the particle's direction).
- getTexture() → texture
  Gets the texture (Image or Canvas) used for the particles.
- hasRelativeRotation() → enable
  Gets whether particle angles and rotations are relative to their velocities. If enabled, particles are aligned to the angle of their velocities and rotate relative to that angle.
- isActive() → active
  Checks whether the particle system is actively emitting particles.
- isPaused() → paused
  Checks whether the particle system is paused.
- isStopped() → stopped
  Checks whether the particle system is stopped.
- moveTo(x, y)
  Moves the position of the emitter. This results in smoother particle spawning behaviour than if ParticleSystem:setPosition is used every frame.
- pause()
  Pauses the particle emitter.
- reset()
  Resets the particle emitter, removing any existing particles and resetting the lifetime counter.
- setBufferSize(size)
  Sets the size of the buffer (the max allowed amount of particles in the system).
- setColors(r1, g1, b1, a1=1, ...)
  Sets a series of colors to apply to the particle sprite. The particle system will interpolate between each color evenly over the particle's lifetime.
  
  Arguments can be passed in groups of four, representing the components of the desired RGBA value, or as tables of RGBA component values, with a default alpha value of 1 if only three values are given. At least one color must be specified. A maximum of eight may be used.
  
  In versions prior to 11.0, color component values were within the range of 0 to 255 instead of 0 to 1.
- setDirection(direction)
  Sets the direction the particles will be emitted in.
- setEmissionArea(distribution, dx, dy, angle=0, directionRelativeToCenter=false)
  Sets area-based spawn parameters for the particles. Newly created particles will spawn in an area around the emitter based on the parameters to this function.
- setEmissionRate(rate)
  Sets the amount of particles emitted per second.
- setEmitterLifetime(life)
  Sets how long the particle system should emit particles (if -1 then it emits particles forever).
- setInsertMode(mode)
  Sets the mode to use when the ParticleSystem adds new particles.
- setLinearAcceleration(xmin, ymin, xmax=xmin, ymax=ymin)
  Sets the linear acceleration (acceleration along the x and y axes) for particles.
  
  Every particle created will accelerate along the x and y axes between xmin,ymin and xmax,ymax.
- setLinearDamping(min, max=min)
  Sets the amount of linear damping (constant deceleration) for particles.
- setOffset(x, y)
  Set the offset position which the particle sprite is rotated around.
  
  If this function is not used, the particles rotate around their center.
- setParticleLifetime(min, max=min)
  Sets the lifetime of the particles.
- setPosition(x, y)
  Sets the position of the emitter.
- setQuads(quad1, ...)
  Sets a series of Quads to use for the particle sprites. Particles will choose a Quad from the list based on the particle's current lifetime, allowing for the use of animated sprite sheets with ParticleSystems.
- setRadialAcceleration(min, max=min)
  Set the radial acceleration (away from the emitter).
- setRelativeRotation(enable)
  Sets whether particle angles and rotations are relative to their velocities. If enabled, particles are aligned to the angle of their velocities and rotate relative to that angle.
- setRotation(min, max=min)
  Sets the rotation of the image upon particle creation (in radians).
- setSizeVariation(variation)
  Sets the amount of size variation (0 meaning no variation and 1 meaning full variation between start and end).
- setSizes(size1, size2, size8)
  Sets a series of sizes by which to scale a particle sprite. 1.0 is normal size. The particle system will interpolate between each size evenly over the particle's lifetime.
  
  At least one size must be specified. A maximum of eight may be used.
- setSpeed(min, max=min)
  Sets the speed of the particles.
- setSpin(min, max=min)
  Sets the spin of the sprite.
- setSpinVariation(variation)
  Sets the amount of spin variation (0 meaning no variation and 1 meaning full variation between start and end).
- setSpread(spread)
  Sets the amount of spread for the system.
- setTangentialAcceleration(min, max=min)
  Sets the tangential acceleration (acceleration perpendicular to the particle's direction).
- setTexture(texture)
  Sets the texture (Image or Canvas) to be used for the particles.
- start()
  Starts the particle emitter.
- stop()
  Stops the particle emitter, resetting the lifetime counter.
- update(dt)
  Updates the particle system; moving, creating and killing particles.

### Quad < Object
A quadrilateral (a polygon with four sides and four corners) with texture coordinate information.

Quads can be used to select part of a texture to draw. In this way, one large texture atlas can be loaded, and then split up into sub-images.
Constructors: newQuad
- getTextureDimensions() → sw, sh
  Gets reference texture dimensions initially specified in love.graphics.newQuad.
- getViewport() → x, y, w, h
  Gets the current viewport of this Quad.
- setViewport(x, y, w, h, sw, sh)
  Sets the texture coordinates according to a viewport.

### Shader < Object
A Shader is used for advanced hardware-accelerated pixel or vertex manipulation. These effects are written in a language based on GLSL (OpenGL Shading Language) with a few things simplified for easier coding.

Potential uses for shaders include HDR/bloom, motion blur, grayscale/invert/sepia/any kind of color effect, reflection/refraction, distortions, bump mapping, and much more! Here is a collection of basic shaders and good starting point to learn: https://github.com/vrld/moonshine
Constructors: getShader, newShader
- getWarnings() → warnings
  Returns any warning and error messages from compiling the shader code. This can be used for debugging your shaders if there's anything the graphics hardware doesn't like.
- hasUniform(name) → hasuniform
  Gets whether a uniform / extern variable exists in the Shader.
  
  If a graphics driver's shader compiler determines that a uniform / extern variable doesn't affect the final output of the shader, it may optimize the variable out. This function will return false in that case.
- send(name, number, ...)
  Sends one or more values to a special (''uniform'') variable inside the shader. Uniform variables have to be marked using the ''uniform'' or ''extern'' keyword, e.g.
  
  uniform float time;  // 'float' is the typical number type used in GLSL shaders.
  
  uniform float varsvec2 light_pos;
  
  uniform vec4 colors[4;
  
  The corresponding send calls would be
  
  shader:send('time', t)
  
  shader:send('vars',a,b)
  
  shader:send('light_pos', {light_x, light_y})
  
  shader:send('colors', {r1, g1, b1, a1},  {r2, g2, b2, a2},  {r3, g3, b3, a3},  {r4, g4, b4, a4})
  
  Uniform / extern variables are read-only in the shader code and remain constant until modified by a Shader:send call. Uniform variables can be accessed in both the Vertex and Pixel components of a shader, as long as the variable is declared in each.
- sendColor(name, color, ...)
  Sends one or more colors to a special (''extern'' / ''uniform'') vec3 or vec4 variable inside the shader. The color components must be in the range of 1. The colors are gamma-corrected if global gamma-correction is enabled.
  
  Extern variables must be marked using the ''extern'' keyword, e.g.
  
  extern vec4 Color;
  
  The corresponding sendColor call would be
  
  shader:sendColor('Color', {r, g, b, a})
  
  Extern variables can be accessed in both the Vertex and Pixel stages of a shader, as long as the variable is declared in each.
  
  In versions prior to 11.0, color component values were within the range of 0 to 255 instead of 0 to 1.

### SpriteBatch < Drawable
Using a single image, draw any number of identical copies of the image using a single call to love.graphics.draw(). This can be used, for example, to draw repeating copies of a single background image with high performance.

A SpriteBatch can be even more useful when the underlying image is a texture atlas (a single image file containing many independent images); by adding Quads to the batch, different sub-images from within the atlas can be drawn.
Constructors: newSpriteBatch
- add(x, y, r=0, sx=1, sy=sx, ox=0, oy=0, kx=0, ky=0) → id
  Adds a sprite to the batch. Sprites are drawn in the order they are added.
- addLayer(layerindex, x=0, y=0, r=0, sx=1, sy=sx, ox=0, oy=0, kx=0, ky=0) → spriteindex
  Adds a sprite to a batch created with an Array Texture.
- attachAttribute(name, mesh)
  Attaches a per-vertex attribute from a Mesh onto this SpriteBatch, for use when drawing. This can be combined with a Shader to augment a SpriteBatch with per-vertex or additional per-sprite information instead of just having per-sprite colors.
  
  Each sprite in a SpriteBatch has 4 vertices in the following order: top-left, bottom-left, top-right, bottom-right. The index returned by SpriteBatch:add (and used by SpriteBatch:set) can used to determine the first vertex of a specific sprite with the formula 1 + 4 * ( id - 1 ).
- clear()
  Removes all sprites from the buffer.
- flush()
  Immediately sends all new and modified sprite data in the batch to the graphics card.
  
  Normally it isn't necessary to call this method as love.graphics.draw(spritebatch, ...) will do it automatically if needed, but explicitly using SpriteBatch:flush gives more control over when the work happens.
  
  If this method is used, it generally shouldn't be called more than once (at most) between love.graphics.draw(spritebatch, ...) calls.
- getBufferSize() → size
  Gets the maximum number of sprites the SpriteBatch can hold.
- getColor() → r, g, b, a
  Gets the color that will be used for the next add and set operations.
  
  If no color has been set with SpriteBatch:setColor or the current SpriteBatch color has been cleared, this method will return nil.
  
  In versions prior to 11.0, color component values were within the range of 0 to 255 instead of 0 to 1.
- getCount() → count
  Gets the number of sprites currently in the SpriteBatch.
- getTexture() → texture
  Gets the texture (Image or Canvas) used by the SpriteBatch.
- set(spriteindex, x, y, r=0, sx=1, sy=sx, ox=0, oy=0, kx=0, ky=0)
  Changes a sprite in the batch. This requires the sprite index returned by SpriteBatch:add or SpriteBatch:addLayer.
- setColor(r, g, b, a=1)
  Sets the color that will be used for the next add and set operations. Calling the function without arguments will disable all per-sprite colors for the SpriteBatch.
  
  In versions prior to 11.0, color component values were within the range of 0 to 255 instead of 0 to 1.
  
  In version 0.9.2 and older, the global color set with love.graphics.setColor will not work on the SpriteBatch if any of the sprites has its own color.
- setDrawRange(start, count)
  Restricts the drawn sprites in the SpriteBatch to a subset of the total.
- setLayer(spriteindex, layerindex, x=0, y=0, r=0, sx=1, sy=sx, ox=0, oy=0, kx=0, ky=0)
  Changes a sprite previously added with add or addLayer, in a batch created with an Array Texture.
- setTexture(texture)
  Sets the texture (Image or Canvas) used for the sprites in the batch, when drawing.

### Text < Drawable
Drawable text.
Constructors: newText
- add(textstring, x=0, y=0, angle=0, sx=1, sy=sx, ox=0, oy=0, kx=0, ky=0) → index
  Adds additional colored text to the Text object at the specified position.
- addf(textstring, wraplimit, align, x, y, angle=0, sx=1, sy=sx, ox=0, oy=0, kx=0, ky=0) → index
  Adds additional formatted / colored text to the Text object at the specified position.
  
  The word wrap limit is applied before any scaling, rotation, and other coordinate transformations. Therefore the amount of text per line stays constant given the same wrap limit, even if the scale arguments change.
- clear()
  Clears the contents of the Text object.
- getDimensions() → width, height
  Gets the width and height of the text in pixels.
- getFont() → font
  Gets the Font used with the Text object.
- getHeight() →  height 
  Gets the height of the text in pixels.
- getWidth() → width
  Gets the width of the text in pixels.
- set(textstring)
  Replaces the contents of the Text object with a new unformatted string.
- setFont(font)
  Replaces the Font used with the text.
- setf(textstring, wraplimit, align)
  Replaces the contents of the Text object with a new formatted string.

### Texture < Drawable
Superclass for drawable objects which represent a texture. All Textures can be drawn with Quads. This is an abstract type that can't be created directly.
- getDPIScale() → dpiscale
  Gets the DPI scale factor of the Texture.
  
  The DPI scale factor represents relative pixel density. A DPI scale factor of 2 means the texture has twice the pixel density in each dimension (4 times as many pixels in the same area) compared to a texture with a DPI scale factor of 1.
  
  For example, a texture with pixel dimensions of 100x100 with a DPI scale factor of 2 will be drawn as if it was 50x50. This is useful with high-dpi /  retina displays to easily allow swapping out higher or lower pixel density Images and Canvases without needing any extra manual scaling logic.
- getDepth() → depth
  Gets the depth of a Volume Texture. Returns 1 for 2D, Cubemap, and Array textures.
- getDepthSampleMode() → compare
  Gets the comparison mode used when sampling from a depth texture in a shader.
  
  Depth texture comparison modes are advanced low-level functionality typically used with shadow mapping in 3D.
- getDimensions() → width, height
  Gets the width and height of the Texture.
- getFilter() → min, mag, anisotropy
  Gets the filter mode of the Texture.
- getFormat() → format
  Gets the pixel format of the Texture.
- getHeight() → height
  Gets the height of the Texture.
- getLayerCount() → layers
  Gets the number of layers / slices in an Array Texture. Returns 1 for 2D, Cubemap, and Volume textures.
- getMipmapCount() → mipmaps
  Gets the number of mipmaps contained in the Texture. If the texture was not created with mipmaps, it will return 1.
- getMipmapFilter() → mode, sharpness
  Gets the mipmap filter mode for a Texture. Prior to 11.0 this method only worked on Images.
- getPixelDimensions() → pixelwidth, pixelheight
  Gets the width and height in pixels of the Texture.
  
  Texture:getDimensions gets the dimensions of the texture in units scaled by the texture's DPI scale factor, rather than pixels. Use getDimensions for calculations related to drawing the texture (calculating an origin offset, for example), and getPixelDimensions only when dealing specifically with pixels, for example when using Canvas:newImageData.
- getPixelHeight() → pixelheight
  Gets the height in pixels of the Texture.
  
  DPI scale factor, rather than pixels. Use getHeight for calculations related to drawing the texture (calculating an origin offset, for example), and getPixelHeight only when dealing specifically with pixels, for example when using Canvas:newImageData.
- getPixelWidth() → pixelwidth
  Gets the width in pixels of the Texture.
  
  DPI scale factor, rather than pixels. Use getWidth for calculations related to drawing the texture (calculating an origin offset, for example), and getPixelWidth only when dealing specifically with pixels, for example when using Canvas:newImageData.
- getTextureType() → texturetype
  Gets the type of the Texture.
- getWidth() → width
  Gets the width of the Texture.
- getWrap() → horiz, vert, depth
  Gets the wrapping properties of a Texture.
  
  This function returns the currently set horizontal and vertical wrapping modes for the texture.
- isReadable() → readable
  Gets whether the Texture can be drawn and sent to a Shader.
  
  Canvases created with stencil and/or depth PixelFormats are not readable by default, unless readable=true is specified in the settings table passed into love.graphics.newCanvas.
  
  Non-readable Canvases can still be rendered to.
- setDepthSampleMode(compare)
  Sets the comparison mode used when sampling from a depth texture in a shader. Depth texture comparison modes are advanced low-level functionality typically used with shadow mapping in 3D.
  
  When using a depth texture with a comparison mode set in a shader, it must be declared as a sampler2DShadow and used in a GLSL 3 Shader. The result of accessing the texture in the shader will return a float between 0 and 1, proportional to the number of samples (up to 4 samples will be used if bilinear filtering is enabled) that passed the test set by the comparison operation.
  
  Depth texture comparison can only be used with readable depth-formatted Canvases.
- setFilter(min, mag=min, anisotropy=1)
  Sets the filter mode of the Texture.
- setMipmapFilter(filtermode, sharpness=0)
  Sets the mipmap filter mode for a Texture. Prior to 11.0 this method only worked on Images.
  
  Mipmapping is useful when drawing a texture at a reduced scale. It can improve performance and reduce aliasing issues.
  
  In created with the mipmaps flag enabled for the mipmap filter to have any effect. In versions prior to 0.10.0 it's best to call this method directly after creating the image with love.graphics.newImage, to avoid bugs in certain graphics drivers.
  
  Due to hardware restrictions and driver bugs, in versions prior to 0.10.0 images that weren't loaded from a CompressedData must have power-of-two dimensions (64x64, 512x256, etc.) to use mipmaps.
- setWrap(horiz, vert=horiz, depth=horiz)
  Sets the wrapping properties of a Texture.
  
  This function sets the way a Texture is repeated when it is drawn with a Quad that is larger than the texture's extent, or when a custom Shader is used which uses texture coordinates outside of [0, 1]. A texture may be clamped or set to repeat in both horizontal and vertical directions.
  
  Clamped textures appear only once (with the edges of the texture stretching to fill the extent of the Quad), whereas repeated ones repeat as many times as there is room in the Quad.

### Video < Drawable
A drawable video.
Constructors: newVideo
- getDimensions() → width, height
  Gets the width and height of the Video in pixels.
- getFilter() → min, mag, anisotropy
  Gets the scaling filters used when drawing the Video.
- getHeight() → height
  Gets the height of the Video in pixels.
- getSource() → source
  Gets the audio Source used for playing back the video's audio. May return nil if the video has no audio, or if Video:setSource is called with a nil argument.
- getStream() → stream
  Gets the VideoStream object used for decoding and controlling the video.
- getWidth() → width
  Gets the width of the Video in pixels.
- isPlaying() → playing
  Gets whether the Video is currently playing.
- pause()
  Pauses the Video.
- play()
  Starts playing the Video. In order for the video to appear onscreen it must be drawn with love.graphics.draw.
- rewind()
  Rewinds the Video to the beginning.
- seek(offset)
  Sets the current playback position of the Video.
- setFilter(min, mag, anisotropy=1)
  Sets the scaling filters used when drawing the Video.
- setSource(source)
  Sets the audio Source used for playing back the video's audio. The audio Source also controls playback speed and synchronization.
- tell() → seconds
  Gets the current playback position of the Video.

---
## love.image

Provides an interface to decode encoded image data.

### CompressedImageFormat
Compressed image data formats. Here and here are a couple overviews of many of the formats.

Unlike traditional PNG or jpeg, these formats stay compressed in RAM and in the graphics card's VRAM. This is good for saving memory space as well as improving performance, since the graphics card will be able to keep more of the image's pixels in its fast-access cache when drawing it.
- DXT1: The DXT1 format. RGB data at 4 bits per pixel (compared to 32 bits for ImageData and regular Images.) Suitable for fully opaque images on desktop systems.
- DXT3: The DXT3 format. RGBA data at 8 bits per pixel. Smooth variations in opacity do not mix well with this format.
- DXT5: The DXT5 format. RGBA data at 8 bits per pixel. Recommended for images with varying opacity on desktop systems.
- BC4: The BC4 format (also known as 3Dc+ or ATI1.) Stores just the red channel, at 4 bits per pixel.
- BC4s: The signed variant of the BC4 format. Same as above but pixel values in the texture are in the range of 1 instead of 1 in shaders.
- BC5: The BC5 format (also known as 3Dc or ATI2.) Stores red and green channels at 8 bits per pixel.
- BC5s: The signed variant of the BC5 format.
- BC6h: The BC6H format. Stores half-precision floating-point RGB data in the range of 65504 at 8 bits per pixel. Suitable for HDR images on desktop systems.
- BC6hs: The signed variant of the BC6H format. Stores RGB data in the range of +65504.
- BC7: The BC7 format (also known as BPTC.) Stores RGB or RGBA data at 8 bits per pixel.
- ETC1: The ETC1 format. RGB data at 4 bits per pixel. Suitable for fully opaque images on older Android devices.
- ETC2rgb: The RGB variant of the ETC2 format. RGB data at 4 bits per pixel. Suitable for fully opaque images on newer mobile devices.
- ETC2rgba: The RGBA variant of the ETC2 format. RGBA data at 8 bits per pixel. Recommended for images with varying opacity on newer mobile devices.
- ETC2rgba1: The RGBA variant of the ETC2 format where pixels are either fully transparent or fully opaque. RGBA data at 4 bits per pixel.
- EACr: The single-channel variant of the EAC format. Stores just the red channel, at 4 bits per pixel.
- EACrs: The signed single-channel variant of the EAC format. Same as above but pixel values in the texture are in the range of 1 instead of 1 in shaders.
- EACrg: The two-channel variant of the EAC format. Stores red and green channels at 8 bits per pixel.
- EACrgs: The signed two-channel variant of the EAC format.
- PVR1rgb2: The 2 bit per pixel RGB variant of the PVRTC1 format. Stores RGB data at 2 bits per pixel. Textures compressed with PVRTC1 formats must be square and power-of-two sized.
- PVR1rgb4: The 4 bit per pixel RGB variant of the PVRTC1 format. Stores RGB data at 4 bits per pixel.
- PVR1rgba2: The 2 bit per pixel RGBA variant of the PVRTC1 format.
- PVR1rgba4: The 4 bit per pixel RGBA variant of the PVRTC1 format.
- ASTC4x4: The 4x4 pixels per block variant of the ASTC format. RGBA data at 8 bits per pixel.
- ASTC5x4: The 5x4 pixels per block variant of the ASTC format. RGBA data at 6.4 bits per pixel.
- ASTC5x5: The 5x5 pixels per block variant of the ASTC format. RGBA data at 5.12 bits per pixel.
- ASTC6x5: The 6x5 pixels per block variant of the ASTC format. RGBA data at 4.27 bits per pixel.
- ASTC6x6: The 6x6 pixels per block variant of the ASTC format. RGBA data at 3.56 bits per pixel.
- ASTC8x5: The 8x5 pixels per block variant of the ASTC format. RGBA data at 3.2 bits per pixel.
- ASTC8x6: The 8x6 pixels per block variant of the ASTC format. RGBA data at 2.67 bits per pixel.
- ASTC8x8: The 8x8 pixels per block variant of the ASTC format. RGBA data at 2 bits per pixel.
- ASTC10x5: The 10x5 pixels per block variant of the ASTC format. RGBA data at 2.56 bits per pixel.
- ASTC10x6: The 10x6 pixels per block variant of the ASTC format. RGBA data at 2.13 bits per pixel.
- ASTC10x8: The 10x8 pixels per block variant of the ASTC format. RGBA data at 1.6 bits per pixel.
- ASTC10x10: The 10x10 pixels per block variant of the ASTC format. RGBA data at 1.28 bits per pixel.
- ASTC12x10: The 12x10 pixels per block variant of the ASTC format. RGBA data at 1.07 bits per pixel.
- ASTC12x12: The 12x12 pixels per block variant of the ASTC format. RGBA data at 0.89 bits per pixel.

### ImageFormat
Encoded image formats.
- tga: Targa image format.
- png: PNG image format.
- jpg: JPG image format.
- bmp: BMP image format.

### PixelFormat
Pixel formats for Textures, ImageData, and CompressedImageData.
- unknown: Indicates unknown pixel format, used internally.
- normal: Alias for rgba8, or srgba8 if gamma-correct rendering is enabled.
- hdr: A format suitable for high dynamic range content - an alias for the rgba16f format, normally.
- r8: Single-channel (red component) format (8 bpp).
- rg8: Two channels (red and green components) with 8 bits per channel (16 bpp).
- rgba8: 8 bits per channel (32 bpp) RGBA. Color channel values range from 0-255 (0-1 in shaders).
- srgba8: gamma-correct version of rgba8.
- r16: Single-channel (red component) format (16 bpp).
- rg16: Two channels (red and green components) with 16 bits per channel (32 bpp).
- rgba16: 16 bits per channel (64 bpp) RGBA. Color channel values range from 0-65535 (0-1 in shaders).
- r16f: Floating point single-channel format (16 bpp). Color values can range from [-65504, +65504].
- rg16f: Floating point two-channel format with 16 bits per channel (32 bpp). Color values can range from [-65504, +65504].
- rgba16f: Floating point RGBA with 16 bits per channel (64 bpp). Color values can range from [-65504, +65504].
- r32f: Floating point single-channel format (32 bpp).
- rg32f: Floating point two-channel format with 32 bits per channel (64 bpp).
- rgba32f: Floating point RGBA with 32 bits per channel (128 bpp).
- la8: Same as rg8, but accessed as (L, L, L, A)
- rgba4: 4 bits per channel (16 bpp) RGBA.
- rgb5a1: RGB with 5 bits each, and a 1-bit alpha channel (16 bpp).
- rgb565: RGB with 5, 6, and 5 bits each, respectively (16 bpp). There is no alpha channel in this format.
- rgb10a2: RGB with 10 bits per channel, and a 2-bit alpha channel (32 bpp).
- rg11b10f: Floating point RGB with 11 bits in the red and green channels, and 10 bits in the blue channel (32 bpp). There is no alpha channel. Color values can range from [0, +65024].
- stencil8: No depth buffer and 8-bit stencil buffer.
- depth16: 16-bit depth buffer and no stencil buffer.
- depth24: 24-bit depth buffer and no stencil buffer.
- depth32f: 32-bit float depth buffer and no stencil buffer.
- depth24stencil8: 24-bit depth buffer and 8-bit stencil buffer.
- depth32fstencil8: 32-bit float depth buffer and 8-bit stencil buffer.
- DXT1: The DXT1 format. RGB data at 4 bits per pixel (compared to 32 bits for ImageData and regular Images.) Suitable for fully opaque images on desktop systems.
- DXT3: The DXT3 format. RGBA data at 8 bits per pixel. Smooth variations in opacity do not mix well with this format.
- DXT5: The DXT5 format. RGBA data at 8 bits per pixel. Recommended for images with varying opacity on desktop systems.
- BC4: The BC4 format (also known as 3Dc+ or ATI1.) Stores just the red channel, at 4 bits per pixel.
- BC4s: The signed variant of the BC4 format. Same as above but pixel values in the texture are in the range of 1 instead of 1 in shaders.
- BC5: The BC5 format (also known as 3Dc or ATI2.) Stores red and green channels at 8 bits per pixel.
- BC5s: The signed variant of the BC5 format.
- BC6h: The BC6H format. Stores half-precision floating-point RGB data in the range of 65504 at 8 bits per pixel. Suitable for HDR images on desktop systems.
- BC6hs: The signed variant of the BC6H format. Stores RGB data in the range of +65504.
- BC7: The BC7 format (also known as BPTC.) Stores RGB or RGBA data at 8 bits per pixel.
- ETC1: The ETC1 format. RGB data at 4 bits per pixel. Suitable for fully opaque images on older Android devices.
- ETC2rgb: The RGB variant of the ETC2 format. RGB data at 4 bits per pixel. Suitable for fully opaque images on newer mobile devices.
- ETC2rgba: The RGBA variant of the ETC2 format. RGBA data at 8 bits per pixel. Recommended for images with varying opacity on newer mobile devices.
- ETC2rgba1: The RGBA variant of the ETC2 format where pixels are either fully transparent or fully opaque. RGBA data at 4 bits per pixel.
- EACr: The single-channel variant of the EAC format. Stores just the red channel, at 4 bits per pixel.
- EACrs: The signed single-channel variant of the EAC format. Same as above but pixel values in the texture are in the range of 1 instead of 1 in shaders.
- EACrg: The two-channel variant of the EAC format. Stores red and green channels at 8 bits per pixel.
- EACrgs: The signed two-channel variant of the EAC format.
- PVR1rgb2: The 2 bit per pixel RGB variant of the PVRTC1 format. Stores RGB data at 2 bits per pixel. Textures compressed with PVRTC1 formats must be square and power-of-two sized.
- PVR1rgb4: The 4 bit per pixel RGB variant of the PVRTC1 format. Stores RGB data at 4 bits per pixel.
- PVR1rgba2: The 2 bit per pixel RGBA variant of the PVRTC1 format.
- PVR1rgba4: The 4 bit per pixel RGBA variant of the PVRTC1 format.
- ASTC4x4: The 4x4 pixels per block variant of the ASTC format. RGBA data at 8 bits per pixel.
- ASTC5x4: The 5x4 pixels per block variant of the ASTC format. RGBA data at 6.4 bits per pixel.
- ASTC5x5: The 5x5 pixels per block variant of the ASTC format. RGBA data at 5.12 bits per pixel.
- ASTC6x5: The 6x5 pixels per block variant of the ASTC format. RGBA data at 4.27 bits per pixel.
- ASTC6x6: The 6x6 pixels per block variant of the ASTC format. RGBA data at 3.56 bits per pixel.
- ASTC8x5: The 8x5 pixels per block variant of the ASTC format. RGBA data at 3.2 bits per pixel.
- ASTC8x6: The 8x6 pixels per block variant of the ASTC format. RGBA data at 2.67 bits per pixel.
- ASTC8x8: The 8x8 pixels per block variant of the ASTC format. RGBA data at 2 bits per pixel.
- ASTC10x5: The 10x5 pixels per block variant of the ASTC format. RGBA data at 2.56 bits per pixel.
- ASTC10x6: The 10x6 pixels per block variant of the ASTC format. RGBA data at 2.13 bits per pixel.
- ASTC10x8: The 10x8 pixels per block variant of the ASTC format. RGBA data at 1.6 bits per pixel.
- ASTC10x10: The 10x10 pixels per block variant of the ASTC format. RGBA data at 1.28 bits per pixel.
- ASTC12x10: The 12x10 pixels per block variant of the ASTC format. RGBA data at 1.07 bits per pixel.
- ASTC12x12: The 12x12 pixels per block variant of the ASTC format. RGBA data at 0.89 bits per pixel.

### love.image.isCompressed(filename) → compressed
Determines whether a file can be loaded as CompressedImageData.
- Variant 2: love.image.isCompressed(fileData) → compressed

### love.image.newCompressedData(filename) → compressedImageData
Create a new CompressedImageData object from a compressed image file. LÖVE supports several compressed texture formats, enumerated in the CompressedImageFormat page.
- Variant 2: love.image.newCompressedData(fileData) → compressedImageData

### love.image.newImageData(width, height) → imageData
Creates a new ImageData object.
- Variant 2: love.image.newImageData(width, height, format='rgba8', data) → imageData
- Variant 3: love.image.newImageData(width, height, data) → imageData
- Variant 4: love.image.newImageData(filename) → imageData
- Variant 5: love.image.newImageData(filedata) → imageData

### CompressedImageData < Data
Represents compressed image data designed to stay compressed in RAM.

CompressedImageData encompasses standard compressed texture formats such as  DXT1, DXT5, and BC5 / 3Dc.

You can't draw CompressedImageData directly to the screen. See Image for that.
Constructors: newCompressedData
- getDimensions() → width, height
  Gets the width and height of the CompressedImageData.
- getFormat() → format
  Gets the format of the CompressedImageData.
- getHeight() → height
  Gets the height of the CompressedImageData.
- getMipmapCount() → mipmaps
  Gets the number of mipmap levels in the CompressedImageData. The base mipmap level (original image) is included in the count.
- getWidth() → width
  Gets the width of the CompressedImageData.

### ImageData < Data
Raw (decoded) image data.

You can't draw ImageData directly to screen. See Image for that.
Constructors: newImageData
- encode(format, filename) → filedata
  Encodes the ImageData and optionally writes it to the save directory.
- getDimensions() → width, height
  Gets the width and height of the ImageData in pixels.
- getHeight() → height
  Gets the height of the ImageData in pixels.
- getPixel(x, y) → r, g, b, a
  Gets the color of a pixel at a specific position in the image.
  
  Valid x and y values start at 0 and go up to image width and height minus 1. Non-integer values are floored.
  
  In versions prior to 11.0, color component values were within the range of 0 to 255 instead of 0 to 1.
- getWidth() → width
  Gets the width of the ImageData in pixels.
- mapPixel(pixelFunction, x=0, y=0, width=ImageData:getWidth(), height=ImageData:getHeight())
  Transform an image by applying a function to every pixel.
  
  This function is a higher-order function. It takes another function as a parameter, and calls it once for each pixel in the ImageData.
  
  The passed function is called with six parameters for each pixel in turn. The parameters are numbers that represent the x and y coordinates of the pixel and its red, green, blue and alpha values. The function should return the new red, green, blue, and alpha values for that pixel.
  
  function pixelFunction(x, y, r, g, b, a)
  
      -- template for defining your own pixel mapping function
  
      -- perform computations giving the new values for r, g, b and a
  
      -- ...
  
      return r, g, b, a
  
  end
  
  In versions prior to 11.0, color component values were within the range of 0 to 255 instead of 0 to 1.
- paste(source, dx, dy, sx, sy, sw, sh)
  Paste into ImageData from another source ImageData.
- setPixel(x, y, r, g, b, a)
  Sets the color of a pixel at a specific position in the image.
  
  Valid x and y values start at 0 and go up to image width and height minus 1.
  
  In versions prior to 11.0, color component values were within the range of 0 to 255 instead of 0 to 1.
- getFormat() → format
  Gets the pixel format of the ImageData.

---
## love.joystick

Provides an interface to the user's joystick.

### GamepadAxis
Virtual gamepad axes.
- leftx: The x-axis of the left thumbstick.
- lefty: The y-axis of the left thumbstick.
- rightx: The x-axis of the right thumbstick.
- righty: The y-axis of the right thumbstick.
- triggerleft: Left analog trigger.
- triggerright: Right analog trigger.

### GamepadButton
Virtual gamepad buttons.
- a: Bottom face button (A).
- b: Right face button (B).
- x: Left face button (X).
- y: Top face button (Y).
- back: Back button.
- guide: Guide button.
- start: Start button.
- leftstick: Left stick click button.
- rightstick: Right stick click button.
- leftshoulder: Left bumper.
- rightshoulder: Right bumper.
- dpup: D-pad up.
- dpdown: D-pad down.
- dpleft: D-pad left.
- dpright: D-pad right.

### JoystickHat
Joystick hat positions.
- c: Centered
- d: Down
- l: Left
- ld: Left+Down
- lu: Left+Up
- r: Right
- rd: Right+Down
- ru: Right+Up
- u: Up

### JoystickInputType
Types of Joystick inputs.
- axis: Analog axis.
- button: Button.
- hat: 8-direction hat value.

### love.joystick.getGamepadMappingString(guid) → mappingstring
Gets the full gamepad mapping string of the Joysticks which have the given GUID, or nil if the GUID isn't recognized as a gamepad.

The mapping string contains binding information used to map the Joystick's buttons an axes to the standard gamepad layout, and can be used later with love.joystick.loadGamepadMappings.

### love.joystick.getJoystickCount() → joystickcount
Gets the number of connected joysticks.

### love.joystick.getJoysticks() → joysticks
Gets a list of connected Joysticks.

### love.joystick.loadGamepadMappings(filename)
Loads a gamepad mappings string or file created with love.joystick.saveGamepadMappings.

It also recognizes any SDL gamecontroller mapping string, such as those created with Steam's Big Picture controller configure interface, or this nice database. If a new mapping is loaded for an already known controller GUID, the later version will overwrite the one currently loaded.
- Variant 2: love.joystick.loadGamepadMappings(mappings)
  Loads a gamepad mappings string directly.

### love.joystick.saveGamepadMappings(filename) → mappings
Saves the virtual gamepad mappings of all recognized as gamepads and have either been recently used or their gamepad bindings have been modified.

The mappings are stored as a string for use with love.joystick.loadGamepadMappings.
- Variant 2: love.joystick.saveGamepadMappings() → mappings
  Returns the mappings string without writing to a file.

### love.joystick.setGamepadMapping(guid, button, inputtype, inputindex, hatdir) → success
Binds a virtual gamepad input to a button, axis or hat for all Joysticks of a certain type. For example, if this function is used with a GUID returned by a Dualshock 3 controller in OS X, the binding will affect Joystick:getGamepadAxis and Joystick:isGamepadDown for ''all'' Dualshock 3 controllers used with the game when run in OS X.

LÖVE includes built-in gamepad bindings for many common controllers. This function lets you change the bindings or add new ones for types of Joysticks which aren't recognized as gamepads by default.

The virtual gamepad buttons and axes are designed around the Xbox 360 controller layout.
- Variant 2: love.joystick.setGamepadMapping(guid, axis, inputtype, inputindex, hatdir) → success
  The physical locations for the bound gamepad axes and buttons should correspond as closely as possible to the layout of a standard Xbox 360 controller.

### Joystick < Object
Represents a physical joystick.
- getAxes() → axisDir1, axisDir2, axisDirN
  Gets the direction of each axis.
- getAxis(axis) → direction
  Gets the direction of an axis.
- getAxisCount() → axes
  Gets the number of axes on the joystick.
- getButtonCount() → buttons
  Gets the number of buttons on the joystick.
- getDeviceInfo() → vendorID, productID, productVersion
  Gets the USB vendor ID, product ID, and product version numbers of joystick which consistent across operating systems.
  
  Can be used to show different icons, etc. for different gamepads.
- getGUID() → guid
  Gets a stable GUID unique to the type of the physical joystick which does not change over time. For example, all Sony Dualshock 3 controllers in OS X have the same GUID. The value is platform-dependent.
- getGamepadAxis(axis) → direction
  Gets the direction of a virtual gamepad axis. If the Joystick isn't recognized as a gamepad or isn't connected, this function will always return 0.
- getGamepadMapping(axis) → inputtype, inputindex, hatdirection
  Gets the button, axis or hat that a virtual gamepad input is bound to.
- getGamepadMappingString() → mappingstring
  Gets the full gamepad mapping string of this Joystick, or nil if it's not recognized as a gamepad.
  
  The mapping string contains binding information used to map the Joystick's buttons an axes to the standard gamepad layout, and can be used later with love.joystick.loadGamepadMappings.
- getHat(hat) → direction
  Gets the direction of the Joystick's hat.
- getHatCount() → hats
  Gets the number of hats on the joystick.
- getID() → id, instanceid
  Gets the joystick's unique identifier. The identifier will remain the same for the life of the game, even when the Joystick is disconnected and reconnected, but it '''will''' change when the game is re-launched.
- getName() → name
  Gets the name of the joystick.
- getVibration() → left, right
  Gets the current vibration motor strengths on a Joystick with rumble support.
- isConnected() → connected
  Gets whether the Joystick is connected.
- isDown(buttonN) → anyDown
  Checks if a button on the Joystick is pressed.
  
  LÖVE 0.9.0 had a bug which required the button indices passed to Joystick:isDown to be 0-based instead of 1-based, for example button 1 would be 0 for this function. It was fixed in 0.9.1.
- isGamepad() → isgamepad
  Gets whether the Joystick is recognized as a gamepad. If this is the case, the Joystick's buttons and axes can be used in a standardized manner across different operating systems and joystick models via Joystick:getGamepadAxis, Joystick:isGamepadDown, love.gamepadpressed, and related functions.
  
  LÖVE automatically recognizes most popular controllers with a similar layout to the Xbox 360 controller as gamepads, but you can add more with love.joystick.setGamepadMapping.
- isGamepadDown(buttonN) → anyDown
  Checks if a virtual gamepad button on the Joystick is pressed. If the Joystick is not recognized as a Gamepad or isn't connected, then this function will always return false.
- isVibrationSupported() → supported
  Gets whether the Joystick supports vibration.
- setVibration(left, right) → success
  Sets the vibration motor speeds on a Joystick with rumble support. Most common gamepads have this functionality, although not all drivers give proper support. Use Joystick:isVibrationSupported to check.

---
## love.keyboard

Provides an interface to the user's keyboard.

### KeyConstant
All the keys you can press. Note that some keys may not be available on your keyboard or system.
- a: The A key
- b: The B key
- c: The C key
- d: The D key
- e: The E key
- f: The F key
- g: The G key
- h: The H key
- i: The I key
- j: The J key
- k: The K key
- l: The L key
- m: The M key
- n: The N key
- o: The O key
- p: The P key
- q: The Q key
- r: The R key
- s: The S key
- t: The T key
- u: The U key
- v: The V key
- w: The W key
- x: The X key
- y: The Y key
- z: The Z key
- 0: The zero key
- 1: The one key
- 2: The two key
- 3: The three key
- 4: The four key
- 5: The five key
- 6: The six key
- 7: The seven key
- 8: The eight key
- 9: The nine key
- space: Space key
- !: Exclamation mark key
- ": Double quote key
- #: Hash key
- $: Dollar key
- &: Ampersand key
- ': Single quote key
- (: Left parenthesis key
- ): Right parenthesis key
- *: Asterisk key
- +: Plus key
- ,: Comma key
- -: Hyphen-minus key
- .: Full stop key
- /: Slash key
- :: Colon key
- ;: Semicolon key
- <: Less-than key
- =: Equal key
- >: Greater-than key
- ?: Question mark key
- @: At sign key
- [: Left square bracket key
- \: Backslash key
- ]: Right square bracket key
- ^: Caret key
- _: Underscore key
- `: Grave accent key
- kp0: The numpad zero key
- kp1: The numpad one key
- kp2: The numpad two key
- kp3: The numpad three key
- kp4: The numpad four key
- kp5: The numpad five key
- kp6: The numpad six key
- kp7: The numpad seven key
- kp8: The numpad eight key
- kp9: The numpad nine key
- kp.: The numpad decimal point key
- kp/: The numpad division key
- kp*: The numpad multiplication key
- kp-: The numpad substraction key
- kp+: The numpad addition key
- kpenter: The numpad enter key
- kp=: The numpad equals key
- up: Up cursor key
- down: Down cursor key
- right: Right cursor key
- left: Left cursor key
- home: Home key
- end: End key
- pageup: Page up key
- pagedown: Page down key
- insert: Insert key
- backspace: Backspace key
- tab: Tab key
- clear: Clear key
- return: Return key
- delete: Delete key
- f1: The 1st function key
- f2: The 2nd function key
- f3: The 3rd function key
- f4: The 4th function key
- f5: The 5th function key
- f6: The 6th function key
- f7: The 7th function key
- f8: The 8th function key
- f9: The 9th function key
- f10: The 10th function key
- f11: The 11th function key
- f12: The 12th function key
- f13: The 13th function key
- f14: The 14th function key
- f15: The 15th function key
- numlock: Num-lock key
- capslock: Caps-lock key
- scrollock: Scroll-lock key
- rshift: Right shift key
- lshift: Left shift key
- rctrl: Right control key
- lctrl: Left control key
- ralt: Right alt key
- lalt: Left alt key
- rmeta: Right meta key
- lmeta: Left meta key
- lsuper: Left super key
- rsuper: Right super key
- mode: Mode key
- compose: Compose key
- pause: Pause key
- escape: Escape key
- help: Help key
- print: Print key
- sysreq: System request key
- break: Break key
- menu: Menu key
- power: Power key
- euro: Euro (&euro;) key
- undo: Undo key
- www: WWW key
- mail: Mail key
- calculator: Calculator key
- appsearch: Application search key
- apphome: Application home key
- appback: Application back key
- appforward: Application forward key
- apprefresh: Application refresh key
- appbookmarks: Application bookmarks key

### Scancode
Keyboard scancodes.

Scancodes are keyboard layout-independent, so the scancode "w" will be generated if the key in the same place as the "w" key on an American QWERTY keyboard is pressed, no matter what the key is labelled or what the user's operating system settings are.

Using scancodes, rather than keycodes, is useful because keyboards with layouts differing from the US/UK layout(s) might have keys that generate 'unknown' keycodes, but the scancodes will still be detected. This however would necessitate having a list for each keyboard layout one would choose to support.

One could use textinput or textedited instead, but those only give back the end result of keys used, i.e. you can't get modifiers on their own from it, only the final symbols that were generated.
- a: The 'A' key on an American layout.
- b: The 'B' key on an American layout.
- c: The 'C' key on an American layout.
- d: The 'D' key on an American layout.
- e: The 'E' key on an American layout.
- f: The 'F' key on an American layout.
- g: The 'G' key on an American layout.
- h: The 'H' key on an American layout.
- i: The 'I' key on an American layout.
- j: The 'J' key on an American layout.
- k: The 'K' key on an American layout.
- l: The 'L' key on an American layout.
- m: The 'M' key on an American layout.
- n: The 'N' key on an American layout.
- o: The 'O' key on an American layout.
- p: The 'P' key on an American layout.
- q: The 'Q' key on an American layout.
- r: The 'R' key on an American layout.
- s: The 'S' key on an American layout.
- t: The 'T' key on an American layout.
- u: The 'U' key on an American layout.
- v: The 'V' key on an American layout.
- w: The 'W' key on an American layout.
- x: The 'X' key on an American layout.
- y: The 'Y' key on an American layout.
- z: The 'Z' key on an American layout.
- 1: The '1' key on an American layout.
- 2: The '2' key on an American layout.
- 3: The '3' key on an American layout.
- 4: The '4' key on an American layout.
- 5: The '5' key on an American layout.
- 6: The '6' key on an American layout.
- 7: The '7' key on an American layout.
- 8: The '8' key on an American layout.
- 9: The '9' key on an American layout.
- 0: The '0' key on an American layout.
- return: The 'return' / 'enter' key on an American layout.
- escape: The 'escape' key on an American layout.
- backspace: The 'backspace' key on an American layout.
- tab: The 'tab' key on an American layout.
- space: The spacebar on an American layout.
- -: The minus key on an American layout.
- =: The equals key on an American layout.
- [: The left-bracket key on an American layout.
- ]: The right-bracket key on an American layout.
- \: The backslash key on an American layout.
- nonus#: The non-U.S. hash scancode.
- ;: The semicolon key on an American layout.
- ': The apostrophe key on an American layout.
- `: The back-tick / grave key on an American layout.
- ,: The comma key on an American layout.
- .: The period key on an American layout.
- /: The forward-slash key on an American layout.
- capslock: The capslock key on an American layout.
- f1: The F1 key on an American layout.
- f2: The F2 key on an American layout.
- f3: The F3 key on an American layout.
- f4: The F4 key on an American layout.
- f5: The F5 key on an American layout.
- f6: The F6 key on an American layout.
- f7: The F7 key on an American layout.
- f8: The F8 key on an American layout.
- f9: The F9 key on an American layout.
- f10: The F10 key on an American layout.
- f11: The F11 key on an American layout.
- f12: The F12 key on an American layout.
- f13: The F13 key on an American layout.
- f14: The F14 key on an American layout.
- f15: The F15 key on an American layout.
- f16: The F16 key on an American layout.
- f17: The F17 key on an American layout.
- f18: The F18 key on an American layout.
- f19: The F19 key on an American layout.
- f20: The F20 key on an American layout.
- f21: The F21 key on an American layout.
- f22: The F22 key on an American layout.
- f23: The F23 key on an American layout.
- f24: The F24 key on an American layout.
- lctrl: The left control key on an American layout.
- lshift: The left shift key on an American layout.
- lalt: The left alt / option key on an American layout.
- lgui: The left GUI (command / windows / super) key on an American layout.
- rctrl: The right control key on an American layout.
- rshift: The right shift key on an American layout.
- ralt: The right alt / option key on an American layout.
- rgui: The right GUI (command / windows / super) key on an American layout.
- printscreen: The printscreen key on an American layout.
- scrolllock: The scroll-lock key on an American layout.
- pause: The pause key on an American layout.
- insert: The insert key on an American layout.
- home: The home key on an American layout.
- numlock: The numlock / clear key on an American layout.
- pageup: The page-up key on an American layout.
- delete: The forward-delete key on an American layout.
- end: The end key on an American layout.
- pagedown: The page-down key on an American layout.
- right: The right-arrow key on an American layout.
- left: The left-arrow key on an American layout.
- down: The down-arrow key on an American layout.
- up: The up-arrow key on an American layout.
- nonusbackslash: The non-U.S. backslash scancode.
- application: The application key on an American layout. Windows contextual menu, compose key.
- execute: The 'execute' key on an American layout.
- help: The 'help' key on an American layout.
- menu: The 'menu' key on an American layout.
- select: The 'select' key on an American layout.
- stop: The 'stop' key on an American layout.
- again: The 'again' key on an American layout.
- undo: The 'undo' key on an American layout.
- cut: The 'cut' key on an American layout.
- copy: The 'copy' key on an American layout.
- paste: The 'paste' key on an American layout.
- find: The 'find' key on an American layout.
- kp/: The keypad forward-slash key on an American layout.
- kp*: The keypad '*' key on an American layout.
- kp-: The keypad minus key on an American layout.
- kp+: The keypad plus key on an American layout.
- kp=: The keypad equals key on an American layout.
- kpenter: The keypad enter key on an American layout.
- kp1: The keypad '1' key on an American layout.
- kp2: The keypad '2' key on an American layout.
- kp3: The keypad '3' key on an American layout.
- kp4: The keypad '4' key on an American layout.
- kp5: The keypad '5' key on an American layout.
- kp6: The keypad '6' key on an American layout.
- kp7: The keypad '7' key on an American layout.
- kp8: The keypad '8' key on an American layout.
- kp9: The keypad '9' key on an American layout.
- kp0: The keypad '0' key on an American layout.
- kp.: The keypad period key on an American layout.
- international1: The 1st international key on an American layout. Used on Asian keyboards.
- international2: The 2nd international key on an American layout.
- international3: The 3rd international  key on an American layout. Yen.
- international4: The 4th international key on an American layout.
- international5: The 5th international key on an American layout.
- international6: The 6th international key on an American layout.
- international7: The 7th international key on an American layout.
- international8: The 8th international key on an American layout.
- international9: The 9th international key on an American layout.
- lang1: Hangul/English toggle scancode.
- lang2: Hanja conversion scancode.
- lang3: Katakana scancode.
- lang4: Hiragana scancode.
- lang5: Zenkaku/Hankaku scancode.
- mute: The mute key on an American layout.
- volumeup: The volume up key on an American layout.
- volumedown: The volume down key on an American layout.
- audionext: The audio next track key on an American layout.
- audioprev: The audio previous track key on an American layout.
- audiostop: The audio stop key on an American layout.
- audioplay: The audio play key on an American layout.
- audiomute: The audio mute key on an American layout.
- mediaselect: The media select key on an American layout.
- www: The 'WWW' key on an American layout.
- mail: The Mail key on an American layout.
- calculator: The calculator key on an American layout.
- computer: The 'computer' key on an American layout.
- acsearch: The AC Search key on an American layout.
- achome: The AC Home key on an American layout.
- acback: The AC Back key on an American layout.
- acforward: The AC Forward key on an American layout.
- acstop: Th AC Stop key on an American layout.
- acrefresh: The AC Refresh key on an American layout.
- acbookmarks: The AC Bookmarks key on an American layout.
- power: The system power scancode.
- brightnessdown: The brightness-down scancode.
- brightnessup: The brightness-up scancode.
- displayswitch: The display switch scancode.
- kbdillumtoggle: The keyboard illumination toggle scancode.
- kbdillumdown: The keyboard illumination down scancode.
- kbdillumup: The keyboard illumination up scancode.
- eject: The eject scancode.
- sleep: The system sleep scancode.
- alterase: The alt-erase key on an American layout.
- sysreq: The sysreq key on an American layout.
- cancel: The 'cancel' key on an American layout.
- clear: The 'clear' key on an American layout.
- prior: The 'prior' key on an American layout.
- return2: The 'return2' key on an American layout.
- separator: The 'separator' key on an American layout.
- out: The 'out' key on an American layout.
- oper: The 'oper' key on an American layout.
- clearagain: The 'clearagain' key on an American layout.
- crsel: The 'crsel' key on an American layout.
- exsel: The 'exsel' key on an American layout.
- kp00: The keypad 00 key on an American layout.
- kp000: The keypad 000 key on an American layout.
- thsousandsseparator: The thousands-separator key on an American layout.
- decimalseparator: The decimal separator key on an American layout.
- currencyunit: The currency unit key on an American layout.
- currencysubunit: The currency sub-unit key on an American layout.
- app1: The 'app1' scancode.
- app2: The 'app2' scancode.
- unknown: An unknown key.

### love.keyboard.getKeyFromScancode(scancode) → key
Gets the key corresponding to the given hardware scancode.

Unlike key constants, Scancodes are keyboard layout-independent. For example the scancode 'w' will be generated if the key in the same place as the 'w' key on an American keyboard is pressed, no matter what the key is labelled or what the user's operating system settings are.

Scancodes are useful for creating default controls that have the same physical locations on on all systems.

### love.keyboard.getScancodeFromKey(key) → scancode
Gets the hardware scancode corresponding to the given key.

Unlike key constants, Scancodes are keyboard layout-independent. For example the scancode 'w' will be generated if the key in the same place as the 'w' key on an American keyboard is pressed, no matter what the key is labelled or what the user's operating system settings are.

Scancodes are useful for creating default controls that have the same physical locations on on all systems.

### love.keyboard.hasKeyRepeat() → enabled
Gets whether key repeat is enabled.

### love.keyboard.hasScreenKeyboard() → supported
Gets whether screen keyboard is supported.

### love.keyboard.hasTextInput() → enabled
Gets whether text input events are enabled.

### love.keyboard.isDown(key) → down
Checks whether a certain key is down. Not to be confused with love.keypressed or love.keyreleased.
- Variant 2: love.keyboard.isDown(key, ...) → anyDown
- Variant 3: love.keyboard.isDown(keys) → anyDown

### love.keyboard.isScancodeDown(scancode, ...) → down
Checks whether the specified Scancodes are pressed. Not to be confused with love.keypressed or love.keyreleased.

Unlike regular KeyConstants, Scancodes are keyboard layout-independent. The scancode 'w' is used if the key in the same place as the 'w' key on an American keyboard is pressed, no matter what the key is labelled or what the user's operating system settings are.

### love.keyboard.setKeyRepeat(enable)
Enables or disables key repeat for love.keypressed. It is disabled by default.

### love.keyboard.setTextInput(enable)
Enables or disables text input events. It is enabled by default on Windows, Mac, and Linux, and disabled by default on iOS and Android.

On touch devices, this shows the system's native on-screen keyboard when it's enabled.
- Variant 2: love.keyboard.setTextInput(enable, x, y, w, h)
  On iOS and Android this variant tells the OS that the specified rectangle is where text will show up in the game, which prevents the system on-screen keyboard from covering the text.

---
## love.math

Provides system-independent mathematical functions.

### MatrixLayout
The layout of matrix elements (row-major or column-major).
- row: The matrix is row-major:
- column: The matrix is column-major:

### love.math.colorFromBytes(rb, gb, bb, ab) → r, g, b, a
Converts a color from 0..255 to 0..1 range.

### love.math.colorToBytes(r, g, b, a) → rb, gb, bb, ab
Converts a color from 0..1 to 0..255 range.

### love.math.gammaToLinear(r, g, b) → lr, lg, lb
Converts a color from gamma-space (sRGB) to linear-space (RGB). This is useful when doing gamma-correct rendering and you need to do math in linear RGB in the few cases where LÖVE doesn't handle conversions automatically.

Read more about gamma-correct rendering here, here, and here.

In versions prior to 11.0, color component values were within the range of 0 to 255 instead of 0 to 1.
- Variant 2: love.math.gammaToLinear(color) → lr, lg, lb
- Variant 3: love.math.gammaToLinear(c) → lc

### love.math.getRandomSeed() → low, high
Gets the seed of the random number generator.

The seed is split into two numbers due to Lua's use of doubles for all number values - doubles can't accurately represent integer  values above 2^53, but the seed can be an integer value up to 2^64.

### love.math.getRandomState() → state
Gets the current state of the random number generator. This returns an opaque implementation-dependent string which is only useful for later use with love.math.setRandomState or RandomGenerator:setState.

This is different from love.math.getRandomSeed in that getRandomState gets the random number generator's current state, whereas getRandomSeed gets the previously set seed number.

### love.math.isConvex(vertices) → convex
Checks whether a polygon is convex.

PolygonShapes in love.physics, some forms of Meshes, and polygons drawn with love.graphics.polygon must be simple convex polygons.
- Variant 2: love.math.isConvex(x1, y1, x2, y2, ...) → convex

### love.math.linearToGamma(lr, lg, lb) → cr, cg, cb
Converts a color from linear-space (RGB) to gamma-space (sRGB). This is useful when storing linear RGB color values in an image, because the linear RGB color space has less precision than sRGB for dark colors, which can result in noticeable color banding when drawing.

In general, colors chosen based on what they look like on-screen are already in gamma-space and should not be double-converted. Colors calculated using math are often in the linear RGB space.

Read more about gamma-correct rendering here, here, and here.

In versions prior to 11.0, color component values were within the range of 0 to 255 instead of 0 to 1.
- Variant 2: love.math.linearToGamma(color) → cr, cg, cb
- Variant 3: love.math.linearToGamma(lc) → c

### love.math.newBezierCurve(vertices) → curve
Creates a new BezierCurve object.

The number of vertices in the control polygon determines the degree of the curve, e.g. three vertices define a quadratic (degree 2) Bézier curve, four vertices define a cubic (degree 3) Bézier curve, etc.
- Variant 2: love.math.newBezierCurve(x1, y1, x2, y2, ...) → curve

### love.math.newRandomGenerator() → rng
Creates a new RandomGenerator object which is completely independent of other RandomGenerator objects and random functions.
- Variant 2: love.math.newRandomGenerator(seed) → rng
  See RandomGenerator:setSeed.
- Variant 3: love.math.newRandomGenerator(low, high) → rng
  See RandomGenerator:setSeed.

### love.math.newTransform() → transform
Creates a new Transform object.
- Variant 2: love.math.newTransform(x, y, angle=0, sx=1, sy=sx, ox=0, oy=0, kx=0, ky=0) → transform
  Creates a Transform with the specified transformation applied on creation.

### love.math.noise(x) → value
Generates a Simplex or Perlin noise value in 1-4 dimensions. The return value will always be the same, given the same arguments.

Simplex noise is closely related to Perlin noise. It is widely used for procedural content generation.

There are many webpages which discuss Perlin and Simplex noise in detail.
- Variant 2: love.math.noise(x, y) → value
  Generates Simplex noise from 2 dimensions.
- Variant 3: love.math.noise(x, y, z) → value
  Generates Perlin noise (Simplex noise in version 0.9.2 and older) from 3 dimensions.
- Variant 4: love.math.noise(x, y, z, w) → value
  Generates Perlin noise (Simplex noise in version 0.9.2 and older) from 4 dimensions.

### love.math.random() → number
Generates a pseudo-random number in a platform independent manner. The default love.run seeds this function at startup, so you generally don't need to seed it yourself.
- Variant 2: love.math.random(max) → number
  Get a uniformly distributed pseudo-random integer within max.
- Variant 3: love.math.random(min, max) → number
  Get uniformly distributed pseudo-random integer within max.

### love.math.randomNormal(stddev=1, mean=0) → number
Get a normally distributed pseudo random number.

### love.math.setRandomSeed(seed)
Sets the seed of the random number generator using the specified integer number. This is called internally at startup, so you generally don't need to call it yourself.
- Variant 2: love.math.setRandomSeed(low, high)
  Combines two 32-bit integer numbers into a 64-bit integer value and sets the seed of the random number generator using the value.

### love.math.setRandomState(state)
Sets the current state of the random number generator. The value used as an argument for this function is an opaque implementation-dependent string and should only originate from a previous call to love.math.getRandomState.

This is different from love.math.setRandomSeed in that setRandomState directly sets the random number generator's current implementation-dependent state, whereas setRandomSeed gives it a new seed value.

### love.math.triangulate(polygon) → triangles
Decomposes a simple convex or concave polygon into triangles.
- Variant 2: love.math.triangulate(x1, y1, x2, y2, x3, y3) → triangles

### BezierCurve < Object
A Bézier curve object that can evaluate and render Bézier curves of arbitrary degree.

For more information on Bézier curves check this great article on Wikipedia.
Constructors: newBezierCurve
- evaluate(t) → x, y
  Evaluate Bézier curve at parameter t. The parameter must be between 0 and 1 (inclusive).
  
  This function can be used to move objects along paths or tween parameters. However it should not be used to render the curve, see BezierCurve:render for that purpose.
- getControlPoint(i) → x, y
  Get coordinates of the i-th control point. Indices start with 1.
- getControlPointCount() → count
  Get the number of control points in the Bézier curve.
- getDegree() → degree
  Get degree of the Bézier curve. The degree is equal to number-of-control-points - 1.
- getDerivative() → derivative
  Get the derivative of the Bézier curve.
  
  This function can be used to rotate sprites moving along a curve in the direction of the movement and compute the direction perpendicular to the curve at some parameter t.
- getSegment(startpoint, endpoint) → curve
  Gets a BezierCurve that corresponds to the specified segment of this BezierCurve.
- insertControlPoint(x, y, i=-1)
  Insert control point as the new i-th control point. Existing control points from i onwards are pushed back by 1. Indices start with 1. Negative indices wrap around: -1 is the last control point, -2 the one before the last, etc.
- removeControlPoint(index)
  Removes the specified control point.
- render(depth=5) → coordinates
  Get a list of coordinates to be used with love.graphics.line.
  
  This function samples the Bézier curve using recursive subdivision. You can control the recursion depth using the depth parameter.
  
  If you are just interested to know the position on the curve given a parameter, use BezierCurve:evaluate.
- renderSegment(startpoint, endpoint, depth=5) → coordinates
  Get a list of coordinates on a specific part of the curve, to be used with love.graphics.line.
  
  This function samples the Bézier curve using recursive subdivision. You can control the recursion depth using the depth parameter.
  
  If you are just need to know the position on the curve given a parameter, use BezierCurve:evaluate.
- rotate(angle, ox=0, oy=0)
  Rotate the Bézier curve by an angle.
- scale(s, ox=0, oy=0)
  Scale the Bézier curve by a factor.
- setControlPoint(i, x, y)
  Set coordinates of the i-th control point. Indices start with 1.
- translate(dx, dy)
  Move the Bézier curve by an offset.

### RandomGenerator < Object
A random number generation object which has its own random state.
Constructors: newRandomGenerator
- getSeed() → low, high
  Gets the seed of the random number generator object.
  
  The seed is split into two numbers due to Lua's use of doubles for all number values - doubles can't accurately represent integer  values above 2^53, but the seed value is an integer number in the range of 2^64 - 1.
- getState() → state
  Gets the current state of the random number generator. This returns an opaque string which is only useful for later use with RandomGenerator:setState in the same major version of LÖVE.
  
  This is different from RandomGenerator:getSeed in that getState gets the RandomGenerator's current state, whereas getSeed gets the previously set seed number.
- random() → number
  Generates a pseudo-random number in a platform independent manner.
- randomNormal(stddev=1, mean=0) → number
  Get a normally distributed pseudo random number.
- setSeed(seed)
  Sets the seed of the random number generator using the specified integer number.
- setState(state)
  Sets the current state of the random number generator. The value used as an argument for this function is an opaque string and should only originate from a previous call to RandomGenerator:getState in the same major version of LÖVE.
  
  This is different from RandomGenerator:setSeed in that setState directly sets the RandomGenerator's current implementation-dependent state, whereas setSeed gives it a new seed value.

### Transform < Object
Object containing a coordinate system transformation.

The love.graphics module has several functions and function variants which accept Transform objects.
Constructors: newTransform
- apply(other) → transform
  Applies the given other Transform object to this one.
  
  This effectively multiplies this Transform's internal transformation matrix with the other Transform's (i.e. self * other), and stores the result in this object.
- clone() → clone
  Creates a new copy of this Transform.
- getMatrix() → e1_1, e1_2, e1_3, e1_4, e2_1, e2_2, e2_3, e2_4, e3_1, e3_2, e3_3, e3_4, e4_1, e4_2, e4_3, e4_4
  Gets the internal 4x4 transformation matrix stored by this Transform. The matrix is returned in row-major order.
- inverse() → inverse
  Creates a new Transform containing the inverse of this Transform.
- inverseTransformPoint(localX, localY) → globalX, globalY
  Applies the reverse of the Transform object's transformation to the given 2D position.
  
  This effectively converts the given position from the local coordinate space of the Transform into global coordinates.
  
  One use of this method can be to convert a screen-space mouse position into global world coordinates, if the given Transform has transformations applied that are used for a camera system in-game.
- isAffine2DTransform() → affine
  Checks whether the Transform is an affine transformation.
- reset() → transform
  Resets the Transform to an identity state. All previously applied transformations are erased.
- rotate(angle) → transform
  Applies a rotation to the Transform's coordinate system. This method does not reset any previously applied transformations.
- scale(sx, sy=sx) → transform
  Scales the Transform's coordinate system. This method does not reset any previously applied transformations.
- setMatrix(e1_1, e1_2, e1_3, e1_4, e2_1, e2_2, e2_3, e2_4, e3_1, e3_2, e3_3, e3_4, e4_1, e4_2, e4_3, e4_4) → transform
  Directly sets the Transform's internal 4x4 transformation matrix.
- setTransformation(x, y, angle=0, sx=1, sy=sx, ox=0, oy=0, kx=0, ky=0) → transform
  Resets the Transform to the specified transformation parameters.
- shear(kx, ky) → transform
  Applies a shear factor (skew) to the Transform's coordinate system. This method does not reset any previously applied transformations.
- transformPoint(globalX, globalY) → localX, localY
  Applies the Transform object's transformation to the given 2D position.
  
  This effectively converts the given position from global coordinates into the local coordinate space of the Transform.
- translate(dx, dy) → transform
  Applies a translation to the Transform's coordinate system. This method does not reset any previously applied transformations.

---
## love.mouse

Provides an interface to the user's mouse.

### CursorType
Types of hardware cursors.
- image: The cursor is using a custom image.
- arrow: An arrow pointer.
- ibeam: An I-beam, normally used when mousing over editable or selectable text.
- wait: Wait graphic.
- waitarrow: Small wait cursor with an arrow pointer.
- crosshair: Crosshair symbol.
- sizenwse: Double arrow pointing to the top-left and bottom-right.
- sizenesw: Double arrow pointing to the top-right and bottom-left.
- sizewe: Double arrow pointing left and right.
- sizens: Double arrow pointing up and down.
- sizeall: Four-pointed arrow pointing up, down, left, and right.
- no: Slashed circle or crossbones.
- hand: Hand symbol.

### love.mouse.getCursor() → cursor
Gets the current Cursor.

### love.mouse.getPosition() → x, y
Returns the current position of the mouse.

### love.mouse.getRelativeMode() → enabled
Gets whether relative mode is enabled for the mouse.

If relative mode is enabled, the cursor is hidden and doesn't move when the mouse does, but relative mouse motion events are still generated via love.mousemoved. This lets the mouse move in any direction indefinitely without the cursor getting stuck at the edges of the screen.

The reported position of the mouse is not updated while relative mode is enabled, even when relative mouse motion events are generated.

### love.mouse.getSystemCursor(ctype) → cursor
Gets a Cursor object representing a system-native hardware cursor.

Hardware cursors are framerate-independent and work the same way as normal operating system cursors. Unlike drawing an image at the mouse's current coordinates, hardware cursors never have visible lag between when the mouse is moved and when the cursor position updates, even at low framerates.

### love.mouse.getX() → x
Returns the current x-position of the mouse.

### love.mouse.getY() → y
Returns the current y-position of the mouse.

### love.mouse.isCursorSupported() → supported
Gets whether cursor functionality is supported.

If it isn't supported, calling love.mouse.newCursor and love.mouse.getSystemCursor will cause an error. Mobile devices do not support cursors.

### love.mouse.isDown(button, ...) → down
Checks whether a certain mouse button is down.

This function does not detect mouse wheel scrolling; you must use the love.wheelmoved (or love.mousepressed in version 0.9.2 and older) callback for that.

### love.mouse.isGrabbed() → grabbed
Checks if the mouse is grabbed.

### love.mouse.isVisible() → visible
Checks if the cursor is visible.

### love.mouse.newCursor(imageData, hotx=0, hoty=0) → cursor
Creates a new hardware Cursor object from an image file or ImageData.

Hardware cursors are framerate-independent and work the same way as normal operating system cursors. Unlike drawing an image at the mouse's current coordinates, hardware cursors never have visible lag between when the mouse is moved and when the cursor position updates, even at low framerates.

The hot spot is the point the operating system uses to determine what was clicked and at what position the mouse cursor is. For example, the normal arrow pointer normally has its hot spot at the top left of the image, but a crosshair cursor might have it in the middle.
- Variant 2: love.mouse.newCursor(filename, hotx=0, hoty=0) → cursor
- Variant 3: love.mouse.newCursor(fileData, hotx=0, hoty=0) → cursor

### love.mouse.setCursor(cursor)
Sets the current mouse cursor.
- Variant 2: love.mouse.setCursor()
  Resets the current mouse cursor to the default.

### love.mouse.setGrabbed(grab)
Grabs the mouse and confines it to the window.

### love.mouse.setPosition(x, y)
Sets the current position of the mouse. Non-integer values are floored.

### love.mouse.setRelativeMode(enable)
Sets whether relative mode is enabled for the mouse.

When relative mode is enabled, the cursor is hidden and doesn't move when the mouse does, but relative mouse motion events are still generated via love.mousemoved. This lets the mouse move in any direction indefinitely without the cursor getting stuck at the edges of the screen.

The reported position of the mouse may not be updated while relative mode is enabled, even when relative mouse motion events are generated.

### love.mouse.setVisible(visible)
Sets the current visibility of the cursor.

### love.mouse.setX(x)
Sets the current X position of the mouse.

Non-integer values are floored.

### love.mouse.setY(y)
Sets the current Y position of the mouse.

Non-integer values are floored.

### Cursor < Object
Represents a hardware cursor.
Constructors: getCursor, newCursor, getSystemCursor
- getType() → ctype
  Gets the type of the Cursor.

---
## love.physics

Can simulate 2D rigid body physics in a realistic manner. This module is based on Box2D, and this API corresponds to the Box2D API as closely as possible.

### BodyType
The types of a Body.
- static: Static bodies do not move.
- dynamic: Dynamic bodies collide with all bodies.
- kinematic: Kinematic bodies only collide with dynamic bodies.

### JointType
Different types of joints.
- distance: A DistanceJoint.
- friction: A FrictionJoint.
- gear: A GearJoint.
- mouse: A MouseJoint.
- prismatic: A PrismaticJoint.
- pulley: A PulleyJoint.
- revolute: A RevoluteJoint.
- rope: A RopeJoint.
- weld: A WeldJoint.

### ShapeType
The different types of Shapes, as returned by Shape:getType.
- circle: The Shape is a CircleShape.
- polygon: The Shape is a PolygonShape.
- edge: The Shape is a EdgeShape.
- chain: The Shape is a ChainShape.

### love.physics.getDistance(fixture1, fixture2) → distance, x1, y1, x2, y2
Returns the two closest points between two fixtures and their distance.

### love.physics.getMeter() → scale
Returns the meter scale factor.

All coordinates in the physics module are divided by this number, creating a convenient way to draw the objects directly to the screen without the need for graphics transformations.

It is recommended to create shapes no larger than 10 times the scale. This is important because Box2D is tuned to work well with shape sizes from 0.1 to 10 meters.

### love.physics.newBody(world, x=0, y=0, type='static') → body
Creates a new body.

There are three types of bodies. 

* Static bodies do not move, have a infinite mass, and can be used for level boundaries. 

* Dynamic bodies are the main actors in the simulation, they collide with everything. 

* Kinematic bodies do not react to forces and only collide with dynamic bodies.

The mass of the body gets calculated when a Fixture is attached or removed, but can be changed at any time with Body:setMass or Body:resetMassData.

### love.physics.newChainShape(loop, x1, y1, x2, y2, ...) → shape
Creates a new ChainShape.
- Variant 2: love.physics.newChainShape(loop, points) → shape

### love.physics.newCircleShape(radius) → shape
Creates a new CircleShape.
- Variant 2: love.physics.newCircleShape(x, y, radius) → shape

### love.physics.newDistanceJoint(body1, body2, x1, y1, x2, y2, collideConnected=false) → joint
Creates a DistanceJoint between two bodies.

This joint constrains the distance between two points on two bodies to be constant. These two points are specified in world coordinates and the two bodies are assumed to be in place when this joint is created. The first anchor point is connected to the first body and the second to the second body, and the points define the length of the distance joint.

### love.physics.newEdgeShape(x1, y1, x2, y2) → shape
Creates a new EdgeShape.

### love.physics.newFixture(body, shape, density=1) → fixture
Creates and attaches a Fixture to a body.

Note that the Shape object is copied rather than kept as a reference when the Fixture is created. To get the Shape object that the Fixture owns, use Fixture:getShape.

### love.physics.newFrictionJoint(body1, body2, x, y, collideConnected=false) → joint
Create a friction joint between two bodies. A FrictionJoint applies friction to a body.
- Variant 2: love.physics.newFrictionJoint(body1, body2, x1, y1, x2, y2, collideConnected=false) → joint

### love.physics.newGearJoint(joint1, joint2, ratio=1, collideConnected=false) → joint
Create a GearJoint connecting two Joints.

The gear joint connects two joints that must be either  prismatic or  revolute joints. Using this joint requires that the joints it uses connect their respective bodies to the ground and have the ground as the first body. When destroying the bodies and joints you must make sure you destroy the gear joint before the other joints.

The gear joint has a ratio the determines how the angular or distance values of the connected joints relate to each other. The formula coordinate1 + ratio * coordinate2 always has a constant value that is set when the gear joint is created.

### love.physics.newMotorJoint(body1, body2, correctionFactor=0.3) → joint
Creates a joint between two bodies which controls the relative motion between them.

Position and rotation offsets can be specified once the MotorJoint has been created, as well as the maximum motor force and torque that will be be applied to reach the target offsets.
- Variant 2: love.physics.newMotorJoint(body1, body2, correctionFactor=0.3, collideConnected=false) → joint

### love.physics.newMouseJoint(body, x, y) → joint
Create a joint between a body and the mouse.

This joint actually connects the body to a fixed point in the world. To make it follow the mouse, the fixed point must be updated every timestep (example below).

The advantage of using a MouseJoint instead of just changing a body position directly is that collisions and reactions to other joints are handled by the physics engine.

### love.physics.newPolygonShape(x1, y1, x2, y2, x3, y3, ...) → shape
Creates a new PolygonShape.

This shape can have 8 vertices at most, and must form a convex shape.
- Variant 2: love.physics.newPolygonShape(vertices) → shape

### love.physics.newPrismaticJoint(body1, body2, x, y, ax, ay, collideConnected=false) → joint
Creates a PrismaticJoint between two bodies.

A prismatic joint constrains two bodies to move relatively to each other on a specified axis. It does not allow for relative rotation. Its definition and operation are similar to a  revolute joint, but with translation and force substituted for angle and torque.
- Variant 2: love.physics.newPrismaticJoint(body1, body2, x1, y1, x2, y2, ax, ay, collideConnected=false) → joint
- Variant 3: love.physics.newPrismaticJoint(body1, body2, x1, y1, x2, y2, ax, ay, collideConnected=false, referenceAngle=0) → joint

### love.physics.newPulleyJoint(body1, body2, gx1, gy1, gx2, gy2, x1, y1, x2, y2, ratio=1, collideConnected=true) → joint
Creates a PulleyJoint to join two bodies to each other and the ground.

The pulley joint simulates a pulley with an optional block and tackle. If the ratio parameter has a value different from one, then the simulated rope extends faster on one side than the other. In a pulley joint the total length of the simulated rope is the constant length1 + ratio * length2, which is set when the pulley joint is created.

Pulley joints can behave unpredictably if one side is fully extended. It is recommended that the method  setMaxLengths  be used to constrain the maximum lengths each side can attain.

### love.physics.newRectangleShape(width, height) → shape
Shorthand for creating rectangular PolygonShapes. 

By default, the local origin is located at the '''center''' of the rectangle as opposed to the top left for graphics.
- Variant 2: love.physics.newRectangleShape(x, y, width, height, angle=0) → shape

### love.physics.newRevoluteJoint(body1, body2, x, y, collideConnected=false) → joint
Creates a pivot joint between two bodies.

This joint connects two bodies to a point around which they can pivot.
- Variant 2: love.physics.newRevoluteJoint(body1, body2, x1, y1, x2, y2, collideConnected=false, referenceAngle=0) → joint

### love.physics.newRopeJoint(body1, body2, x1, y1, x2, y2, maxLength, collideConnected=false) → joint
Creates a joint between two bodies. Its only function is enforcing a max distance between these bodies.

### love.physics.newWeldJoint(body1, body2, x, y, collideConnected=false) → joint
Creates a constraint joint between two bodies. A WeldJoint essentially glues two bodies together. The constraint is a bit soft, however, due to Box2D's iterative solver.
- Variant 2: love.physics.newWeldJoint(body1, body2, x1, y1, x2, y2, collideConnected=false) → joint
- Variant 3: love.physics.newWeldJoint(body1, body2, x1, y1, x2, y2, collideConnected=false, referenceAngle=0) → joint

### love.physics.newWheelJoint(body1, body2, x, y, ax, ay, collideConnected=false) → joint
Creates a wheel joint.
- Variant 2: love.physics.newWheelJoint(body1, body2, x1, y1, x2, y2, ax, ay, collideConnected=false) → joint

### love.physics.newWorld(xg=0, yg=0, sleep=true) → world
Creates a new World.

### love.physics.setMeter(scale)
Sets the pixels to meter scale factor.

All coordinates in the physics module are divided by this number and converted to meters, and it creates a convenient way to draw the objects directly to the screen without the need for graphics transformations.

It is recommended to create shapes no larger than 10 times the scale. This is important because Box2D is tuned to work well with shape sizes from 0.1 to 10 meters. The default meter scale is 30.

### Body < Object
Bodies are objects with velocity and position.
Constructors: newBody
- applyAngularImpulse(impulse)
  Applies an angular impulse to a body. This makes a single, instantaneous addition to the body momentum.
  
  A body with with a larger mass will react less. The reaction does '''not''' depend on the timestep, and is equivalent to applying a force continuously for 1 second. Impulses are best used to give a single push to a body. For a continuous push to a body it is better to use Body:applyForce.
- applyForce(fx, fy)
  Apply force to a Body.
  
  A force pushes a body in a direction. A body with with a larger mass will react less. The reaction also depends on how long a force is applied: since the force acts continuously over the entire timestep, a short timestep will only push the body for a short time. Thus forces are best used for many timesteps to give a continuous push to a body (like gravity). For a single push that is independent of timestep, it is better to use Body:applyLinearImpulse.
  
  If the position to apply the force is not given, it will act on the center of mass of the body. The part of the force not directed towards the center of mass will cause the body to spin (and depends on the rotational inertia).
  
  Note that the force components and position must be given in world coordinates.
- applyLinearImpulse(ix, iy)
  Applies an impulse to a body.
  
  This makes a single, instantaneous addition to the body momentum.
  
  An impulse pushes a body in a direction. A body with with a larger mass will react less. The reaction does '''not''' depend on the timestep, and is equivalent to applying a force continuously for 1 second. Impulses are best used to give a single push to a body. For a continuous push to a body it is better to use Body:applyForce.
  
  If the position to apply the impulse is not given, it will act on the center of mass of the body. The part of the impulse not directed towards the center of mass will cause the body to spin (and depends on the rotational inertia). 
  
  Note that the impulse components and position must be given in world coordinates.
- applyTorque(torque)
  Apply torque to a body.
  
  Torque is like a force that will change the angular velocity (spin) of a body. The effect will depend on the rotational inertia a body has.
- destroy()
  Explicitly destroys the Body and all fixtures and joints attached to it.
  
  An error will occur if you attempt to use the object after calling this function. In 0.7.2, when you don't have time to wait for garbage collection, this function may be used to free the object immediately.
- getAngle() → angle
  Get the angle of the body.
  
  The angle is measured in radians. If you need to transform it to degrees, use math.deg.
  
  A value of 0 radians will mean 'looking to the right'. Although radians increase counter-clockwise, the y axis points down so it becomes ''clockwise'' from our point of view.
- getAngularDamping() → damping
  Gets the Angular damping of the Body
  
  The angular damping is the ''rate of decrease of the angular velocity over time'': A spinning body with no damping and no external forces will continue spinning indefinitely. A spinning body with damping will gradually stop spinning.
  
  Damping is not the same as friction - they can be modelled together. However, only damping is provided by Box2D (and LOVE).
  
  Damping parameters should be between 0 and infinity, with 0 meaning no damping, and infinity meaning full damping. Normally you will use a damping value between 0 and 0.1.
- getAngularVelocity() → w
  Get the angular velocity of the Body.
  
  The angular velocity is the ''rate of change of angle over time''.
  
  It is changed in World:update by applying torques, off centre forces/impulses, and angular damping. It can be set directly with Body:setAngularVelocity.
  
  If you need the ''rate of change of position over time'', use Body:getLinearVelocity.
- getContacts() → contacts
  Gets a list of all Contacts attached to the Body.
- getFixtures() → fixtures
  Returns a table with all fixtures.
- getGravityScale() → scale
  Returns the gravity scale factor.
- getInertia() → inertia
  Gets the rotational inertia of the body.
  
  The rotational inertia is how hard is it to make the body spin.
- getJoints() → joints
  Returns a table containing the Joints attached to this Body.
- getLinearDamping() → damping
  Gets the linear damping of the Body.
  
  The linear damping is the ''rate of decrease of the linear velocity over time''. A moving body with no damping and no external forces will continue moving indefinitely, as is the case in space. A moving body with damping will gradually stop moving.
  
  Damping is not the same as friction - they can be modelled together.
- getLinearVelocity() → x, y
  Gets the linear velocity of the Body from its center of mass.
  
  The linear velocity is the ''rate of change of position over time''.
  
  If you need the ''rate of change of angle over time'', use Body:getAngularVelocity.
  
  If you need to get the linear velocity of a point different from the center of mass:
  
  *  Body:getLinearVelocityFromLocalPoint allows you to specify the point in local coordinates.
  
  *  Body:getLinearVelocityFromWorldPoint allows you to specify the point in world coordinates.
  
  See page 136 of 'Essential Mathematics for Games and Interactive Applications' for definitions of local and world coordinates.
- getLinearVelocityFromLocalPoint(x, y) → vx, vy
  Get the linear velocity of a point on the body.
  
  The linear velocity for a point on the body is the velocity of the body center of mass plus the velocity at that point from the body spinning.
  
  The point on the body must given in local coordinates. Use Body:getLinearVelocityFromWorldPoint to specify this with world coordinates.
- getLinearVelocityFromWorldPoint(x, y) → vx, vy
  Get the linear velocity of a point on the body.
  
  The linear velocity for a point on the body is the velocity of the body center of mass plus the velocity at that point from the body spinning.
  
  The point on the body must given in world coordinates. Use Body:getLinearVelocityFromLocalPoint to specify this with local coordinates.
- getLocalCenter() → x, y
  Get the center of mass position in local coordinates.
  
  Use Body:getWorldCenter to get the center of mass in world coordinates.
- getLocalPoint(worldX, worldY) → localX, localY
  Transform a point from world coordinates to local coordinates.
- getLocalPoints(x1, y1, x2, y2, ...) → x1, y1, x2, y2, ...
  Transforms multiple points from world coordinates to local coordinates.
- getLocalVector(worldX, worldY) → localX, localY
  Transform a vector from world coordinates to local coordinates.
- getMass() → mass
  Get the mass of the body.
  
  Static bodies always have a mass of 0.
- getMassData() → x, y, mass, inertia
  Returns the mass, its center, and the rotational inertia.
- getPosition() → x, y
  Get the position of the body.
  
  Note that this may not be the center of mass of the body.
- getTransform() → x, y, angle
  Get the position and angle of the body.
  
  Note that the position may not be the center of mass of the body. An angle of 0 radians will mean 'looking to the right'. Although radians increase counter-clockwise, the y axis points down so it becomes clockwise from our point of view.
- getType() → type
  Returns the type of the body.
- getUserData() → value
  Returns the Lua value associated with this Body.
- getWorld() → world
  Gets the World the body lives in.
- getWorldCenter() → x, y
  Get the center of mass position in world coordinates.
  
  Use Body:getLocalCenter to get the center of mass in local coordinates.
- getWorldPoint(localX, localY) → worldX, worldY
  Transform a point from local coordinates to world coordinates.
- getWorldPoints(x1, y1, x2, y2) → x1, y1, x2, y2
  Transforms multiple points from local coordinates to world coordinates.
- getWorldVector(localX, localY) → worldX, worldY
  Transform a vector from local coordinates to world coordinates.
- getX() → x
  Get the x position of the body in world coordinates.
- getY() → y
  Get the y position of the body in world coordinates.
- isActive() → status
  Returns whether the body is actively used in the simulation.
- isAwake() → status
  Returns the sleep status of the body.
- isBullet() → status
  Get the bullet status of a body.
  
  There are two methods to check for body collisions:
  
  *  at their location when the world is updated (default)
  
  *  using continuous collision detection (CCD)
  
  The default method is efficient, but a body moving very quickly may sometimes jump over another body without producing a collision. A body that is set as a bullet will use CCD. This is less efficient, but is guaranteed not to jump when moving quickly.
  
  Note that static bodies (with zero mass) always use CCD, so your walls will not let a fast moving body pass through even if it is not a bullet.
- isDestroyed() → destroyed
  Gets whether the Body is destroyed. Destroyed bodies cannot be used.
- isFixedRotation() → fixed
  Returns whether the body rotation is locked.
- isSleepingAllowed() → allowed
  Returns the sleeping behaviour of the body.
- isTouching(otherbody) → touching
  Gets whether the Body is touching the given other Body.
- resetMassData()
  Resets the mass of the body by recalculating it from the mass properties of the fixtures.
- setActive(active)
  Sets whether the body is active in the world.
  
  An inactive body does not take part in the simulation. It will not move or cause any collisions.
- setAngle(angle)
  Set the angle of the body.
  
  The angle is measured in radians. If you need to transform it from degrees, use math.rad.
  
  A value of 0 radians will mean 'looking to the right'. Although radians increase counter-clockwise, the y axis points down so it becomes ''clockwise'' from our point of view.
  
  It is possible to cause a collision with another body by changing its angle.
- setAngularDamping(damping)
  Sets the angular damping of a Body
  
  See Body:getAngularDamping for a definition of angular damping.
  
  Angular damping can take any value from 0 to infinity. It is recommended to stay between 0 and 0.1, though. Other values will look unrealistic.
- setAngularVelocity(w)
  Sets the angular velocity of a Body.
  
  The angular velocity is the ''rate of change of angle over time''.
  
  This function will not accumulate anything; any impulses previously applied since the last call to World:update will be lost.
- setAwake(awake)
  Wakes the body up or puts it to sleep.
- setBullet(status)
  Set the bullet status of a body.
  
  There are two methods to check for body collisions:
  
  *  at their location when the world is updated (default)
  
  *  using continuous collision detection (CCD)
  
  The default method is efficient, but a body moving very quickly may sometimes jump over another body without producing a collision. A body that is set as a bullet will use CCD. This is less efficient, but is guaranteed not to jump when moving quickly.
  
  Note that static bodies (with zero mass) always use CCD, so your walls will not let a fast moving body pass through even if it is not a bullet.
- setFixedRotation(isFixed)
  Set whether a body has fixed rotation.
  
  Bodies with fixed rotation don't vary the speed at which they rotate. Calling this function causes the mass to be reset.
- setGravityScale(scale)
  Sets a new gravity scale factor for the body.
- setInertia(inertia)
  Set the inertia of a body.
- setLinearDamping(ld)
  Sets the linear damping of a Body
  
  See Body:getLinearDamping for a definition of linear damping.
  
  Linear damping can take any value from 0 to infinity. It is recommended to stay between 0 and 0.1, though. Other values will make the objects look 'floaty'(if gravity is enabled).
- setLinearVelocity(x, y)
  Sets a new linear velocity for the Body.
  
  This function will not accumulate anything; any impulses previously applied since the last call to World:update will be lost.
- setMass(mass)
  Sets a new body mass.
- setMassData(x, y, mass, inertia)
  Overrides the calculated mass data.
- setPosition(x, y)
  Set the position of the body.
  
  Note that this may not be the center of mass of the body.
  
  This function cannot wake up the body.
- setSleepingAllowed(allowed)
  Sets the sleeping behaviour of the body. Should sleeping be allowed, a body at rest will automatically sleep. A sleeping body is not simulated unless it collided with an awake body. Be wary that one can end up with a situation like a floating sleeping body if the floor was removed.
- setTransform(x, y, angle)
  Set the position and angle of the body.
  
  Note that the position may not be the center of mass of the body. An angle of 0 radians will mean 'looking to the right'. Although radians increase counter-clockwise, the y axis points down so it becomes clockwise from our point of view.
  
  This function cannot wake up the body.
- setType(type)
  Sets a new body type.
- setUserData(value)
  Associates a Lua value with the Body.
  
  To delete the reference, explicitly pass nil.
- setX(x)
  Set the x position of the body.
  
  This function cannot wake up the body.
- setY(y)
  Set the y position of the body.
  
  This function cannot wake up the body.

### ChainShape < Shape
A ChainShape consists of multiple line segments. It can be used to create the boundaries of your terrain. The shape does not have volume and can only collide with PolygonShape and CircleShape.

Unlike the PolygonShape, the ChainShape does not have a vertices limit or has to form a convex shape, but self intersections are not supported.
Constructors: newChainShape
- getChildEdge(index) → shape
  Returns a child of the shape as an EdgeShape.
- getNextVertex() → x, y
  Gets the vertex that establishes a connection to the next shape.
  
  Setting next and previous ChainShape vertices can help prevent unwanted collisions when a flat shape slides along the edge and moves over to the new shape.
- getPoint(index) → x, y
  Returns a point of the shape.
- getPoints() → x1, y1, x2, y2
  Returns all points of the shape.
- getPreviousVertex() → x, y
  Gets the vertex that establishes a connection to the previous shape.
  
  Setting next and previous ChainShape vertices can help prevent unwanted collisions when a flat shape slides along the edge and moves over to the new shape.
- getVertexCount() → count
  Returns the number of vertices the shape has.
- setNextVertex(x, y)
  Sets a vertex that establishes a connection to the next shape.
  
  This can help prevent unwanted collisions when a flat shape slides along the edge and moves over to the new shape.
- setPreviousVertex(x, y)
  Sets a vertex that establishes a connection to the previous shape.
  
  This can help prevent unwanted collisions when a flat shape slides along the edge and moves over to the new shape.

### CircleShape < Shape
Circle extends Shape and adds a radius and a local position.
Constructors: newCircleShape
- getPoint() → x, y
  Gets the center point of the circle shape.
- getRadius() → radius
  Gets the radius of the circle shape.
- setPoint(x, y)
  Sets the location of the center of the circle shape.
- setRadius(radius)
  Sets the radius of the circle.

### Contact < Object
Contacts are objects created to manage collisions in worlds.
- getChildren() → indexA, indexB
  Gets the child indices of the shapes of the two colliding fixtures. For ChainShapes, an index of 1 is the first edge in the chain.
  Used together with Fixture:rayCast or ChainShape:getChildEdge.
- getFixtures() → fixtureA, fixtureB
  Gets the two Fixtures that hold the shapes that are in contact.
- getFriction() → friction
  Get the friction between two shapes that are in contact.
- getNormal() → nx, ny
  Get the normal vector between two shapes that are in contact.
  
  This function returns the coordinates of a unit vector that points from the first shape to the second.
- getPositions() → x1, y1, x2, y2
  Returns the contact points of the two colliding fixtures. There can be one or two points.
- getRestitution() → restitution
  Get the restitution between two shapes that are in contact.
- isEnabled() → enabled
  Returns whether the contact is enabled. The collision will be ignored if a contact gets disabled in the preSolve callback.
- isTouching() → touching
  Returns whether the two colliding fixtures are touching each other.
- resetFriction()
  Resets the contact friction to the mixture value of both fixtures.
- resetRestitution()
  Resets the contact restitution to the mixture value of both fixtures.
- setEnabled(enabled)
  Enables or disables the contact.
- setFriction(friction)
  Sets the contact friction.
- setRestitution(restitution)
  Sets the contact restitution.

### DistanceJoint < Joint
Keeps two bodies at the same distance.
Constructors: newDistanceJoint
- getDampingRatio() → ratio
  Gets the damping ratio.
- getFrequency() → Hz
  Gets the response speed.
- getLength() → l
  Gets the equilibrium distance between the two Bodies.
- setDampingRatio(ratio)
  Sets the damping ratio.
- setFrequency(Hz)
  Sets the response speed.
- setLength(l)
  Sets the equilibrium distance between the two Bodies.

### EdgeShape < Shape
A EdgeShape is a line segment. They can be used to create the boundaries of your terrain. The shape does not have volume and can only collide with PolygonShape and CircleShape.
Constructors: newEdgeShape
- getNextVertex() → x, y
  Gets the vertex that establishes a connection to the next shape.
  
  Setting next and previous EdgeShape vertices can help prevent unwanted collisions when a flat shape slides along the edge and moves over to the new shape.
- getPoints() → x1, y1, x2, y2
  Returns the local coordinates of the edge points.
- getPreviousVertex() → x, y
  Gets the vertex that establishes a connection to the previous shape.
  
  Setting next and previous EdgeShape vertices can help prevent unwanted collisions when a flat shape slides along the edge and moves over to the new shape.
- setNextVertex(x, y)
  Sets a vertex that establishes a connection to the next shape.
  
  This can help prevent unwanted collisions when a flat shape slides along the edge and moves over to the new shape.
- setPreviousVertex(x, y)
  Sets a vertex that establishes a connection to the previous shape.
  
  This can help prevent unwanted collisions when a flat shape slides along the edge and moves over to the new shape.

### Fixture < Object
Fixtures attach shapes to bodies.
Constructors: newFixture
- destroy()
  Destroys the fixture.
- getBody() → body
  Returns the body to which the fixture is attached.
- getBoundingBox(index=1) → topLeftX, topLeftY, bottomRightX, bottomRightY
  Returns the points of the fixture bounding box. In case the fixture has multiple children a 1-based index can be specified. For example, a fixture will have multiple children with a chain shape.
- getCategory() → ...
  Returns the categories the fixture belongs to.
- getDensity() → density
  Returns the density of the fixture.
- getFilterData() → categories, mask, group
  Returns the filter data of the fixture.
  
  Categories and masks are encoded as the bits of a 16-bit integer.
- getFriction() → friction
  Returns the friction of the fixture.
- getGroupIndex() → group
  Returns the group the fixture belongs to. Fixtures with the same group will always collide if the group is positive or never collide if it's negative. The group zero means no group.
  
  The groups range from -32768 to 32767.
- getMask() → ...
  Returns which categories this fixture should '''NOT''' collide with.
- getMassData() → x, y, mass, inertia
  Returns the mass, its center and the rotational inertia.
- getRestitution() → restitution
  Returns the restitution of the fixture.
- getShape() → shape
  Returns the shape of the fixture. This shape is a reference to the actual data used in the simulation. It's possible to change its values between timesteps.
- getUserData() → value
  Returns the Lua value associated with this fixture.
- isDestroyed() → destroyed
  Gets whether the Fixture is destroyed. Destroyed fixtures cannot be used.
- isSensor() → sensor
  Returns whether the fixture is a sensor.
- rayCast(x1, y1, x2, y2, maxFraction, childIndex=1) → xn, yn, fraction
  Casts a ray against the shape of the fixture and returns the surface normal vector and the line position where the ray hit. If the ray missed the shape, nil will be returned.
  
  The ray starts on the first point of the input line and goes towards the second point of the line. The fifth argument is the maximum distance the ray is going to travel as a scale factor of the input line length.
  
  The childIndex parameter is used to specify which child of a parent shape, such as a ChainShape, will be ray casted. For ChainShapes, the index of 1 is the first edge on the chain. Ray casting a parent shape will only test the child specified so if you want to test every shape of the parent, you must loop through all of its children.
  
  The world position of the impact can be calculated by multiplying the line vector with the third return value and adding it to the line starting point.
  
  hitx, hity = x1 + (x2 - x1) * fraction, y1 + (y2 - y1) * fraction
- setCategory(...)
  Sets the categories the fixture belongs to. There can be up to 16 categories represented as a number from 1 to 16.
  
  All fixture's default category is 1.
- setDensity(density)
  Sets the density of the fixture. Call Body:resetMassData if this needs to take effect immediately.
- setFilterData(categories, mask, group)
  Sets the filter data of the fixture.
  
  Groups, categories, and mask can be used to define the collision behaviour of the fixture.
  
  If two fixtures are in the same group they either always collide if the group is positive, or never collide if it's negative. If the group is zero or they do not match, then the contact filter checks if the fixtures select a category of the other fixture with their masks. The fixtures do not collide if that's not the case. If they do have each other's categories selected, the return value of the custom contact filter will be used. They always collide if none was set.
  
  There can be up to 16 categories. Categories and masks are encoded as the bits of a 16-bit integer.
  
  When created, prior to calling this function, all fixtures have category set to 1, mask set to 65535 (all categories) and group set to 0.
  
  This function allows setting all filter data for a fixture at once. To set only the categories, the mask or the group, you can use Fixture:setCategory, Fixture:setMask or Fixture:setGroupIndex respectively.
- setFriction(friction)
  Sets the friction of the fixture.
  
  Friction determines how shapes react when they 'slide' along other shapes. Low friction indicates a slippery surface, like ice, while high friction indicates a rough surface, like concrete. Range: 0.0 - 1.0.
- setGroupIndex(group)
  Sets the group the fixture belongs to. Fixtures with the same group will always collide if the group is positive or never collide if it's negative. The group zero means no group.
  
  The groups range from -32768 to 32767.
- setMask(...)
  Sets the category mask of the fixture. There can be up to 16 categories represented as a number from 1 to 16.
  
  This fixture will '''NOT''' collide with the fixtures that are in the selected categories if the other fixture also has a category of this fixture selected.
- setRestitution(restitution)
  Sets the restitution of the fixture.
- setSensor(sensor)
  Sets whether the fixture should act as a sensor.
  
  Sensors do not cause collision responses, but the begin-contact and end-contact World callbacks will still be called for this fixture.
- setUserData(value)
  Associates a Lua value with the fixture.
  
  To delete the reference, explicitly pass nil.
- testPoint(x, y) → isInside
  Checks if a point is inside the shape of the fixture.

### FrictionJoint < Joint
A FrictionJoint applies friction to a body.
Constructors: newFrictionJoint
- getMaxForce() → force
  Gets the maximum friction force in Newtons.
- getMaxTorque() → torque
  Gets the maximum friction torque in Newton-meters.
- setMaxForce(maxForce)
  Sets the maximum friction force in Newtons.
- setMaxTorque(torque)
  Sets the maximum friction torque in Newton-meters.

### GearJoint < Joint
Keeps bodies together in such a way that they act like gears.
Constructors: newGearJoint
- getJoints() → joint1, joint2
  Get the Joints connected by this GearJoint.
- getRatio() → ratio
  Get the ratio of a gear joint.
- setRatio(ratio)
  Set the ratio of a gear joint.

### Joint < Object
Attach multiple bodies together to interact in unique ways.
- destroy()
  Explicitly destroys the Joint. An error will occur if you attempt to use the object after calling this function.
  
  In 0.7.2, when you don't have time to wait for garbage collection, this function 
  
  may be used to free the object immediately.
- getAnchors() → x1, y1, x2, y2
  Get the anchor points of the joint.
- getBodies() → bodyA, bodyB
  Gets the bodies that the Joint is attached to.
- getCollideConnected() → c
  Gets whether the connected Bodies collide.
- getReactionForce(x) → x, y
  Returns the reaction force in newtons on the second body
- getReactionTorque(invdt) → torque
  Returns the reaction torque on the second body.
- getType() → type
  Gets a string representing the type.
- getUserData() → value
  Returns the Lua value associated with this Joint.
- isDestroyed() → destroyed
  Gets whether the Joint is destroyed. Destroyed joints cannot be used.
- setUserData(value)
  Associates a Lua value with the Joint.
  
  To delete the reference, explicitly pass nil.

### MotorJoint < Joint
Controls the relative motion between two Bodies. Position and rotation offsets can be specified, as well as the maximum motor force and torque that will be applied to reach the target offsets.
Constructors: newMotorJoint
- getAngularOffset() → angleoffset
  Gets the target angular offset between the two Bodies the Joint is attached to.
- getLinearOffset() → x, y
  Gets the target linear offset between the two Bodies the Joint is attached to.
- setAngularOffset(angleoffset)
  Sets the target angluar offset between the two Bodies the Joint is attached to.
- setLinearOffset(x, y)
  Sets the target linear offset between the two Bodies the Joint is attached to.

### MouseJoint < Joint
For controlling objects with the mouse.
Constructors: newMouseJoint
- getDampingRatio() → ratio
  Returns the damping ratio.
- getFrequency() → freq
  Returns the frequency.
- getMaxForce() → f
  Gets the highest allowed force.
- getTarget() → x, y
  Gets the target point.
- setDampingRatio(ratio)
  Sets a new damping ratio.
- setFrequency(freq)
  Sets a new frequency.
- setMaxForce(f)
  Sets the highest allowed force.
- setTarget(x, y)
  Sets the target point.

### PolygonShape < Shape
A PolygonShape is a convex polygon with up to 8 vertices.
Constructors: newPolygonShape, newRectangleShape
- getPoints() → x1, y1, x2, y2
  Get the local coordinates of the polygon's vertices.
  
  This function has a variable number of return values. It can be used in a nested fashion with love.graphics.polygon.

### PrismaticJoint < Joint
Restricts relative motion between Bodies to one shared axis.
Constructors: newPrismaticJoint
- areLimitsEnabled() → enabled
  Checks whether the limits are enabled.
- getAxis() → x, y
  Gets the world-space axis vector of the Prismatic Joint.
- getJointSpeed() → s
  Get the current joint angle speed.
- getJointTranslation() → t
  Get the current joint translation.
- getLimits() → lower, upper
  Gets the joint limits.
- getLowerLimit() → lower
  Gets the lower limit.
- getMaxMotorForce() → f
  Gets the maximum motor force.
- getMotorForce(invdt) → force
  Returns the current motor force.
- getMotorSpeed() → s
  Gets the motor speed.
- getReferenceAngle() → angle
  Gets the reference angle.
- getUpperLimit() → upper
  Gets the upper limit.
- isMotorEnabled() → enabled
  Checks whether the motor is enabled.
- setLimits(lower, upper)
  Sets the limits.
- setLimitsEnabled() → enable
  Enables/disables the joint limit.
- setLowerLimit(lower)
  Sets the lower limit.
- setMaxMotorForce(f)
  Set the maximum motor force.
- setMotorEnabled(enable)
  Enables/disables the joint motor.
- setMotorSpeed(s)
  Sets the motor speed.
- setUpperLimit(upper)
  Sets the upper limit.

### PulleyJoint < Joint
Allows you to simulate bodies connected through pulleys.
Constructors: newPulleyJoint
- getConstant() → length
  Get the total length of the rope.
- getGroundAnchors() → a1x, a1y, a2x, a2y
  Get the ground anchor positions in world coordinates.
- getLengthA() → length
  Get the current length of the rope segment attached to the first body.
- getLengthB() → length
  Get the current length of the rope segment attached to the second body.
- getMaxLengths() → len1, len2
  Get the maximum lengths of the rope segments.
- getRatio() → ratio
  Get the pulley ratio.
- setConstant(length)
  Set the total length of the rope.
  
  Setting a new length for the rope updates the maximum length values of the joint.
- setMaxLengths(max1, max2)
  Set the maximum lengths of the rope segments.
  
  The physics module also imposes maximum values for the rope segments. If the parameters exceed these values, the maximum values are set instead of the requested values.
- setRatio(ratio)
  Set the pulley ratio.

### RevoluteJoint < Joint
Allow two Bodies to revolve around a shared point.
Constructors: newRevoluteJoint
- areLimitsEnabled() → enabled
  Checks whether limits are enabled.
- getJointAngle() → angle
  Get the current joint angle.
- getJointSpeed() → s
  Get the current joint angle speed.
- getLimits() → lower, upper
  Gets the joint limits.
- getLowerLimit() → lower
  Gets the lower limit.
- getMaxMotorTorque() → f
  Gets the maximum motor force.
- getMotorSpeed() → s
  Gets the motor speed.
- getMotorTorque() → f
  Get the current motor force.
- getReferenceAngle() → angle
  Gets the reference angle.
- getUpperLimit() → upper
  Gets the upper limit.
- hasLimitsEnabled() → enabled
  Checks whether limits are enabled.
- isMotorEnabled() → enabled
  Checks whether the motor is enabled.
- setLimits(lower, upper)
  Sets the limits.
- setLimitsEnabled(enable)
  Enables/disables the joint limit.
- setLowerLimit(lower)
  Sets the lower limit.
- setMaxMotorTorque(f)
  Set the maximum motor force.
- setMotorEnabled(enable)
  Enables/disables the joint motor.
- setMotorSpeed(s)
  Sets the motor speed.
- setUpperLimit(upper)
  Sets the upper limit.

### RopeJoint < Joint
The RopeJoint enforces a maximum distance between two points on two bodies. It has no other effect.
Constructors: newRopeJoint
- getMaxLength() → maxLength
  Gets the maximum length of a RopeJoint.
- setMaxLength(maxLength)
  Sets the maximum length of a RopeJoint.

### Shape < Object
Shapes are solid 2d geometrical objects which handle the mass and collision of a Body in love.physics.

Shapes are attached to a Body via a Fixture. The Shape object is copied when this happens. 

The Shape's position is relative to the position of the Body it has been attached to.
- computeAABB(tx, ty, tr, childIndex=1) → topLeftX, topLeftY, bottomRightX, bottomRightY
  Returns the points of the bounding box for the transformed shape.
- computeMass(density) → x, y, mass, inertia
  Computes the mass properties for the shape with the specified density.
- getChildCount() → count
  Returns the number of children the shape has.
- getRadius() → radius
  Gets the radius of the shape.
- getType() → type
  Gets a string representing the Shape.
  
  This function can be useful for conditional debug drawing.
- rayCast(x1, y1, x2, y2, maxFraction, tx, ty, tr, childIndex=1) → xn, yn, fraction
  Casts a ray against the shape and returns the surface normal vector and the line position where the ray hit. If the ray missed the shape, nil will be returned. The Shape can be transformed to get it into the desired position.
  
  The ray starts on the first point of the input line and goes towards the second point of the line. The fourth argument is the maximum distance the ray is going to travel as a scale factor of the input line length.
  
  The childIndex parameter is used to specify which child of a parent shape, such as a ChainShape, will be ray casted. For ChainShapes, the index of 1 is the first edge on the chain. Ray casting a parent shape will only test the child specified so if you want to test every shape of the parent, you must loop through all of its children.
  
  The world position of the impact can be calculated by multiplying the line vector with the third return value and adding it to the line starting point.
  
  hitx, hity = x1 + (x2 - x1) * fraction, y1 + (y2 - y1) * fraction
- testPoint(tx, ty, tr, x, y) → hit
  This is particularly useful for mouse interaction with the shapes. By looping through all shapes and testing the mouse position with this function, we can find which shapes the mouse touches.

### WeldJoint < Joint
A WeldJoint essentially glues two bodies together.
Constructors: newWeldJoint
- getDampingRatio() → ratio
  Returns the damping ratio of the joint.
- getFrequency() → freq
  Returns the frequency.
- getReferenceAngle() → angle
  Gets the reference angle.
- setDampingRatio(ratio)
  Sets a new damping ratio.
- setFrequency(freq)
  Sets a new frequency.

### WheelJoint < Joint
Restricts a point on the second body to a line on the first body.
Constructors: newWheelJoint
- getAxis() → x, y
  Gets the world-space axis vector of the Wheel Joint.
- getJointSpeed() → speed
  Returns the current joint translation speed.
- getJointTranslation() → position
  Returns the current joint translation.
- getMaxMotorTorque() → maxTorque
  Returns the maximum motor torque.
- getMotorSpeed() → speed
  Returns the speed of the motor.
- getMotorTorque(invdt) → torque
  Returns the current torque on the motor.
- getSpringDampingRatio() → ratio
  Returns the damping ratio.
- getSpringFrequency() → freq
  Returns the spring frequency.
- isMotorEnabled() → on
  Checks if the joint motor is running.
- setMaxMotorTorque(maxTorque)
  Sets a new maximum motor torque.
- setMotorEnabled(enable)
  Starts and stops the joint motor.
- setMotorSpeed(speed)
  Sets a new speed for the motor.
- setSpringDampingRatio(ratio)
  Sets a new damping ratio.
- setSpringFrequency(freq)
  Sets a new spring frequency.

### World < Object
A world is an object that contains all bodies and joints.
Constructors: newWorld
- destroy()
  Destroys the world, taking all bodies, joints, fixtures and their shapes with it. 
  
  An error will occur if you attempt to use any of the destroyed objects after calling this function.
- getBodies() → bodies
  Returns a table with all bodies.
- getBodyCount() → n
  Returns the number of bodies in the world.
- getCallbacks() → beginContact, endContact, preSolve, postSolve
  Returns functions for the callbacks during the world update.
- getContactCount() → n
  Returns the number of contacts in the world.
- getContactFilter() → contactFilter
  Returns the function for collision filtering.
- getContacts() → contacts
  Returns a table with all Contacts.
- getGravity() → x, y
  Get the gravity of the world.
- getJointCount() → n
  Returns the number of joints in the world.
- getJoints() → joints
  Returns a table with all joints.
- isDestroyed() → destroyed
  Gets whether the World is destroyed. Destroyed worlds cannot be used.
- isLocked() → locked
  Returns if the world is updating its state.
  
  This will return true inside the callbacks from World:setCallbacks.
- isSleepingAllowed() → allow
  Gets the sleep behaviour of the world.
- queryBoundingBox(topLeftX, topLeftY, bottomRightX, bottomRightY, callback)
  Calls a function for each fixture inside the specified area by searching for any overlapping bounding box (Fixture:getBoundingBox).
- rayCast(x1, y1, x2, y2, callback)
  Casts a ray and calls a function for each fixtures it intersects.
- setCallbacks(beginContact, endContact, preSolve, postSolve)
  Sets functions for the collision callbacks during the world update.
  
  Four Lua functions can be given as arguments. The value nil removes a function.
  
  When called, each function will be passed three arguments. The first two arguments are the colliding fixtures and the third argument is the Contact between them. The postSolve callback additionally gets the normal and tangent impulse for each contact point. See notes.
  
  If you are interested to know when exactly each callback is called, consult a Box2d manual
- setContactFilter(filter)
  Sets a function for collision filtering.
  
  If the group and category filtering doesn't generate a collision decision, this function gets called with the two fixtures as arguments. The function should return a boolean value where true means the fixtures will collide and false means they will pass through each other.
- setGravity(x, y)
  Set the gravity of the world.
- setSleepingAllowed(allow)
  Sets the sleep behaviour of the world.
- translateOrigin(x, y)
  Translates the World's origin. Useful in large worlds where floating point precision issues become noticeable at far distances from the origin.
- update(dt, velocityiterations=8, positioniterations=3)
  Update the state of the world.

---
## love.sound

This module is responsible for decoding sound files. It can't play the sounds, see love.audio for that.

### love.sound.newDecoder(file, buffer=2048) → decoder
Attempts to find a decoder for the encoded sound data in the specified file.
- Variant 2: love.sound.newDecoder(filename, buffer=2048) → decoder

### love.sound.newSoundData(filename) → soundData
Creates new SoundData from a filepath, File, or Decoder. It's also possible to create SoundData with a custom sample rate, channel and bit depth.

The sound data will be decoded to the memory in a raw format. It is recommended to create only short sounds like effects, as a 3 minute song uses 30 MB of memory this way.
- Variant 2: love.sound.newSoundData(file) → soundData
- Variant 3: love.sound.newSoundData(decoder) → soundData
- Variant 4: love.sound.newSoundData(samples, rate=44100, bits=16, channels=2) → soundData

### Decoder < Object
An object which can gradually decode a sound file.
Constructors: newDecoder
- clone() → decoder
  Creates a new copy of current decoder.
  
  The new decoder will start decoding from the beginning of the audio stream.
- decode() → soundData
  Decodes the audio and returns a SoundData object containing the decoded audio data.
- getBitDepth() → bitDepth
  Returns the number of bits per sample.
- getChannelCount() → channels
  Returns the number of channels in the stream.
- getDuration() → duration
  Gets the duration of the sound file. It may not always be sample-accurate, and it may return -1 if the duration cannot be determined at all.
- getSampleRate() → rate
  Returns the sample rate of the Decoder.
- seek(offset)
  Sets the currently playing position of the Decoder.

### SoundData < Data
Contains raw audio samples.

You can not play SoundData back directly. You must wrap a Source object around it.
Constructors: newSoundData
- getBitDepth() → bitdepth
  Returns the number of bits per sample.
- getChannelCount() → channels
  Returns the number of channels in the SoundData.
- getDuration() → duration
  Gets the duration of the sound data.
- getSample(i) → sample
  Gets the value of the sample-point at the specified position. For stereo SoundData objects, the data from the left and right channels are interleaved in that order.
- getSampleCount() → count
  Returns the number of samples per channel of the SoundData.
- getSampleRate() → rate
  Returns the sample rate of the SoundData.
- setSample(i, sample)
  Sets the value of the sample-point at the specified position. For stereo SoundData objects, the data from the left and right channels are interleaved in that order.

---
## love.system

Provides access to information about the user's system.

### PowerState
The basic state of the system's power supply.
- unknown: Cannot determine power status.
- battery: Not plugged in, running on a battery.
- nobattery: Plugged in, no battery available.
- charging: Plugged in, charging battery.
- charged: Plugged in, battery is fully charged.

### love.system.getClipboardText() → text
Gets text from the clipboard.

### love.system.getOS() → osString
Gets the current operating system. In general, LÖVE abstracts away the need to know the current operating system, but there are a few cases where it can be useful (especially in combination with os.execute.)

### love.system.getPowerInfo() → state, percent, seconds
Gets information about the system's power supply.

### love.system.getProcessorCount() → processorCount
Gets the amount of logical processor in the system.

### love.system.hasBackgroundMusic() → backgroundmusic
Gets whether another application on the system is playing music in the background.

Currently this is implemented on iOS and Android, and will always return false on other operating systems. The t.audio.mixwithsystem flag in love.conf can be used to configure whether background audio / music from other apps should play while LÖVE is open.

### love.system.openURL(url) → success
Opens a URL with the user's web or file browser.

### love.system.setClipboardText(text)
Puts text in the clipboard.

### love.system.vibrate(seconds=0.5)
Causes the device to vibrate, if possible. Currently this will only work on Android and iOS devices that have a built-in vibration motor.

---
## love.thread

Allows you to work with threads.

Threads are separate Lua environments, running in parallel to the main code. As their code runs separately, they can be used to compute complex operations without adversely affecting the frame rate of the main thread. However, as they are separate environments, they cannot access the variables and functions of the main thread, and communication between threads is limited.

All LOVE objects (userdata) are shared among threads so you'll only have to send their references across threads. You may run into concurrency issues if you manipulate an object on multiple threads at the same time.

When a Thread is started, it only loads the love.thread module. Every other module has to be loaded with require.

### love.thread.getChannel(name) → channel
Creates or retrieves a named thread channel.

### love.thread.newChannel() → channel
Create a new unnamed thread channel.

One use for them is to pass new unnamed channels to other threads via Channel:push on a named channel.

### love.thread.newThread(filename) → thread
Creates a new Thread from a filename, string or FileData object containing Lua code.
- Variant 2: love.thread.newThread(fileData) → thread
- Variant 3: love.thread.newThread(codestring) → thread

### Channel < Object
An object which can be used to send and receive data between different threads.
Constructors: newChannel, getChannel
- clear()
  Clears all the messages in the Channel queue.
- demand() → value
  Retrieves the value of a Channel message and removes it from the message queue.
  
  It waits until a message is in the queue then returns the message value.
- getCount() → count
  Retrieves the number of messages in the thread Channel queue.
- hasRead(id) → hasread
  Gets whether a pushed value has been popped or otherwise removed from the Channel.
- peek() → value
  Retrieves the value of a Channel message, but leaves it in the queue.
  
  It returns nil if there's no message in the queue.
- performAtomic(func, ...) → ret1, ...
  Executes the specified function atomically with respect to this Channel.
  
  Calling multiple methods in a row on the same Channel is often useful. However if multiple Threads are calling this Channel's methods at the same time, the different calls on each Thread might end up interleaved (e.g. one or more of the second thread's calls may happen in between the first thread's calls.)
  
  This method avoids that issue by making sure the Thread calling the method has exclusive access to the Channel until the specified function has returned.
- pop() → value
  Retrieves the value of a Channel message and removes it from the message queue.
  
  It returns nil if there are no messages in the queue.
- push(value) → id
  Send a message to the thread Channel.
  
  See Variant for the list of supported types.
- supply(value) → success
  Send a message to the thread Channel and wait for a thread to accept it.
  
  See Variant for the list of supported types.

### Thread < Object
A Thread is a chunk of code that can run in parallel with other threads. Data can be sent between different threads with Channel objects.
Constructors: newThread
- getError() → err
  Retrieves the error string from the thread if it produced an error.
- isRunning() → value
  Returns whether the thread is currently running.
  
  Threads which are not running can be (re)started with Thread:start.
- start()
  Starts the thread.
  
  Beginning with version 0.9.0, threads can be restarted after they have completed their execution.
- wait()
  Wait for a thread to finish.
  
  This call will block until the thread finishes.

---
## love.timer

Provides an interface to the user's clock.

### love.timer.getAverageDelta() → delta
Returns the average delta time (seconds per frame) over the last second.

### love.timer.getDelta() → dt
Returns the time between the last two frames.

### love.timer.getFPS() → fps
Returns the current frames per second.

### love.timer.getTime() → time
Returns the value of a timer with an unspecified starting time.

This function should only be used to calculate differences between points in time, as the starting time of the timer is unknown.

### love.timer.sleep(s)
Pauses the current thread for the specified amount of time.

### love.timer.step() → dt
Measures the time between two frames.

Calling this changes the return value of love.timer.getDelta.

---
## love.touch

Provides an interface to touch-screen presses.

### love.touch.getPosition(id) → x, y
Gets the current position of the specified touch-press, in pixels.

### love.touch.getPressure(id) → pressure
Gets the current pressure of the specified touch-press.

### love.touch.getTouches() → touches
Gets a list of all active touch-presses.

---
## love.video

This module is responsible for decoding, controlling, and streaming video files.

It can't draw the videos, see love.graphics.newVideo and Video objects for that.

### love.video.newVideoStream(filename) → videostream
Creates a new VideoStream. Currently only Ogg Theora video files are supported. VideoStreams can't draw videos, see love.graphics.newVideo for that.
- Variant 2: love.video.newVideoStream(file) → videostream

### VideoStream < Object
An object which decodes, streams, and controls Videos.
Constructors: newVideoStream
- getFilename() → filename
  Gets the filename of the VideoStream.
- isPlaying() → playing
  Gets whether the VideoStream is playing.
- pause()
  Pauses the VideoStream.
- play()
  Plays the VideoStream.
- rewind()
  Rewinds the VideoStream. Synonym to VideoStream:seek(0).
- seek(offset)
  Sets the current playback position of the VideoStream.
- tell() → seconds
  Gets the current playback position of the VideoStream.

---
## love.window

Provides an interface for modifying and retrieving information about the program's window.

### DisplayOrientation
Types of device display orientation.
- unknown: Orientation cannot be determined.
- landscape: Landscape orientation.
- landscapeflipped: Landscape orientation (flipped).
- portrait: Portrait orientation.
- portraitflipped: Portrait orientation (flipped).

### FullscreenType
Types of fullscreen modes.
- desktop: Sometimes known as borderless fullscreen windowed mode. A borderless screen-sized window is created which sits on top of all desktop UI elements. The window is automatically resized to match the dimensions of the desktop, and its size cannot be changed.
- exclusive: Standard exclusive-fullscreen mode. Changes the display mode (actual resolution) of the monitor.
- normal: Standard exclusive-fullscreen mode. Changes the display mode (actual resolution) of the monitor.

### MessageBoxType
Types of message box dialogs. Different types may have slightly different looks.
- info: Informational dialog.
- warning: Warning dialog.
- error: Error dialog.

### love.window.close()
Closes the window. It can be reopened with love.window.setMode.

### love.window.fromPixels(pixelvalue) → value
Converts a number from pixels to density-independent units.

The pixel density inside the window might be greater (or smaller) than the 'size' of the window. For example on a retina screen in Mac OS X with the highdpi window flag enabled, the window may take up the same physical size as an 800x600 window, but the area inside the window uses 1600x1200 pixels. love.window.fromPixels(1600) would return 800 in that case.

This function converts coordinates from pixels to the size users are expecting them to display at onscreen. love.window.toPixels does the opposite. The highdpi window flag must be enabled to use the full pixel density of a Retina screen on Mac OS X and iOS. The flag currently does nothing on Windows and Linux, and on Android it is effectively always enabled.

Most LÖVE functions return values and expect arguments in terms of pixels rather than density-independent units.
- Variant 2: love.window.fromPixels(px, py) → x, y
  The units of love.graphics.getWidth, love.graphics.getHeight, love.mouse.getPosition, mouse events, love.touch.getPosition, and touch events are always in terms of pixels.

### love.window.getDPIScale() → scale
Gets the DPI scale factor associated with the window.

The pixel density inside the window might be greater (or smaller) than the 'size' of the window. For example on a retina screen in Mac OS X with the highdpi window flag enabled, the window may take up the same physical size as an 800x600 window, but the area inside the window uses 1600x1200 pixels. love.window.getDPIScale() would return 2.0 in that case.

The love.window.fromPixels and love.window.toPixels functions can also be used to convert between units.

The highdpi window flag must be enabled to use the full pixel density of a Retina screen on Mac OS X and iOS. The flag currently does nothing on Windows and Linux, and on Android it is effectively always enabled.

### love.window.getDesktopDimensions(displayindex=1) → width, height
Gets the width and height of the desktop.

### love.window.getDisplayCount() → count
Gets the number of connected monitors.

### love.window.getDisplayName(displayindex=1) → name
Gets the name of a display.

### love.window.getDisplayOrientation(displayindex) → orientation
Gets current device display orientation.

### love.window.getFullscreen() → fullscreen, fstype
Gets whether the window is fullscreen.

### love.window.getFullscreenModes(displayindex=1) → modes
Gets a list of supported fullscreen modes.

### love.window.getIcon() → imagedata
Gets the window icon.

### love.window.getMode() → width, height, flags
Gets the display mode and properties of the window.

### love.window.getPosition() → x, y, displayindex
Gets the position of the window on the screen.

The window position is in the coordinate space of the display it is currently in.

### love.window.getSafeArea() → x, y, w, h
Gets area inside the window which is known to be unobstructed by a system title bar, the iPhone X notch, etc. Useful for making sure UI elements can be seen by the user.

### love.window.getTitle() → title
Gets the window title.

### love.window.getVSync() → vsync
Gets current vertical synchronization (vsync).

### love.window.hasFocus() → focus
Checks if the game window has keyboard focus.

### love.window.hasMouseFocus() → focus
Checks if the game window has mouse focus.

### love.window.isDisplaySleepEnabled() → enabled
Gets whether the display is allowed to sleep while the program is running.

Display sleep is disabled by default. Some types of input (e.g. joystick button presses) might not prevent the display from sleeping, if display sleep is allowed.

### love.window.isMaximized() → maximized
Gets whether the Window is currently maximized.

The window can be maximized if it is not fullscreen and is resizable, and either the user has pressed the window's Maximize button or love.window.maximize has been called.

### love.window.isMinimized() → minimized
Gets whether the Window is currently minimized.

### love.window.isOpen() → open
Checks if the window is open.

### love.window.isVisible() → visible
Checks if the game window is visible.

The window is considered visible if it's not minimized and the program isn't hidden.

### love.window.maximize()
Makes the window as large as possible.

This function has no effect if the window isn't resizable, since it essentially programmatically presses the window's 'maximize' button.

### love.window.minimize()
Minimizes the window to the system's task bar / dock.

### love.window.requestAttention(continuous=false)
Causes the window to request the attention of the user if it is not in the foreground.

In Windows the taskbar icon will flash, and in OS X the dock icon will bounce.

### love.window.restore()
Restores the size and position of the window if it was minimized or maximized.

### love.window.setDisplaySleepEnabled(enable)
Sets whether the display is allowed to sleep while the program is running.

Display sleep is disabled by default. Some types of input (e.g. joystick button presses) might not prevent the display from sleeping, if display sleep is allowed.

### love.window.setFullscreen(fullscreen) → success
Enters or exits fullscreen. The display to use when entering fullscreen is chosen based on which display the window is currently in, if multiple monitors are connected.
- Variant 2: love.window.setFullscreen(fullscreen, fstype) → success
  If fullscreen mode is entered and the window size doesn't match one of the monitor's display modes (in normal fullscreen mode) or the window size doesn't match the desktop size (in 'desktop' fullscreen mode), the window will be resized appropriately. The window will revert back to its original size again when fullscreen mode is exited using this function.

### love.window.setIcon(imagedata) → success
Sets the window icon until the game is quit. Not all operating systems support very large icon images.

### love.window.setMode(width, height, flags) → success
Sets the display mode and properties of the window.

If width or height is 0, setMode will use the width and height of the desktop. 

Changing the display mode may have side effects: for example, canvases will be cleared and values sent to shaders with canvases beforehand or re-draw to them afterward if you need to.

### love.window.setPosition(x, y, displayindex=1)
Sets the position of the window on the screen.

The window position is in the coordinate space of the specified display.

### love.window.setTitle(title)
Sets the window title.

### love.window.setVSync(vsync)
Sets vertical synchronization mode.

### love.window.showMessageBox(title, message, type='info', attachtowindow=true) → success
Displays a message box dialog above the love window. The message box contains a title, optional text, and buttons.
- Variant 2: love.window.showMessageBox(title, message, buttonlist, type='info', attachtowindow=true) → pressedbutton
  Displays a message box with a customized list of buttons.

### love.window.toPixels(value) → pixelvalue
Converts a number from density-independent units to pixels.

The pixel density inside the window might be greater (or smaller) than the 'size' of the window. For example on a retina screen in Mac OS X with the highdpi window flag enabled, the window may take up the same physical size as an 800x600 window, but the area inside the window uses 1600x1200 pixels. love.window.toPixels(800) would return 1600 in that case.

This is used to convert coordinates from the size users are expecting them to display at onscreen to pixels. love.window.fromPixels does the opposite. The highdpi window flag must be enabled to use the full pixel density of a Retina screen on Mac OS X and iOS. The flag currently does nothing on Windows and Linux, and on Android it is effectively always enabled.

Most LÖVE functions return values and expect arguments in terms of pixels rather than density-independent units.
- Variant 2: love.window.toPixels(x, y) → px, py
  The units of love.graphics.getWidth, love.graphics.getHeight, love.mouse.getPosition, mouse events, love.touch.getPosition, and touch events are always in terms of pixels.

### love.window.updateMode(width, height, settings) → success
Sets the display mode and properties of the window, without modifying unspecified properties.

If width or height is 0, updateMode will use the width and height of the desktop. 

Changing the display mode may have side effects: for example, canvases will be cleared. Make sure to save the contents of canvases beforehand or re-draw to them afterward if you need to.

