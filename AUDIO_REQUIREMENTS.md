# Audio Requirements Document
## Banana Clock iOS App

This document outlines all cached audio requirements for the Banana Clock iOS application based on code analysis.

---

## Quick Reference Checklist

### 🎵 Background Music (6 files - .aac/.mp3)
- [ready] `ai_music_chill_vibes` - Relaxing background music
- [x] `ai_music_upbeat` - Energetic morning music  
- [ready] `ai_music_nature_sounds` - Nature/ambient sounds
- [x] `ai_music_ambient` - Ambient atmospheric music
- [] `ai_music_classical` - Classical music selection
- [] `ai_music_jazz` - Jazz music selection

### 🔔 Alarm Sounds (11 files - .caf)
- [ ] `alarm_glass_horizon.caf` - Glass Horizon alarm sound
- [ ] `alarm_pulse_shift.caf` - Pulse Shift alarm sound
- [ ] `alarm_morning_monks.caf` - Morning Monks alarm sound  
- [ ] `alarm_orbital_bounce.caf` - Orbital Bounce alarm sound
- [ ] `alarm_wood_wake.caf` - Wood Wake alarm sound
- [ ] `alarm_dream_exit.caf` - Dream Exit alarm sound
- [ ] `alarm_lofi_lift.caf` - Lo-Fi Lift alarm sound
- [ ] `alarm_spark_taps.caf` - Spark Taps alarm sound
- [ ] `alarm_sungarden.caf` - SunGarden alarm sound
- [ ] `alarm_chronotriggered.caf` - ChronoTriggered alarm sound
- [ ] `alarm_times_up.caf` - Time's Up alarm sound

### 🔊 UI/Timer Sounds (5 files - .caf)
- [ ] `timer_complete.caf` - Timer completion sound
- [ ] `stopwatch_countdown_tick.caf` - Countdown tick (3-2-1)
- [ ] `stopwatch_countdown_start.caf` - Countdown complete/start
- [ ] `converter_countdown_tick.caf` - World clock converter tick (optional)
- [ ] `converter_countdown_complete.caf` - Converter activation (optional)

### 🎤 Fallback AI Audio (3 files - .aac)
- [ ] `ai_wakeup_generic_voice1.aac` - Generic wake-up (Voice 1)
- [ ] `ai_wakeup_generic_voice2.aac` - Generic wake-up (Voice 2)  
- [ ] `ai_wakeup_generic_voice3.aac` - Generic wake-up (Voice 3)

**Total: 25 audio files**

---

## 1. Alarm Sounds
**Location in code**: `AudioService.swift:185-201`, `alarm-sound-model.swift:3-48`
**Format**: `.caf` files
**Implementation**: Located in `Bundle.main` and loaded via `AVAudioPlayer`

### Required Files:
- `alarm_glass_horizon.caf` - Glass Horizon alarm sound
- `alarm_pulse_shift.caf` - Pulse Shift alarm sound
- `alarm_morning_monks.caf` - Morning Monks alarm sound  
- `alarm_orbital_bounce.caf` - Orbital Bounce alarm sound
- `alarm_wood_wake.caf` - Wood Wake alarm sound
- `alarm_dream_exit.caf` - Dream Exit alarm sound
- `alarm_lofi_lift.caf` - Lo-Fi Lift alarm sound
- `alarm_spark_taps.caf` - Spark Taps alarm sound
- `alarm_sungarden.caf` - SunGarden alarm sound
- `alarm_chronotriggered.caf` - ChronoTriggered alarm sound
- `alarm_times_up.caf` - Time's Up alarm sound

**Usage**: Standard alarm sounds that loop indefinitely until dismissed. Users can select from picker view.

---

## 2. AI Wake-Up Background Music
**Location in code**: `AudioService.swift:54-136`, `alarm-model.swift:246-273`
**Format**: Audio files (format TBD, likely `.aac` or `.mp3`)
**Implementation**: Played through `AVAudioEngine` with volume mixing and fade controls

### Required Files by Category:
- `ai_music_chill_vibes.[ext]` - Relaxing background music
- `ai_music_upbeat.[ext]` - Energetic morning music  
- `ai_music_nature_sounds.[ext]` - Nature/ambient sounds
- `ai_music_ambient.[ext]` - Ambient atmospheric music
- `ai_music_classical.[ext]` - Classical music selection
- `ai_music_jazz.[ext]` - Jazz music selection

**Usage**: Background music for AI wake-up sequences, played at low volume initially and faded in over 30 seconds. Loops continuously during AI voice playback.

---

