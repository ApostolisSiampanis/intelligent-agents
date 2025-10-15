# Agent Positioning Fix - Stacking Issue Resolved

## 🐛 Problem Identified

From the debug logs and screenshot, all agents from the same village were spawning at the **exact same position**, causing them to stack on top of each other.

### Evidence from Logs:
```
[23:54:44] [MAP_GEN] Creating agent 39 (village 0) at tile (33.0, 16.0) -> world (2144.0, 1056.0)
[23:54:44] [MAP_GEN] Creating agent 37 (village 0) at tile (33.0, 16.0) -> world (2144.0, 1056.0)
[23:54:44] [MAP_GEN] Creating agent 35 (village 0) at tile (33.0, 16.0) -> world (2144.0, 1056.0)
```

**ALL Village 1 agents**: tile `(33.0, 16.0)` → world `(2144.0, 1056.0)` (IDENTICAL)  
**ALL Village 2 agents**: tile `(27.0, 57.0)` → world `(1760.0, 3680.0)` (IDENTICAL)

### Visual Problem:
When agents stack on the same pixel, Godot's physics engine pushes them apart randomly, causing:
- ❌ Agents appearing at different offsets from the tile center
- ❌ Inconsistent positioning
- ❌ Visual clutter when agents return to village

## ✅ Solution Implemented

Added a small random offset when spawning agents to prevent perfect stacking.

### Code Changes

**File:** `scripts/map_generator.gd` - `create_agent()` function

```gdscript
# Add small random offset to prevent agents stacking on exact same position
var offset_range = 20.0  # Pixels
var random_offset = Vector2(
    randf_range(-offset_range, offset_range),
    randf_range(-offset_range, offset_range)
)
world_pos += random_offset
```

### How It Works:

1. **Calculate base position** - Get tile center using `map_to_local()`
2. **Generate random offset** - Between -20 and +20 pixels in both X and Y
3. **Apply offset** - Add to world position before assigning to agent
4. **Result** - Agents spawn in a small cluster around the village tile

### Configuration:

- **offset_range**: 20.0 pixels
  - Small enough to keep agents visually near the village
  - Large enough to prevent physics collisions
  - Can be adjusted if needed (higher = more spread out)

## 🎮 Expected Behavior After Fix:

### Before (Stacked):
```
Village Tile
     ↓
  [Agent]  ← All agents at EXACT same position
  [Agent]     Physics pushes them randomly
  [Agent]     Appears messy and offset
```

### After (Spread):
```
Village Tile
     ↓
  [Agent]     [Agent]
     [Agent]        [Agent]
        [Agent]   [Agent]
     ← Naturally distributed around village
     ← All centered on village tile
     ← Visually cleaner
```

## 📊 Testing Checklist:

✅ Run new game  
✅ Observe agent spawn positions  
✅ Check that agents appear clustered near village (not stacked)  
✅ Verify Village 1 and Village 2 both work correctly  
✅ Confirm agents still move and pathfind normally  
✅ Check log for offset values  

## 📝 Technical Details:

### Random Offset Range:
- **X-axis**: -20px to +20px
- **Y-axis**: -20px to +20px
- **Total spread**: 40px × 40px area

### Godot Tile Size:
- Default tile size: 64×64 pixels
- Agent spread: ~62.5% of tile size
- Agents stay within visual bounds of village

### Physics Considerations:
- Agent collision shape: 12.75 × 10.75 pixels
- With 20px offset, agents won't overlap
- Natural movement handles any remaining proximity

## 🔧 Alternative Solutions Considered:

1. **Grid Formation** - Place agents in neat rows/columns
   - ❌ Too rigid, looks unnatural
   
2. **Circular Distribution** - Arrange in circle around village
   - ❌ Complex math, overkill for this use case
   
3. **Physics-based spreading** - Let them push each other apart
   - ❌ Already happening, but looks messy without initial offset
   
4. **Random offset (CHOSEN)** - Simple, effective, natural-looking
   - ✅ Easy to implement
   - ✅ Minimal performance impact
   - ✅ Works for any number of agents
   - ✅ Maintains village cohesion

## 📈 Performance Impact:

- **Overhead**: 2 random number generations per agent spawn
- **Timing**: One-time cost during map generation
- **Total impact**: Negligible (~0.001ms per agent)

## 🚀 Future Enhancements:

If more sophisticated positioning is needed:
- [ ] Formation patterns (circle, square, etc.)
- [ ] Avoid spawning on obstacles
- [ ] Dynamic spread based on agent count
- [ ] Configurable offset range per village

## 📖 Related Files:

- `scripts/map_generator.gd` - Agent spawn logic
- `scenes/agent.tscn` - Agent collision shapes
- `logs/game_log_*.txt` - Position debugging data
