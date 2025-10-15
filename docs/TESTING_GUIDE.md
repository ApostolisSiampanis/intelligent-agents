# Quick Start & Testing Guide

## Quick Start

### Running the Game

1. Open the project in Godot Engine
2. Press F5 or click the "Play" button
3. Adjust map parameters on the input screen (or use defaults)
4. Click "Start"
5. **NEW**: When the map loads, select a resource priority (Wood/Stone/Gold/Auto)
6. Game will resume automatically after selection
7. Watch your agents collect the selected resource!

## Testing Scenarios

### Scenario 1: Basic User Control
**Objective**: Verify basic resource selection works

1. Start a new game
2. Select "WOOD" priority
3. Observe:
   - ✓ Wood button turns green
   - ✓ Village 1 agents show 🌲 icon
   - ✓ Agents move toward wood resources
   - ✓ Win probability displays

**Expected**: All Village 1 agents should prioritize wood collection

---

### Scenario 2: Dynamic Priority Change
**Objective**: Test switching priorities mid-game

1. Start with "WOOD" selected
2. Wait until agents are collecting wood
3. Click "STONE" button
4. Observe:
   - ✓ Stone button turns green
   - ✓ Wood button turns white
   - ✓ Agents complete current trips
   - ✓ On next village return, agents switch to stone
   - ✓ Agent icons change to 🪨

**Expected**: Smooth transition to new priority

---

### Scenario 3: Auto Mode
**Objective**: Verify AI-assisted resource selection

1. Start with any manual selection
2. Click "AUTO" button
3. Observe:
   - ✓ Auto button turns blue
   - ✓ "Current Priority: AUTO MODE" displays
   - ✓ Agents intelligently select resources
   - ✓ Priority may change as game progresses

**Expected**: System automatically optimizes resource selection

---

### Scenario 4: Winning Probability
**Objective**: Verify probability calculation

1. Start game and watch probability
2. Let Village 1 collect some resources
3. Observe:
   - ✓ Probability increases as you collect
   - ✓ Probability decreases if Village 2 pulls ahead
   - ✓ Number updates in real-time (0-100%)

**Expected**: Probability reflects actual game state

---

### Scenario 5: Resource Depletion
**Objective**: Test warning system

1. Select a resource (e.g., GOLD)
2. Wait for gold to be depleted
3. Observe:
   - ✓ Warning message appears
   - ✓ Message says "WARNING: GOLD resources depleted!"
   - ✓ Agents continue searching
   - ✓ Warning auto-hides after 5 seconds

**Expected**: Clear warning with appropriate behavior

---

### Scenario 6: AI Adaptation (Village 2)
**Objective**: Verify Village 2 reacts to your choices

1. Select "WOOD" priority
2. Watch Village 2 agents for 30 seconds
3. Switch to "STONE"
4. Watch Village 2 agents again
5. Observe:
   - ✓ Village 2 adapts strategy
   - ✓ May compete for same resources
   - ✓ May focus on different resources if behind
   - ✓ Behavior changes based on game state

**Expected**: Village 2 shows intelligent adaptation

---

### Scenario 7: Initial Selection Requirement
**Objective**: Verify game pauses until selection

1. Start a new game
2. When map loads, don't click anything
3. Observe:
   - ✓ Agents don't move
   - ✓ Timer doesn't progress
   - ✓ "SELECT RESOURCE PRIORITY" message shows
4. Click any resource button
5. Observe:
   - ✓ Game resumes immediately
   - ✓ Agents start moving

**Expected**: Game won't start without selection

---

### Scenario 8: Village 1 vs Village 2 Competition
**Objective**: Full gameplay test

1. Start game with Auto mode
2. Play for 2-3 minutes
3. Try different manual selections
4. Observe:
   - ✓ Both villages compete for resources
   - ✓ Win probability fluctuates
   - ✓ Strategic choices affect outcome
   - ✓ One village eventually wins

**Expected**: Engaging competitive gameplay

---

## Debug Checklist

### Visual Elements
- [ ] Resource buttons appear in Village 1 panel
- [ ] Buttons have correct textures/labels
- [ ] Button colors change on selection
- [ ] Agent labels show resource icons
- [ ] Warning messages appear in red text
- [ ] Win probability shows percentage

### Functionality
- [ ] Game pauses on start
- [ ] Resource selection resumes game
- [ ] Agents respect selected priority
- [ ] Priority can be changed mid-game
- [ ] Auto mode works correctly
- [ ] Village 2 AI adapts strategy
- [ ] Resource depletion triggers warnings
- [ ] Win probability updates continuously

### Edge Cases
- [ ] All resources depleted
- [ ] All agents eliminated
- [ ] Switching priorities rapidly
- [ ] Auto mode with no resources
- [ ] Game restart after completion

## Common Issues & Solutions

### Issue: Agents not moving
**Solution**: Make sure you selected a resource priority at game start

### Issue: Buttons not highlighting
**Solution**: Check that resource_priority_panel.gd script is attached to the panel

### Issue: No emoji icons showing
**Solution**: Your system may not support emoji rendering. Edit agent.gd to use text instead:
```gdscript
# Replace emoji with text
if current_goal == Common.TileType.WOOD:
    goal_text = " [W]"
elif current_goal == Common.TileType.STONE:
    goal_text = " [S]"
elif current_goal == Common.TileType.GOLD:
    goal_text = " [G]"
```

### Issue: Win probability stuck at --%
**Solution**: Make sure you've selected initial priority to start the game

### Issue: Village 2 not adapting
**Solution**: Check that villages are linked in game_manager (setup_villages called)

### Issue: Warning messages not appearing
**Solution**: Verify resource.gd emits resource_depleted signal correctly

## Performance Monitoring

Watch for these during testing:

- **Frame Rate**: Should remain stable (60 FPS target)
- **Memory**: No significant leaks over time
- **CPU**: Winning probability calculation is lightweight
- **Responsiveness**: UI buttons should be instant

## Gameplay Balance Testing

1. **User vs AI Fairness**
   - Play 10 games with different strategies
   - Track win/loss ratio
   - Should be roughly 50/50 with good play

2. **Auto Mode Effectiveness**
   - Compare Auto vs Manual play
   - Auto should perform reasonably well
   - Should not be unbeatable or useless

3. **Strategy Viability**
   - Test focusing on single resource
   - Test balanced approach
   - Test reactive strategy
   - All should be viable

## Reporting Issues

If you find bugs or issues, note:
1. What you were doing
2. What you expected
3. What actually happened
4. Steps to reproduce
5. Any error messages in console

## Success Criteria

The feature is working correctly if:
- ✅ All testing scenarios pass
- ✅ No errors in console
- ✅ Gameplay feels responsive
- ✅ Win probability seems accurate
- ✅ AI provides good competition
- ✅ UI is clear and intuitive

## Next Steps

After successful testing:
1. Adjust AI difficulty if needed
2. Fine-tune winning probability weights
3. Consider additional visual enhancements
4. Gather user feedback
5. Plan future improvements

Happy testing! 🎮
