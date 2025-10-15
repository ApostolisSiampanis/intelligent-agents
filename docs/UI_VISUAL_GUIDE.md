# Visual UI Guide - Resource Priority Control

## Village 1 Status Panel Layout

```
┌─────────────────────────────────────────────────┐
│                                                 │
│              Village 1 (YOU)                    │
│                                                 │
│     Remaining resources to reach the goal:      │
│                                                 │
│       Stone: X    Wood: X    Gold: X            │
│                                                 │
├─────────────────────────────────────────────────┤
│         RESOURCE PRIORITY PANEL                 │
├─────────────────────────────────────────────────┤
│         RESOURCE PRIORITY                       │
│                                                 │
│   ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐         │
│   │ WOOD │ │STONE │ │ GOLD │ │ AUTO │         │
│   │  🌲  │ │  🪨  │ │  💰  │ │      │         │
│   └──────┘ └──────┘ └──────┘ └──────┘         │
│     (Green when selected)      (Blue when      │
│                                 selected)       │
│                                                 │
│   Current Priority: WOOD                        │
│                                                 │
│   Win Probability: 65%                          │
│                                                 │
│   ⚠ WARNING: STONE resources depleted!         │
│   Agents will search for more.                  │
│                                                 │
└─────────────────────────────────────────────────┘
```

## Button States

### Wood Button (Selected)
```
┌──────────────┐
│   WOOD 🌲    │  <- Green background (0.3, 0.8, 0.3)
│              │
└──────────────┘
```

### Auto Button (Selected)
```
┌──────────────┐
│     AUTO     │  <- Blue background (0.2, 0.6, 1.0)
│              │
└──────────────┘
```

### Unselected Button
```
┌──────────────┐
│   STONE 🪨   │  <- White/normal color (1, 1, 1)
│              │
└──────────────┘
```

## Agent Label Display

### Village 1 Agent (User-Controlled)
```
┌─────────────────┐
│   85% 🌲 ID 1   │  <- Shows energy, resource icon, ID
└─────────────────┘
```

### Village 2 Agent (AI-Controlled)
```
┌─────────────────┐
│   75% ID 2      │  <- Shows energy and ID only
└─────────────────┘
```

## Game Start Screen

### Before Priority Selection
```
┌─────────────────────────────────────────────────┐
│                                                 │
│      ⚠ SELECT RESOURCE PRIORITY TO START ⚠     │
│                                                 │
│   ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐         │
│   │ WOOD │ │STONE │ │ GOLD │ │ AUTO │         │
│   └──────┘ └──────┘ └──────┘ └──────┘         │
│                                                 │
│   Win Probability: --%                          │
│                                                 │
└─────────────────────────────────────────────────┘

        Game is PAUSED - Waiting for selection
```

### After Priority Selection
```
┌─────────────────────────────────────────────────┐
│                                                 │
│         Current Priority: WOOD                  │
│                                                 │
│   ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐         │
│   │ WOOD │ │STONE │ │ GOLD │ │ AUTO │         │
│   │  🌲  │ │  🪨  │ │  💰  │ │      │         │
│   └──────┘ └──────┘ └──────┘ └──────┘         │
│   ^^^^^^                                        │
│   GREEN                                         │
│                                                 │
│   Win Probability: 50%                          │
│                                                 │
└─────────────────────────────────────────────────┘

        Game is RUNNING - Agents moving
```

## Full Game Screen Layout

```
┌──────────────────────────────────────────────────────────────────────┐
│  Village 1 (YOU)                                  Village 2 (COMPUTER)│
│  ┌────────────────┐                              ┌────────────────┐  │
│  │ Remaining:     │                              │ Remaining:     │  │
│  │ S:10 W:20 G:5  │                              │ S:15 W:25 G:8  │  │
│  ├────────────────┤      ┌──────────────┐       ├────────────────┤  │
│  │  PRIORITY      │      │     GOAL     │       │   Agent List   │  │
│  │  ┌──┐ ┌──┐    │      │ S:40 W:80    │       │                │  │
│  │  │🌲│ │🪨│    │      │ G:6          │       │ Agent ID 2     │  │
│  │  └──┘ └──┘    │      │              │       │ State: WALKING │  │
│  │  ┌──┐ ┌────┐  │      │ Village X    │       │ Energy: 75%    │  │
│  │  │💰│ │AUTO│  │      │ WON!         │       │                │  │
│  │  └──┘ └────┘  │      └──────────────┘       │ Agent ID 4     │  │
│  │                │                              │ State: REFILL  │  │
│  │ Priority: WOOD │                              │ Energy: 45%    │  │
│  │ Win Prob: 65%  │                              │                │  │
│  │                │                              │                │  │
│  ├────────────────┤                              └────────────────┘  │
│  │ Agent List     │                                                  │
│  │                │          [GAME MAP]                              │
│  │ Agent ID 1     │                                                  │
│  │ State: WALKING │         [Tiles, Resources,                      │
│  │ Energy: 85% 🌲 │          Villages, Agents]                       │
│  │                │                                                  │
│  │ Agent ID 3     │                                                  │
│  │ State: DECIDE  │                                                  │
│  │ Energy: 60% 🌲 │                                                  │
│  │                │                                                  │
│  └────────────────┘                                                  │
│                                                                      │
│  [Back to Menu]                                           [Exit]     │
└──────────────────────────────────────────────────────────────────────┘
```

## Color Scheme

### Resource Buttons
- **Normal State**: White (1.0, 1.0, 1.0, 1.0)
- **Selected State**: Green (0.3, 0.8, 0.3, 1.0)
- **Auto Selected**: Blue (0.2, 0.6, 1.0, 1.0)

### Text Colors
- **Normal Text**: Default theme color
- **Warning Text**: Red (1.0, 0.3, 0.3, 1.0)
- **Priority Text**: Default theme color
- **Win Probability**: Default theme color

## Interaction Flow

1. **Game Start**
   ```
   User clicks "Start" on input screen
        ↓
   Map loads, game PAUSES
        ↓
   "SELECT RESOURCE PRIORITY" message shows
        ↓
   User clicks resource button
        ↓
   Button highlights GREEN/BLUE
        ↓
   Game RESUMES automatically
        ↓
   Agents start moving toward selected resource
   ```

2. **During Game**
   ```
   User clicks different resource button
        ↓
   New button highlights
        ↓
   Old button returns to white
        ↓
   Agent labels update with new icon
        ↓
   Agents switch on next village visit
   ```

3. **Resource Depleted**
   ```
   Resource reaches 0 quantity
        ↓
   Check if user selected that resource
        ↓
   If YES: Show warning message
        ↓
   Warning auto-hides after 5 seconds
        ↓
   Agents continue searching
   ```

## Emoji Icons Used

- 🌲 Wood/Tree resource
- 🪨 Stone/Rock resource
- 💰 Gold/Money resource
- ⚠ Warning indicator

**Note**: If emojis don't render properly, you can replace them with:
- Text alternatives: "W", "S", "G"
- Colored squares: █ with different colors
- Sprite icons from the tileset