## 3. Timer Completion Sound
**Location in code**: `AudioService.swift:212-225`
**Format**: `.caf` file
**Implementation**: Single-play sound via `AVAudioPlayer`

### Required File:
- `timer_complete.caf` - Timer completion notification sound

**Usage**: Played when countdown timers reach zero. Non-looping, single playback.

---

## 4. Stopwatch Countdown Sounds
**Location in code**: `stopwatch-view.swift:471-480`
**Format**: System sounds (AudioServices)
**Implementation**: Uses `AudioServicesPlaySystemSound()` 

### Current Implementation:
- **Countdown tick**: System Sound ID `1103` (beep sound)
- **Countdown start**: System Sound ID `1104` (different beep)

### Recommended Cached Files:
- `stopwatch_countdown_tick.caf` - Individual countdown second sound (3-2-1)
- `stopwatch_countdown_start.caf` - Sound when countdown reaches zero and stopwatch starts

**Usage**: Plays during 3-second countdown before stopwatch starts. Tick sound for each second, start sound when countdown completes.

---

## 5. World Clock Converter Countdown
**Location in code**: `world-clock-view.swift:142-177`
**Format**: No audio currently implemented
**Implementation**: Visual countdown only (10 seconds)

### Recommended Files:
- `converter_countdown_tick.caf` - Countdown tick for timezone converter
- `converter_countdown_complete.caf` - Sound when converter activates

**Usage**: Optional audio feedback for 10-second countdown in timezone converter feature.

---

## 6. Generic Fallback Audio
**Location in code**: `AudioService.swift:273-308`
**Format**: `.aac` files (AI-generated content)
**Implementation**: Downloaded and cached in Documents directory

### Required Files:
- `ai_wakeup_generic_voice1.aac` - Generic wake-up content (Voice 1)
- `ai_wakeup_generic_voice2.aac` - Generic wake-up content (Voice 2)  
- `ai_wakeup_generic_voice3.aac` - Generic wake-up content (Voice 3)

**Usage**: Fallback AI wake-up content when daily generation fails or network is unavailable.

---

## Implementation Notes

### File Naming Conventions:
- **Alarm sounds**: `alarm_{sound_name}.caf`
- **AI music**: `ai_music_{category}.{ext}`
- **Timer sounds**: `timer_{action}.caf`
- **Stopwatch sounds**: `stopwatch_{action}.caf`
- **Converter sounds**: `converter_{action}.caf`
- **Generic AI**: `ai_wakeup_generic_{voice}.aac`

### Code Integration Points:

1. **AlarmSound enum** (`alarm-sound-model.swift:30-47`):
   ```swift
   var fileName: String {
       return "alarm_{rawValue}"
   }
   ```

2. **AudioService.playAlarmSound()** (`audio-service.swift:185-201`):
   ```swift
   guard let soundURL = Bundle.main.url(
       forResource: soundIdentifier,
       withExtension: "caf"
   )
   ```

3. **AudioService.playTimerComplete()** (`audio-service.swift:212-225`):
   ```swift
   guard let soundURL = Bundle.main.url(
       forResource: "timer_complete",
       withExtension: "caf"
   )
   ```

4. **AI Wake-Up Music Loading** (`audio-service.swift:80-81`):
   ```swift
   let musicFile = try AVAudioFile(forReading: musicURL)
   ```

5. **Stopwatch Countdown** (`stopwatch-view.swift:471-480`):
   ```swift
   // Replace with cached audio
   AudioServicesPlaySystemSound(1103) // -> playSound("stopwatch_countdown_tick")
   AudioServicesPlaySystemSt seciound(1104) // -> playSound("stopwatch_countdown_start")
   ```

### Audio Session Configuration:
- **Category**: `.playback` with `.mixWithOthers` and `.allowAirPlay` options
- **Background playback**: Enabled for alarm functionality
- **Remote control**: Integrated with MPRemoteCommandCenter

### Quality Requirements:
- **Sample Rate**: 44.1kHz recommended for iOS compatibility
- **Bit Depth**: 16-bit minimum
- **Duration**: 
  - Alarm sounds: 10-30 seconds (will loop)
  - AI music: 3-5 minutes (will loop)
  - Timer/UI sounds: 1-3 seconds (single play)
  - Generic AI content: 30-90 seconds

---

## Questions for Clarification:

1. **AI Music Format**: What audio format should be used for background music files? (.mp3, .aac, .m4a)
2. **AI Music Sources**: Will these be original compositions or licensed tracks?
3. **Stopwatch Sounds**: Should we replace system sounds with custom audio for better control?
4. **World Clock Audio**: Is audio feedback desired for the timezone converter countdown?
5. **Volume Levels**: Should different sound categories have different default volume levels?