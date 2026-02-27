This **isn't** the actual `minetestmapper`, just the cut out and modified
version of its base tooling, with the original available [here](https://github.com/luanti-org/minetestmapper/tree/master/util).


## Usage

### 1. Dump nodes.txt from a new Mineclonia world

1. Create it in the GUI, then locate its directory, make a subdirectory called
   `worldmods` inside of it and copy-paste `dumpnodes` from this directory
   there. In this example, the directory of the world will be referred to as
   `new_world`.
2. Enter the new world in singleplayer and type `/dumpnodes` in chat.
3. The output should read that `nodes.txt` has been generated successfully.

### 2. Run the script to generate colors.json

```bash
python3 ./generate_colorstxt.py --game ../../ --mods ../../mods/ \
    ../../../../worlds/new_world/nodes.txt
```

`python3` is whatever your Python binary is in the PATH. Note that the script
uses [Pillow (ex. PIL)](https://pypi.org/project/pillow/) for image processing
and you have to install it first with either `pip`, your system package manager,
or a virtual environment (i.e. via [pyenv](https://github.com/pyenv/pyenv)).

### 3. Place colors.json in its rightful place

That rightful place happens to be `mods/ITEMS/mcl_maps/colors.json`.

After this, all new generated maps should have colors for new nodes and updated
colors for updated textures!

