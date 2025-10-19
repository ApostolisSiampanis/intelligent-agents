# Quick Fix Reference - Wall Collisions

## 🎯 One-Minute Setup Guide

### What Was Fixed (Code):
✅ Physics-based movement  
✅ Wall validation in pathfinding  
✅ Larger resource detection  
✅ Proper collision layers  
✅ Better spawn positioning  

### What You Need To Do (Godot Editor):

**⚠️ CRITICAL: Add Wall Collisions to TileSet**

1. Open `scenes/map_generator.tscn` in Godot
2. Select **TileMap** node
3. Click **TileSet** in Inspector → **Edit**
4. Find and select **wall tile** (coordinates 3, 1 - stone block)
5. In bottom panel: **Physics Layers** → **Add Layer 0**
6. Click **"Create Collision Polygon from Tile"** or draw manually
7. Save the TileSet
8. Done! ✅

### Test It Works:
1. Run game (F5)
2. Press **F10** to show collision shapes
3. Watch agents bounce off walls
4. Check logs: `grep "Stuck" logs/game_log_*.txt`

---

## 🐛 Quick Troubleshooting

**Agents still pass through walls?**
→ TileSet collision shapes not added (see step 5-6 above)

**Agents get stuck?**
→ Normal! They recalculate path automatically (check logs)

**Resources not collected?**
→ Fixed (detection area now 48x48), restart game

**Agents spawn on walls?**
→ Fixed (validation added), won't happen anymore

---

## 📁 What Changed

| File | Change |
|------|--------|
| `agent.gd` | Physics movement + wall validation |
| `agent.tscn` | Collision layers (2/1) |
| `resource_collider.tscn` | Detection 16→48 px |
| `map_generator.gd` | Spawn offset 20→8 px |

---

## 📖 Full Documentation

See `docs/COLLISION_FIX_GUIDE.md` for complete details.

---

**Status:** Code ✅ | TileSet ⏳ (5 min fix)
