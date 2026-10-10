# Xbox controller forwarding on Android and Windows

During an Android-to-Windows remote session, the Android app forwards Xbox button, trigger, D-pad, and stick state in a RustDesk protocol message. Android devices are filtered by Microsoft's USB vendor ID (`0x045e`); other gamepads are left to the normal Android/RustDesk input path. The S21 test controller reported vendor/product ID `045e:0b12` and produced both button and analog-stick events.

The Windows host creates an Xbox 360-compatible virtual controller after the first report. Windows games can then read it through XInput. The virtual controller is removed when the input worker ends with the remote session.

## Requirements

- Install a Windows host build and an Android client build that both contain this feature. Older RustDesk versions do not forward the new protocol message.
- Install and start the ViGEmBus driver on the controlled Windows PC before connecting. The driver and its client library are retired and no longer receive updates; see the [official end-of-life statement](https://docs.nefarius.at/projects/ViGEm/End-of-Life/).
- Keep keyboard/control permission enabled for the RustDesk session. Gamepad reports use the same remote-control permission gate.

## Building from source

Regenerate the Flutter Rust bridge after changing `src/flutter_ffi.rs`:

```sh
flutter_rust_bridge_codegen --rust-input ./src/flutter_ffi.rs --dart-output ./flutter/lib/generated_bridge.dart
```

The generated Dart bridge is ignored by Git in this repository, so a clean checkout needs this step before building the Flutter client.

Forwarding is enabled automatically only for Android sessions whose peer reports Windows as its platform. Button state is released when forwarding stops or the Android activity pauses.

## Verified checkpoint

On 2026-10-02, one Xbox controller was verified end to end from the Galaxy S21 to the Windows host. The Windows diagnostic log confirmed incoming reports and a ready ViGEm Xbox 360 target; the user confirmed the controller works in-game. This checkpoint supports one controller per RustDesk session. Multiple controllers are not supported yet: reports do not carry a controller ID, and the Windows input worker owns one virtual target.

## Two-controller work in progress

The follow-up implementation now carries Android's per-device ID and a disconnect flag through the protocol. The Windows input worker keeps a separate ViGEm target for each ID and removes that target when Android reports the controller unplugged. The Windows build and Rust type-check pass; the Android package has not been rebuilt or tested with two controllers yet.
