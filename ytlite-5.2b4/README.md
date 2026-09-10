# YTLite 5.2b4 — extracted tweak files

These are the contents of `com.dvntm.ytlite_5.2b4_iphoneos-arm.deb`, pulled
directly from https://github.com/dayanch96/YTLite/releases/tag/v5.2b4 — the
last free release before the 5.2+ subscription requirement.

```
YTLite.dylib               tweak binary (~15.8 MB, arm64)
YTLite.plist               filter plist (MobileSubstrate / libsubstrate)
YTLite.bundle/             resources (Assets.car, SponsorAudio.m4a, localizations)
```

## Inject into a YouTube IPA

Use `cyan` (pyzule-rw) — same tool the upstream CI uses:

```sh
cyan -i youtube.ipa -o youtube-plus.ipa \
     -uwef YTLite.dylib YTLite.plist /Library/Application\ Support/YTLite.bundle
```

## Compatibility

| YouTube version | Compatible tweak | Notes |
|---|---|---|
| `20.21.6` (≈ Nov 2025) | **5.2b4** (this folder) | Hooks should match internals |
| `21.16.2` (≈ Jul 2026) | `5.2.2` (released) | Use upstream CI build |

Using a newer tweak against older YouTube = features silently don't work.
Using an older tweak against newer YouTube = crash on launch (watchdog kill).

## What's NOT included

- My `CustomYTMute.xm` audio-session fix (that lives on the
  `fix/audio-session-ambient` branch in `CustomYTMute.xm` and only
  applies to source builds, not to this prebuilt `.dylib`).
- The source code for the hooks — to modify, fork the upstream repo
  and rebuild from source.
