# Mystery Forest: The Lost Crystal (Expanded Adventure Edition)

A 3D low-poly fantasy adventure game built with **Godot 4** and **GDScript**.

## 🌲 Forest & Environmental Detail

Explore a 120m × 120m fantasy forest enclosed by mountains:
- **Diverse Trees (65+ trees)**: Mountain Conifers with multi-tiered needle canopies, gnarly broadleaf Oaks with fluffy foliage in varied green tones, and silver-barked Birch trees.
- **Fallen Logs & Mossy Stumps (16 features)**: Weathered logs and mossy tree stumps along trails and clearings.
- **Undergrowth Detail**: Over 36 grass & fern tuft clusters, 24 shrubs/bushes, 16 colorful wild flower patches, and 14 forest mushrooms.
- **Varied Rock Formations (16 boulders)**: Granite stones and stepping stone pathways.
- **Encircled Mountain Range**: 8 mountain peaks encircling the valley skyline.

---

## 🔮 The 3 Magical Crystals & Sky Beacons

Each crystal casts a luminous **Vertical Sky Beacon Beam** high into the heavens, allowing you to spot and navigate to them from anywhere in the forest:

1. **The Luminous Amethyst Crystal (Violet Beacon)**
   - Location: **The Ancient Druid Shrine** (North-West, ~`[-34, -25]`)
   - Resting upon an ancient stone altar encircled by 8 megalithic pillars.

2. **The Celestial Sapphire Crystal (Cyan Beacon)**
   - Location: **The Bioluminescent Giant Mushroom Grove** (South-East, ~`[32, 26]`)
   - Hovering in a mossy clearing surrounded by giant glowing fantasy mushrooms.

3. **The Radiant Sunstone Crystal (Golden Amber Beacon)**
   - Location: **The Highland Stone Arch & Overlook** (North-East, ~`[28, -32]`)
   - Positioned atop stone steps beneath a natural megalithic archway.

---

## 🧭 The Humanoid Adventurer Character

- **Clothing & Gear**: Emerald explorer tunic, dark leather belt with brass buckle, adventure side pouch, crimson explorer scarf, and travel rucksack with rolled bedroll.
- **Facial Features & Hat**: Explorer's wide-brimmed hat with golden ribbon band, styled hair, and expressive face.
- **Ground Alignment**: Sturdy leather boots resting flush with the terrain at `Y = 0.0`.
- **Procedural Humanoid Animation**:
  - **Walking**: Natural arm swinging, synchronized leg strides, and subtle vertical footsteps bounce.
  - **Running (Sprinting)**: Athletic wide-arm pumps, longer strides, and forward torso lean.
  - **Jumping**: Legs tuck and arms reach up for balance in mid-air.
  - **Idle**: Gentle chest breathing motion when standing still.

---

## 🎥 Camera Improvements

- **Tree Collision Prevention**: Camera `SpringArm3D` uses dedicated collision masking (`collision_mask = 2`) so it smoothly navigates the forest canopy without jumping or snapping when near tree trunks or branches.
- **Smooth Follow & Framing**: Framed at `5.2m` distance and `1.55m` height with position lerp interpolation for responsive, jitter-free exploration.

---

## 🎮 Controls

| Action | Key / Input | Notes |
|---|---|---|
| **Move** | `W`, `A`, `S`, `D` | Character moves relative to current camera angle |
| **Look / Orbit Camera** | Mouse Movement | Full 360° horizontal orbit with vertical pitch limits |
| **Sprint** | Hold `Left Shift` | Increases speed with athletic running strides and lean |
| **Jump** | `Spacebar` | Smooth jump physics when standing on terrain |
| **Pause Menu** | `Escape` | Pauses physics and frees mouse cursor |

---

## 🚀 How to Run the Game

1. Launch Godot (`D:\games\Godot_v4.7.2-stable_win64.exe`).
2. Open or re-import the project at `D:\games\MysteryForest\project.godot`.
3. Press **F5** (or click the **Play ▶** button).
4. Click **PLAY** on the Main Menu, follow the glowing sky beams, and collect all three crystals!
