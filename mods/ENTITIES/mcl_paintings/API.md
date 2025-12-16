# mcl_paintings

To register a painting use the function `mcl_paintings.register_painting(name, def)`

`name` is a unique string identifier

Meanwhile `def` is a table with these fields:

- `width` - How wide is the painting
- `height` - how high is the painting
- `texture` - name of the texture
- `legacy_motive` - together with `width` and `height` these are used to convert legacy paintings to the new implementation.
If you're a modder, just ignore this

For an example of usage you can check the `registrations.lua` file in this directory
