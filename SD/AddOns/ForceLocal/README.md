# ForceLocal

Publishes the Force's mDNS hostname (`force.local`) on the LAN, the same
way `move.local` works for Ableton Move — so you can reach it by name
instead of tracking its DHCP IP.

## How it works

Runs a standalone `avahi-daemon` (binary + libs bundled here, reused from
the `rtpMIDI` addon) with D-Bus disabled (`avahi-daemon.conf`) and
`--no-drop-root`, so it never touches shared `/etc/dbus-1` policy or needs
a dedicated system user — it just answers mDNS queries for the device's
existing hostname (`force`, set at the OS level already).

## Enable

```
manage.sh ENABLE
```

No `acvs` restart needed — this never touches `LD_PRELOAD` or the main
app, it's a fully independent process.

## Known caveat

The Force's own `az01-network-midi` service (used for RTP-MIDI/AppleMIDI
discovery) also touches mDNS. Coexistence has worked in testing (this
addon logs a "detected another mDNS stack" warning at startup, which is
informational, not an error) but hasn't been stress-tested. If you notice
`force.local` becoming flaky, that service is the first thing to check —
this addon deliberately doesn't stop or otherwise touch it.
