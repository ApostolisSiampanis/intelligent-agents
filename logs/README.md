# Debug Logs

This folder contains debug log files generated during gameplay.

## Log File Format

Log files are automatically created with timestamps:
- Format: `game_log_YYYY-MM-DD_HH-MM-SS.txt`
- Example: `game_log_2025-10-15_14-30-45.txt`

## What's Logged

The debug logger tracks the entire priority selection flow:

1. **Button Clicks** - When user clicks Wood/Stone/Gold/Auto buttons
2. **Priority Panel** - Resource selection and game manager communication
3. **Game Manager** - Village priority setting and game state changes
4. **Village** - Control mode, priority flags, and resource selection
5. **Agents** - State transitions (IDLE → DECIDING → WALKING)

## How to Use

1. **Run the game** normally (F5 in Godot or run from command line)
2. **Play through the scenario** you want to debug
3. **Exit the game** - the log file will be automatically closed
4. **Open the latest log file** in this folder to review what happened

## Finding Issues

Search for these keywords in the log:
- `ERROR` - Critical issues
- `IDLE` - Agents waiting state
- `DECIDING` - Agents starting movement
- `is_priority_selected` - Priority selection status
- `control_mode` - Village control type

## Example Log Entry

```
[14:30:45] [PRIORITY PANEL] Wood button pressed
[14:30:45] [PRIORITY PANEL] select_resource called - Type: WOOD Auto: false
[14:30:45] [GAME MANAGER] set_village_1_priority called - Type: WOOD Auto: false
[14:30:45] [VILLAGE] set_user_resource_priority called - Resource: WOOD Auto: false
[14:30:45] [AGENT 1] Priority selected! Transitioning from IDLE to DECIDING
```
