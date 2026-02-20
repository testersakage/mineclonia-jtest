# Common Mineclonia library functions

## Compatibility functions

### `mcl_util.log_deprecated_call(level)`
  Writes a luanti-style deprecation message to the log.
  When called from a function, it writes to the log the name of the function,
  stating it as a deprecated function, followed by the filename and the line
  number of the function calling the deprecated function.

#### Arguments:
  level: log level, defaults to "warning".
