# User Control Feature - Village 1 Resource Priority System

## Overview
This feature allows the user to control Village 1 by selecting which resources their agents should prioritize, while Village 2 remains AI-controlled. The system includes an intelligent "Auto" mode and provides real-time winning probability calculations.

## Features

### 1. Resource Priority Selection
- **Location**: Village 1 status panel in the game screen
- **Controls**: 
  - Wood Button: Prioritizes wood collection
  - Stone Button: Prioritizes stone collection
  - Gold Button: Prioritizes gold collection
  - Auto Button: Enables AI-assisted priority selection

### 2. Dynamic Priority Changes
- Users can change resource priorities at any time during the game
- All Village 1 agents will complete their current task, then switch to the new priority on their next trip to the village
- Visual feedback shows which resource is currently selected (green highlight)

### 3. Auto Mode
The Auto mode implements an intelligent algorithm that:
- Calculates the best resource to prioritize based on:
  - Resource gap between villages
  - Agent capabilities (carry capacity, speed, energy)
  - Available resources on the map
  - Current completion percentage
- Recalculates priorities every time an agent returns to the village
- Shows "AUTO MODE" indicator in the UI

### 4. Winning Probability Display
- **Real-time calculation** displayed as a percentage (0% to 100%)
- **Calculation factors** (weighted):
  - Resource completion percentage (40%)
  - Number of active agents (30%)
  - Agent capabilities (30%)
- Updates continuously during gameplay

### 5. Visual Indicators
- **Agent Labels**: Village 1 agents display emoji indicators showing their current target:
  - 🌲 for Wood
  - 🪨 for Stone
  - 💰 for Gold
- **Button Highlighting**:
  - Green: User-selected resource
  - Blue: Auto mode active
  - White: Not selected

### 6. Resource Depletion Warnings
- Warning message appears when selected resource is depleted
- Message: "WARNING: [RESOURCE] resources depleted! Agents will search for more."
- Agents continue searching for the selected resource
- Warning auto-hides after 5 seconds

### 7. Initial Priority Selection Requirement
- Game pauses at start until user selects initial priority
- Message: "⚠ SELECT RESOURCE PRIORITY TO START ⚠"
- Game resumes automatically after selection

### 8. AI Adaptation (Village 2)
Village 2's AI adapts its strategy based on game state using a combination of tactics:

#### Counter-Strategy (50% weight)
- Monitors Village 1's selected resource
- Increases priority for resources the user is targeting to compete directly

#### Race Strategy (30% weight)
- Analyzes completion ratios for each resource
- Boosts priority for resources where Village 2 is ahead
- Reduces priority for resources where Village 1 has significant lead

#### Adaptive Strategy (20% weight)
- If Village 2 is losing overall (>20% behind):
  - Focuses on resources that are close to completion (<30% remaining)
  - Takes calculated risks to catch up
- If Village 2 is winning:
  - Maintains balanced approach

## Technical Implementation

### Key Files Modified

1. **village.gd**
   - Added `ControlMode` enum (USER_CONTROLLED, AI_CONTROLLED)
   - Added `set_user_resource_priority()` method
   - Implemented `calc_ai_strategy_multiplier()` for Village 2 adaptation
   - Modified `calc_capability_dict()` to respect user control

2. **game_manager.gd**
   - Added `calculate_winning_probability()` method
   - Added `set_village_1_priority()` method
   - Implemented village linking for AI strategy
   - Added signals for resource depletion and priority changes

3. **agent.gd**
   - Modified `_physics_process()` to check priority selection
   - Updated label display to show resource indicators
   - Added pause for user-controlled villages without priority

4. **resource_priority_panel.gd** (NEW)
   - Manages UI for resource selection
   - Handles button states and visual feedback
   - Displays winning probability
   - Shows warnings for depleted resources

5. **resource.gd**
   - Added resource depletion signal
   - Tracks depletion state

6. **map_generator.gd**
   - Connects resource priority panel to game manager
   - Handles resource depletion warnings
   - Manages game pause/resume for initial selection

### Code Architecture

```
User Input (Resource Priority Panel)
    ↓
GameManager.set_village_1_priority()
    ↓
Village.set_user_resource_priority()
    ↓
Agent.assign_resource_goal() 
    ↓
Village.calc_capability_dict()
    ↓
Agent changes goal on next village visit
```

### AI Decision Flow (Village 2)

```
Agent reaches village
    ↓
GameManager.assign_resource_goal()
    ↓
Village.calc_capability_dict()
    ↓
Village.calc_capability() (for each resource)
    ↓
Village.calc_ai_strategy_multiplier()
    ↓
    Analyzes:
    - Opponent's selected resource
    - Completion ratios
    - Overall game state
    ↓
Returns best resource with adjusted priority
```

## Usage Guide

### For Players

1. **Starting the Game**
   - Launch the game as normal
   - When the map loads, the game will pause
   - Select your initial resource priority from the buttons
   - Game automatically resumes after selection

2. **Changing Priority**
   - Click any resource button at any time
   - Your agents will switch to the new resource after their next village visit
   - Watch the visual indicators on agents to see their current targets

3. **Using Auto Mode**
   - Click the "AUTO" button
   - The system will automatically select the best resource
   - You can switch back to manual mode at any time

4. **Monitoring Progress**
   - Check "Win Probability" percentage regularly
   - Higher percentage = better chance of winning
   - Adjust strategy based on probability trends

5. **Handling Depleted Resources**
   - If your selected resource runs out, a warning appears
   - Agents will continue searching (may find more)
   - Consider switching to a different resource

### Strategy Tips

- **Early Game**: Use Auto mode to let AI optimize while you learn
- **Mid Game**: Switch to manual if you see Village 2 focusing on a specific resource
- **Late Game**: Prioritize the resource closest to completion
- **When Losing**: Try different resources to find an advantage
- **When Winning**: Maintain focus on completing remaining resources

## Future Enhancements

Potential improvements for future versions:
- Resource availability indicators (show remaining resources on map)
- Historical priority tracking (show past selections)
- Advanced statistics (resources collected per minute, etc.)
- Multiple difficulty levels for Village 2 AI
- Ability to set priority percentages (e.g., 70% wood, 30% stone)
- Predictive analytics showing estimated completion times

## Troubleshooting

**Issue**: Game won't start after map loads
- **Solution**: Make sure you've selected a resource priority button

**Issue**: Agents not switching to selected resource
- **Solution**: Wait for agents to return to village; they complete current tasks first

**Issue**: Winning probability seems inaccurate
- **Solution**: Probability is based on current state; it changes as game progresses

**Issue**: Warning messages not disappearing
- **Solution**: They auto-hide after 5 seconds; you can also change priority to clear them
