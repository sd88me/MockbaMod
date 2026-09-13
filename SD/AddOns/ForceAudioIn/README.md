# ForceAudioIn

The **shared audio-injection tap** for the Force - a prerequisite addon,
not a synth in its own right. It injects synthesized/generated audio into
the Force's own audio-in capture path, so a separate process's output
becomes audible on a normal Audio-In track - the inverse of the
`ForceLinkAudio` addon (which taps `snd_pcm_writei` to extract what the
Force plays; this taps `snd_pcm_readi` to inject audio into what it
captures).

Other addons that want to inject audio - [`force-maze`](https://github.com/sd88me/force-maze)'s
`ForceMazeVoice`, and any future ones - depend on this addon being
enabled. They don't bundle their own copy of `forceAudioIn.so` or arm
`LD_PRELOAD` themselves; they just attach to the tap this addon arms.

## How it works

`forceAudioIn.so` is `LD_PRELOAD`'d into `/usr/bin/MPC` and interposes
`snd_pcm_readi` by symbol name (`dlsym(RTLD_NEXT, ...)`) - not raw address
patching, so it has no firmware-version dependency. It mixes (sums, never
replaces) audio from up to **4 simultaneous** POSIX shared-memory rings
(`/forceAudioInject0`..`/forceAudioInject3`) into whatever real hardware
audio MPC reads, so a real instrument plugged into the physical input
keeps working unmodified alongside any injected voices. Each voice has its
own gain/channel-routing/enabled state.

A background thread lazily attaches any voice ring that appears after
boot - or reappears, e.g. a voice host that stops and restarts its ring
under a fresh identity - within ~2s, no `acvs` restart needed.

`injectTone` is a minimal stand-in producer (a fixed sine wave), started
on demand from the nodeServer Modules page (`/moduler`) - useful to prove
the injection path works before wiring up a real synth. A real voice host
(like `force-maze`'s `maze_host`) replaces it, writing rendered audio into
its own slot's ring instead.

## Enable

```
manage.sh ENABLE    # arms the tap at boot, persistently - attaches NOTHING
```

This only arms `forceAudioIn.so` with **zero voices** - proven safe across
every repeated-restart test run against it, including a real reboot. It
does not start `injectTone` or any other producer. Start/stop a voice from
the nodeServer Modules page instead, whenever you actually want one
running - never by editing this addon's own scripts.

Logs: `/tmp/forceAudioIn.log` (the shared tap).

## The hard rule

**Never restart `acvs` while any voice is attached.** Extensive live
testing found that doing so reliably kills pads/buttons (occasionally
wifi) - on the very first restart, not gradually. The mechanism is still
unidentified despite ruling out symbol collision, a background diagnostics
thread, the per-sample mix loop itself, and both co-loaded libraries'
constructors (confirmed inert via disassembly) - see
`mockbamod-module-creator`'s `references/audio-injection.md` for the full
investigation. `forceAudioIn.so` armed with zero voices, by contrast, has
never failed a single test. So: enable this addon once (arms the tap,
persists across boots, zero voices), then only ever start/stop voices via
the Modules page, and never restart `acvs` manually while one is running.

## Notes

- Multiple simultaneous voices from different addons are supported and
  intentional (each takes its own `--slot` 0-3) - this used to say the
  opposite (only one producer at a time); that's no longer true as of the
  multi-voice mixer.
- See `mockbamod-module-creator`'s `references/audio-injection.md` for the
  full design story (clock-rate handling, the boot-race constraint, why
  this class of `LD_PRELOAD` use is lower-risk than raw binary patching,
  and the still-open pads-dead-on-restart investigation).
