# Absolutely-positioned input devices and Multitouch

When using `/dev/input/event*` for keyboard/mouse support, ordinary mice (and old trackpads)
are supported directly, via `REL_*` event types.

However, on laptops with trackpads that report `ABS_*` events, we emulate a relative mouse
device, as well as doing some simple gesture recognition (e.g. tap-to-click, drag lock,
multitouch finger tracking).

We use libevdev to get a cleaned-up stream of raw events, but libevdev doesn't try to infer
higher-level gestures. In future we may choose to add libinput as a dependency, since it *does*
do basic gesture recognition of the kind we're interested in. At the moment, though, we do not
want the extra dependency; in addition, libinput operates in a very wayland/X-centric style,
which isn't necessarily a good fit for us.

We maintain enough state to distinguish between simple absolute-positioned devices, "type A"
multitouch devices, and "type B" multitouch devices. See
<https://www.kernel.org/doc/Documentation/input/multi-touch-protocol.txt> for specifics of
"type A" vs "type B".

 - Simple absolute-positioned ("simple") devices: never emit `SYN_MT_REPORT` events or `ABS_MT_SLOT` events.
 - Type A multitouch: emit `SYN_MT_REPORT`.
 - Type B multitouch: emit `ABS_MT_SLOT`.

`BTN_TOUCH` indicates some input is active. We use this as a signal to update our simulated
mouse cursor position, but do not take it as a signal to emit click events, *except* that we do
tap-to-click detection; see use of the `moved` flag in `sqUnixEvdevKeyMouse.c`.

Each `SYN_REPORT` commits the state of the simulated mouse cursor and sends events on to the
image, resetting our state as appropriate:
 - for simple devices, no resetting is needed;
 - for type A devices, the finger count is reset to zero;
 - for type B devices, no resetting is needed.

To decide which coordinate pairs to attend to, we follow these rules:

 - for simple devices, we just take `ABS_X`/`ABS_Y` events and do tap detection using
   `BTN_TOUCH`;

 - for type A devices, we take `ABS_MT_POSITION_X`/`Y` for the *first* finger in each report;

 - for type B devices, each time a new touch is detected, if zero touches are in progress, we
   mark this touch slot as the one to attend to; when it is released, we attend to no others
   until all active touches have ended.

In all cases, `BTN_TOOL_DOUBLETAP` etc are used to let multi-finger taps substitute for middle
and right mouse button clicks.
