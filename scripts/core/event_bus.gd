extends Node
## Global signal hub. Systems talk through signals so they stay decoupled.

@warning_ignore("unused_signal")
signal camera_mode_changed(mode: int)
