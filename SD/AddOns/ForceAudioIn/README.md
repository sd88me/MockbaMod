# ForceAudioIn

Injects synthesized/generated audio into the Force's own audio-in capture
path, so a separate process's output becomes audible on a normal Audio-In
track — the inverse of the `ForceLinkAudio` addon (which taps
`snd_pcm_writei` to extract what the Force plays; this taps
`snd_pcm_readi` to inject audio into what it captures).

## How it works

`forceAudioIn.so` is `LD_PRELOAD`'d into `/usr/bin/MPC` and interposes
`snd_pcm_readi` by symbol name (`dlsym(RTLD_NEXT, ...)`) — not raw address
patching, so it has no firmware-version dependency. It mixes (adds, never
replaces) audio from a POSIX shared-memory ring (`/forceAudioInject`) into
whatever real hardware audio MPC reads, so a real instrument plugged into
the physical input keeps working unmodified alongside the injected signal.

`injectTone` is a minimal stand-in producer (a fixed sine wave) used to
prove the injection path works — a real synth/generator process would
replace it, writing rendered audio into the same shared-memory ring
instead. See [`force-maze`](https://github.com/sd88me/force-maze) for a
complete, real synth built on top of this exact mechanism.

## Enable

```
manage.sh ENABLE    # restarts acvs to arm the LD_PRELOAD tap
```

Test tone frequency/gain/channels are set in `config`. Logs:
`/tmp/forceAudioIn.log` (the mix tap) and `/tmp/injectTone.log` (the test
producer).

## Notes

- Only one producer should own the `/forceAudioInject` ring at a time —
  don't run this alongside another addon (like `force-maze`'s engine) that
  also produces into it.
- See `mockbamod-module-creator`'s `references/audio-injection.md` for the
  full design story (clock-rate handling, the boot-race constraint, why
  this class of `LD_PRELOAD` use is lower-risk than raw binary patching).
