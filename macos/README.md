# Native macOS settings

Use Dark Mode and the graphite accent color in Appearance settings.
These are instructions, not a dump of system preferences.

The desktop uses native left/right edge snapping. Top-edge maximize and Option-drag tiling are disabled.
The corresponding WindowManager preferences are:

```text
EnableTilingByEdgeDrag = true
EnableTopTilingByEdgeDrag = false
EnableTilingOptionAccelerator = false
```

Use Left Command for normal application shortcuts. The Karabiner configuration remaps Right Command.
The existing three-modifier arrow bindings snap left/right, enter native full screen, or return to a floating maximized window.
Caps Lock with H/J/K/L focuses windows without moving them.

Kitty uses 95% background opacity and blur 24. SketchyBar uses a separate near-95% background color.
Text and raised panels remain opaque. This is frosted transparency, not a claim to reproduce Apple's full Liquid Glass renderer.
