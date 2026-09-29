# GALAGA CPC — Game Manual

## Objective

Pilot your fighter, destroy the alien formations, and score as many points as possible. The game advances through successive stages until all lives are lost.

![Title screen and point table](assets/Screenshots/menu.png)

*The title screen alternates between point values and the Hall of Fame.*

## Starting the game

1. Start the Amstrad CPC or emulator with the game disk inserted.
2. At the Locomotive BASIC `Ready` prompt, type `RUN"galaga.bas` and press Enter.
3. The intro screen appears. Press **Space** or wait 10 seconds for the game to load.
4. At the title screen, choose a difficulty with left/right, then press **Space** or joystick **Fire 1** to begin playing.

## Controls

| Action | Keyboard | Joystick |
|---|---|---|
| Move left | Left arrow or `O` | Left |
| Move right | Right arrow or `P` | Right |
| Fire / select | `Space` | Fire 1 |
| Pause / resume | `H` | — |

Hold the fire button for repeated shots. While paused, press `H` again to resume.

## Difficulty

Choose **Easy**, **Medium**, **Hard**, or **Hardest** on the title screen with the left/right arrows, `O` / `P`, or the joystick. **Easy** preserves the game's original behavior. Higher settings add enemy entry patterns from the center and lower sides, tighten the entry formation timing, bring attacks and firing to earlier stages, and add more firing enemies. The pressure increases further as you progress through the stages.

## Stages and enemies

- Each regular stage begins with a 28-enemy entry formation. Destroy every enemy to advance.
- Every fourth stage, starting at stage 3 (3, 7, 11, ...), is a bonus stage. Hit as many targets as possible before it ends.
- On stages 10–19, one random enemy from each entry group fires. On stages 20–29, two fire; from stage 30 onward, three fire.
- From stage 40 onward, enemy shots also travel diagonally.
- Enemy point values are shown on the title screen. Scores vary by enemy type and whether it is destroyed in formation or while attacking.

![Enemy formation and incoming fire](assets/Screenshots/enemyfire.png)

*Watch for enemy shots and diving attacks.*

## Lives and the second fighter

You start with three lives. Extra lives are awarded as your score increases. If Boss Galaga captures your fighter, destroying the Boss before capture is complete can release it. If capture completes, you continue with one fewer life; when the captured fighter returns, you gain a dual-fighter formation with increased firepower. A collision can cost one of the two fighters.

![Two fighters in action](assets/Screenshots/twofighters.png)

![Fighter captured](assets/Screenshots/captured.png)

## Score and entering initials

If your final score qualifies for the Top 5, enter three initials:

- Left / down: previous letter.
- Right / up: next letter.
- `Space` or Fire 1: confirm the letter and move to the next position.

The Top 5 scores are saved to the disk and remain available after restarting. Keep the game disk in the drive while entering initials. If saving fails, the game displays a warning.

![Entering initials](assets/Screenshots/enteringname.png)

![Bonus-stage results](assets/Screenshots/bonushits.png)

## On-screen information

- **1UP:** your current game score.
- **HIGH SCORE:** the highest saved score.
- **Ships along the bottom:** remaining lives.
- **Stage badges:** badges valued at 1, 5, 10, 20, 30, and 50 combine to show the current stage. For example, stage 4 shows four 1-point badges, stage 5 shows one 5-point badge, and stage 6 shows one 5-point badge plus one 1-point badge.

## Tips

- Move horizontally and keep firing, while watching the position of enemy shots.
- In bonus stages, focus on hitting as many targets as possible.
- From stage 40 onward, account for the sideways movement of enemy fire.
- Press `H` to pause whenever needed.
