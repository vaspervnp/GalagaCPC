# Galaga (1981) Amstrad CPC Clone - Development Plan

## 1. Project Overview
This document outlines the plan for developing a clone of the 1981 arcade classic **Galaga** for the Amstrad CPC using Z80 Assembly. We will utilize the modern CPC development toolchain (`rasm`, `convimgcpc`, and `diskimagemanager`) along with Aseprite/Blender for asset creation.

## 2. Game Analysis (Galaga 1981)
To create a faithful clone, we must understand the core mechanics that made the original game so iconic:

### Core Mechanics
*   **Genre:** Fixed-screen vertical shooter.
*   **Player Control:** The player controls a starfighter that only moves left and right at the bottom of the screen.
*   **Firing:** You can fire missiles upward, but there is a strict limit of **two missiles on-screen** at a time (or four with the Dual Fighter). This requires precise aiming.
*   **The Capture Mechanic (Signature Feature):** The "Boss Galaga" enemy can emit a tractor beam. If the player's ship is caught, it becomes captured and sits at the top of the screen. The player spawns a new ship (if they have lives remaining). If the player shoots the specific Boss Galaga that captured their ship *while it is attacking*, the captured ship is rescued and docks next to the player's current ship, forming the **Dual Fighter**. This doubles firepower but also doubles the hitbox.

### Enemies and Patterns
*   **Zako (Bee):** Basic enemy, flies in standard patterns and dive-bombs.
*   **Goei (Butterfly):** Slightly tougher, acts as escorts or attackers.
*   **Boss Galaga:** Takes two hits to destroy. Emits the tractor beam.
*   **Entrance Phase:** Enemies do not spawn in a block. They fly in from the top and sides of the screen in intricate, choreographed, sweeping patterns before settling into their formation at the top.
*   **Attack Phase:** Enemies break formation to dive-bomb the player, occasionally looping around before returning to formation.

### Stages and Progression
*   **Endless Gameplay:** Difficulty scales as stages progress (faster patterns, more aggressive dive-bombing).
*   **Challenging Stages:** Every few levels, enemies fly in complex sequences without firing. Destroying all 40 yields a massive point bonus.

## 3. Amstrad CPC Technical Considerations
*   **Graphics Mode:** **Mode 0** (160x200 resolution, 16 colors out of 27) is highly recommended. While the pixels are wide, Galaga relies heavily on its colorful, distinct sprites against a black background. Mode 1 (4 colors) would be too restrictive for the vibrant look of Galaga.
*   **Memory:** Standard 64K (CPC 464) is plenty for a game of this scope, but managing sprite data in RAM will require care.
*   **Sprite Drawing:** We will need optimized sprite drawing routines (software sprites, as CPC has no hardware sprites) masking out the background.
*   **Timing:** Using the CPC's VSYNC (1/50th of a second) to sync the game loop for smooth movement.

## 4. Toolchain & Asset Pipeline
*   **Graphics (Aseprite):** Draw all sprites (Ship, Dual Ship, Zako, Goei, Boss Galaga, Explosions) using the Amstrad CPC 16-color palette.
*   **Asset Conversion (`convimgcpc`):** Convert the exported PNGs from Aseprite into CPC-ready binary data (interleaved screen data or raw sprite bytes).
*   **Code Compilation (`rasm`):** The Z80 assembler will compile our source code into executable CPC binaries. `rasm` is incredibly fast and supports modern directives.
*   **Disk Image (`diskimagemanager`):** Once compiled, this tool will pack the binary files into a `.dsk` floppy disk image.
*   **Testing:** Use an emulator like **WinAPE** or **RetroVirtualMachine** to test the `.dsk` file.

## 5. Development Phases

### Phase 1: Setup and Framework
*   Set up the `rasm` build script.
*   Initialize the CPC screen (Set Mode 0, set the palette to Galaga colors).
*   Write basic VSYNC timing loops.
*   Create a simple script that automates compilation, disk image creation, and launching the emulator.

### Phase 2: Visuals & Player
*   Design the player ship in Aseprite, convert with `convimgcpc`.
*   Write a sprite rendering routine (with masking).
*   Implement player input (Keyboard/Joystick) to move left/right.
*   Implement screen boundaries.

### Phase 3: Projectiles & Collisions
*   Implement player shooting (limit 2 on screen).
*   Implement simple Axis-Aligned Bounding Box (AABB) collision detection.
*   Create a basic dummy enemy to test shooting and destroying sprites.

### Phase 4: Enemy Choreography (The Hardest Part)
*   Design Zako, Goei, and Boss Galaga sprites.
*   Implement pathing/curves. The enemies in Galaga follow pre-defined mathematical paths (like Bézier curves). We will likely need to pre-calculate these paths into lookup tables (LUTs) in assembly for performance.
*   Implement the "Formation" logic (grid positioning at the top).

### Phase 5: Advanced Mechanics
*   Implement the Boss Galaga tractor beam animation.
*   Implement the Capture sequence (taking player control away, docking the ship).
*   Implement the Rescue sequence and Dual Fighter logic.

### Phase 6: Game Loop & Polish
*   Score system, High Score, and Lives display.
*   Level progression (speeding up enemy loops).
*   Sound Effects (using the AY-3-8912 chip).
*   Challenging Stages.
