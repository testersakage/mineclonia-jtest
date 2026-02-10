# Advanced Command Blocks for Mineclonia / Minetest

This mod enhances the default Command Block system for Mineclonia, adding improved execution logic, relative coordinate parsing.

---

## ✨ Features

### ✅ Execution Modes
Command Blocks can execute commands in two different modes:

- **Player Mode** — Commands execute as the stored commander.
- **Command Block Mode** — Commands execute relative to the block position (server-side execution).

You can toggle the executor directly from the block GUI.

---

### ✅ Relative Coordinate Support (`~`)
Proper support for Minecraft-style relative coordinates:

~ ~ ~
~1 ~ ~-2


When in **Command Block Mode**, coordinates are resolved relative to the block position.

Axis resolution is handled safely per command to prevent desync issues.


---

### ✅ Block Types

- **Impulse**
- **Repeating**
- **Chain** *(⚠ Currently in development)*

Chain blocks work but are still being refined for edge cases and execution timing.

---

## ⚠ Chain Block Status

Chain logic is still under development.

Known considerations:
- Edge-case execution order
- Redstone timing synchronization
- Advanced conditional propagation

Contributions and improvements are welcome.

---

## 🔧 Requirements

- Mineclonia
- mcl_redstone
- Creative mode + `maphack` privilege to edit blocks

---

## 🛠 Technical Overview

- Safe redstone power detection (`pcall` protected)
- Server-side coordinate parsing
- Controlled timer execution
---

## 🤝 Contributing

Help is very welcome.

If you want to improve:
- Chain execution logic
- Performance
- Edge case handling
- Compatibility with additional commands
- Security improvements

Feel free to open a Pull Request.


Author : wrxxnch (github.com/wrxxnch)

