added chain/repeater command_block for Mineclonia

The mod makes the command block support relative coordinates (~ ~ ~), adds repeater and chain modes, always active and needs redstone like classic "Mincecraft", also includes how commands are executed from the player (as if using the execute at @p command), which is the normal way in Mineclonia, and also a mode from the command block.

You can toggle the executor from player/command_block directly from the block GUI.

Testing the mode player/command_block
if you are in player mode and execute the command setblock ~ ~1 ~ mcl_core:dirt, the block will be placed above the player (head position)

If you are in command_block mode (server) and execute the command setblock ~ ~1 ~ mcl_core:dirt, the block will be placed on top of the command block (normal Minecraft behavior)


note:chain command block is under development,feel free to contribute


Feel free to open a Pull Request.


Author : wrxxnch (github.com/wrxxnch)

