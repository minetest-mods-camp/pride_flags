# `pride_flags` API

Programmers can use the following Lua functions to add custom flags,
get a list of all flags, and set and get the flag of flag pole nodes.

## Functions

### `pride_flags.add_flag = function(name)`
Add a new flag to the game. `name` is the flag identifier.
There *must* exist a texture with the name `prideflag_<name>.png`.
The texture *should* have an aspect ratio of 1.3.
The recommended size is 78×60, but other sizes are OK
as long the aspect ratio is respected.

The flag name *must not* already exist. This will be checked.

On success, the flag will be appended to the list of flags at the end.

If a flag with the given name already exists, no flag will be
added.

Returns `true` on success and `false` on failure.

### `pride_flags.get_flags = function()`
Returns a list of all available flag identifiers. The flags
are sorted by selection order.

### `pride_flags.set_flag_at = function(pos, flag_name)`
Sets the flag at an upper mast node at position `pos` to the flag `flag_name`.
The node at `pos` *must* be `pride_flags:upper_mast`.
Returns `true` on success and `false` otherwise.

### `pride_flags.get_flag_at = function(pos)`
Returns the currently used flag at the upper mast node at position `pos`.
The node at `pos` *must* be `pride_flags:upper_mast`.
Returns a string on success and `nil` otherwise.
