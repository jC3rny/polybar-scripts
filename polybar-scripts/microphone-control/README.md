# Script: microphone-control.sh

Another control script for the microphone, this time with the icons!

Use control button or left click to toggle the state. Scroll up or down to change sensitivity.

## Module

```ini
type = custom/script
interval = 1

exec = $HOME/.local/bin/microphone-control.sh --status

click-left = $HOME/.local/bin/microphone-control.sh --mute
scroll-up = $HOME/.local/bin/microphone-control.sh --volume-up
scroll-down = $HOME/.local/bin/microphone-control.sh --volume-down
```
