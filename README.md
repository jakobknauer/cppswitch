# Intro

`cppswitch` is a Neovim plugin for switching between a C++ (or C) header file and the corresponding implementation file,
or creating the corresponding file if it doesn't exist.

It is able to handle both situations where header and implementation are located in the same directory,
and where they are in separate "src" and "include" (names configurable) directories, called "twin directories" in what follows.


# Setup

1. Install the plugin, e.g. using vim-plug:

```lua
local Plug = vim.fn["plug#"]
vim.call("plug#begin")
Plug "jakobknauer/cppswitch"
vim.call("plug#end")
```

2. Setup

```lua
require("cppswitch").setup()
```

3. Configure

Adapt some global variables to modify the behavior of the plugin.
The following are the default values - if you're happy with them, skip this step.
See below for details on the behavior, and how the 'twin directory' mechanic works.

```lua
-- File extensions that indicate header files
vim.g.cppswitch_header_extensions = {"h", "hpp", "hh", "h++", "hxx", "H"}
-- File extensions that indicate implementation files
vim.g.cppswitch_impl_extensions = {"c", "cpp", "cc", "c++", "cxx", "C"}

-- The file extension to use for creating a header file, when none exists
vim.g.cppswitch_preferred_header_extension = "h"
-- The file extension to use for creating an implementation file, when none exists
vim.g.cppswitch_preferred_impl_extension = "cpp"

-- In which directories to search for the corresponding header/implementation file, and in which order.
-- List, allowed items: "same" and "twin"
vim.g.cppswitch_search_dirs = {"same", "twin"}

-- In which directory to create a header/implementation file, if it doesn't exist.
-- Possible values: "same" or "twin"
vim.g.cppswitch_creation_dir = "same"

-- For determining the 'twin directories'
vim.g.cppswitch_header_dir = "include"
vim.g.cppswitch_impl_dir = "src"
```

4. Create keymaps for using the plugin - adapt to your liking

```lua
vim.keymap.set("n", "<leader>S", "<cmd>CppswitchSwitch<CR>")
vim.keymap.set("n", "<leader>h", "<cmd>CppswitchGotoHeader<CR>")
vim.keymap.set("n", "<leader>c", "<cmd>CppswitchGotoImpl<CR>")
```

5. When in an implementation file, use `<leader>h` (or whichever keymap you configured) to switch to the corresponding header file, and use `<leader>c` for the opposite direction.
Or simply use `<leader>S` for letting the plugin detect in which type of file you currently are, and switch to the other one.

# Behavior

## `CppswitchGotoHeader` & `CppswitchGotoImpl`

The commands `CppswitchGotoHeader` and `CppswitchGotoImpl` behave the same, but with roles of header and implementation files reversed.
In this section, we will thus only explain the behavior of `CppswitchGotoHeader`.

`CppswitchGotoHeader` is intended to switch from a C++ implementation file to the corresponding header file. In the following, suppose that the current file is called "util.cpp". In fact, the file extension of the current file is irrelevant for what follows, only its location and the part of the name before the extension ("util" in this case) play a role.

### Search

The command first searches if a suitable header file already exists. If this is not the case, the header file is newly created.

The search for the header file is first of all influenced by the variable `cppswitch_search_dirs`.

- If this list contains the item "same" then the header file will be searched for in the directory in which "util.cpp" is located. 

- If this list contains the item "twin" then the header file will be searched for in "twin directory" of the directory in which "util.cpp" is located.
The twin directory is obtained by going up the directory hierarchy until a directory called "src" is reached,
and replacing that by "include".
For example, the twin directory of `/my/project/src/helpers/` would be `/my/project/include/helpers/`.
If there is no parent directory called "src", or the twin directory does not exist, the twin directory is not used for the search.

__Note:__ The directory names "src" and "include" are merely the defaults used by the plugin, but they can be configured using the variables `cppswitch_impl_dir` and `cppswitch_header_dir`.

If `cppswitch_search_dirs` contains both "twin" and "same", then both directories are used for searching the header file, in the order they appear in the list.

In the specified search directories, the plugin then searches for a file called "util.?", where "?" is replaced by all extensions listed in `cppswitch_header_extensions`, in the same order.
The first file of that kind that actually exists is loaded.

For example, if we have

- `cppswitch_search_dirs = {"twin", "same"}`, 
- `cppswitch_header_extensions = {"hpp", "h"}`, 
- `cppswtich_impl_dir` and `cppswitch_header_dir` are the defaults, 
- and "util.cpp" is located in `/my/project/src/helpers/`,

then the following files are checked in that order:

- `/my/project/include/helpers/util.hpp`
- `/my/project/include/helpers/util.h`
- `/my/project/src/helpers/util.hpp`
- `/my/project/src/helpers/util.h`

### Creation

If the search is not successful and no matching header file is found, the header file is created instead.
The directory in which the header file is created is controlled by the variable `cppswitch_creation_dir` (which may be "same" or "twin"),
and the file extension is determined by the variable `cppswitch_preferred_header_extension`.
For example, in the scenario from above, if
- `cppswitch_creation_dir = "twin"`,
- and `cppswitch_preferred_header_extension = "hpp"`,
then the file `/my/project/src/helpers/util.hpp` is created (including the directory, if it does not exist).


## `CppswitchSwitch`

The command `CppswitchSwitch` is basically a convenience wrapper around `CppswitchGotoHeader` and `CppswitchGotoImpl`.
It uses the variables `cppswitch_header_extensions` and `cppswitch_impl_extensions` to determine if the current buffer is a header or implementation file,
and then switches to the other one.
