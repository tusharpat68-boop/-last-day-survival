extends Node
## Global signal hub. Systems talk through signals so they stay decoupled.

@warning_ignore("unused_signal")
signal camera_mode_changed(mode: int)
@warning_ignore("unused_signal")
signal interact_prompt_changed(text: String)
@warning_ignore("unused_signal")
signal message_posted(text: String)
