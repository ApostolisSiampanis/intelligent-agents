# Debug Logging Guide

## ✅ Setup Complete!

Your game now automatically logs all debug information to timestamped files in the `logs/` folder.

## 🎮 How to Run and Debug

### Option 1: Run from Godot Editor
```bash
# Open Godot and press F5 to run the game
# Logs will be saved automatically
```

### Option 2: Run from Command Line
```bash
cd /home/theo/Desktop/intelligent-agents

# Run the game
godot --path . --headless false

# Or run the specific scene
godot --path . scenes/input_screen.tscn
```

## 📁 Where Are the Logs?

Logs are saved in: `/home/theo/Desktop/intelligent-agents/logs/`

File naming pattern: `game_log_2025-10-15_14-30-45.txt`

## 🔍 What Gets Logged?

### 1. Priority Panel Events
- Button clicks (Wood, Stone, Gold, Auto)
- Resource selection
- Game manager connection status

### 2. Game Manager Events
- Village priority updates
- Control mode verification
- Game pause/resume

### 3. Village Events  
- Resource priority changes
- Control mode status
- Priority selection flag updates

### 4. Agent Events
- State transitions (IDLE → DECIDING → WALKING)
- Priority selection checks
- Movement decisions

## 📊 Analyzing the Logs

### Find Specific Issues:

**Check if buttons work:**
```bash
grep "button pressed" logs/game_log_*.txt
```

**Check village state:**
```bash
grep "Village 1 state" logs/game_log_*.txt
```

**Check agent transitions:**
```bash
grep "AGENT.*IDLE\|DECIDING" logs/game_log_*.txt
```

**Find errors:**
```bash
grep "ERROR" logs/game_log_*.txt
```

## 🐛 Common Issues to Look For

### Issue: Buttons not responding
**Search for:** `[PRIORITY PANEL] button pressed`
- If this doesn't appear → Button signal connection issue
- If it appears but nothing follows → Game manager is null

### Issue: Village not updating
**Search for:** `[VILLAGE] set_user_resource_priority`
- Check if `is_priority_selected: true` appears
- Check if `control_mode` is `USER_CONTROLLED`

### Issue: Agents not moving
**Search for:** `[AGENT] Priority selected! Transitioning`
- If this doesn't appear → Agents not detecting priority change
- Check if `is_priority_selected` flag is being read correctly

## 📝 Example Debug Session

1. **Run the game**
2. **Click the WOOD button**
3. **Wait 5 seconds**
4. **Exit the game**
5. **Open the latest log file:**
   ```bash
   cd logs
   ls -lt | head -2  # Find the latest file
   cat game_log_2025-10-15_*.txt
   ```

## 🔧 Debug Output Format

Each log line includes:
- **Timestamp**: `[14:30:45]`
- **Component**: `[PRIORITY PANEL]`, `[GAME MANAGER]`, `[VILLAGE]`, `[AGENT X]`
- **Message**: Description of what happened

Example:
```
[14:30:45] [PRIORITY PANEL] Wood button pressed
[14:30:45] [PRIORITY PANEL] select_resource called - Type: WOOD Auto: false
[14:30:45] [PRIORITY PANEL] Game manager found, calling set_village_1_priority
[14:30:45] [GAME MANAGER] set_village_1_priority called - Type: WOOD Auto: false
[14:30:45] [GAME MANAGER] Village 1 found, calling set_user_resource_priority
[14:30:45] [VILLAGE] set_user_resource_priority called - Resource: WOOD Auto: false
[14:30:45] [VILLAGE] Updated state - is_priority_selected: true control_mode: 0
[14:30:45] [GAME MANAGER] Village 1 state - is_priority_selected: true
[14:30:45] [GAME MANAGER] Village 1 state - control_mode: 0
[14:30:45] [GAME MANAGER] Village 1 state - user_selected_resource: WOOD
[14:30:45] [GAME MANAGER] Resuming game (Engine.time_scale = 1.0)
[14:30:46] [AGENT 1] Priority selected! Transitioning from IDLE to DECIDING
[14:30:46] [AGENT 3] Priority selected! Transitioning from IDLE to DECIDING
[14:30:46] [AGENT 5] Priority selected! Transitioning from IDLE to DECIDING
```

## 🎯 Next Steps

1. Run the game now
2. Select a resource priority (Wood/Stone/Gold/Auto)
3. Observe agent behavior
4. Exit the game
5. Check the log file in `logs/` folder
6. Share the log file with me so we can debug together!

---

**Note:** Logs are also printed to the Godot console in real-time, so you can watch them live in the editor's Output panel.
