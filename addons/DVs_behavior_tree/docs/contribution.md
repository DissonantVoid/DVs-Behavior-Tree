# Contribution
Any help is welcome and appreciated. You can check the [roadmap](roadmap.md) for ideas.\
For pull requests please open an issue first to discuss your feature unless it's a simple bug fix or correction.

## Contribution Guidelines
- Avoid asserting or crashing, prefer pushing errors/warnings in the editor and working around user error at run-time.
- Color palette used: `#af9dd9` for primary color, `#4a4563` for secondary. Other colors can be added as needed.
- If a function of a base class is intended to be overridden by derived classes, place a "# override" comment above it.

### Style Guide
For coding I use a slightly modified version of the [Godot official style](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html#doc-gdscript-styleguide). Don't worry about it too much I can always do a sweep after the PR is merged but here are the main points:
- Static typing is a must.
- Private variables/functions start with _.
- && and || instead of `and` and `or`.
- Constants are not capitalized.

# Project Structure
`docs` is where the documentation files are stored.\
`icons` is for node icons while `icons/debugger` is for debugger icons.

`behavior_tree` includes all behavior nodes.

`debug` includes the debugger UI and functionality. `debug/components` includes UI nodes that are instantiated multiple times.

One of the most important aspects of this addon is the messaging pipeline between the running game and the editor debugger, through it information about nodes is sent from the game to be visualized in the debugger and requests from the debugger are sent to the game when needed.\
The main classes on the editor side are:
- `debugger_plugin.gd` handles communication between the game and the editor on the editor side.
- `debugger_ui.gd` handles the debugger UI in the editor and receives information about the game from `debugger_plugin.gd`.
- `components/graph_node.gd` is the visual representation of a single behavior node and receives info about the correlating node by `debugger_plugin.gd`.

The main class on the game side is:
- `debugger_listener_autoload.gd` is an autoload that handles communication between the game and the editor on the game side (see `BTDebuggerListener.send_message` and `BTDebuggerListener._on_debugger_message_received`).

Here's a visualization of the communication pipeline:

<img src="https://imgur.com/fSePdBC.png" width="500"/>

# Icons
There isn't much to help with at the moment unless new nodes are added or you have a better idea for an existing icon.\
Please make sure that the icon is placed in `icons` for behavior nodes or `icons/debugger` for debugger icons, for nodes make sure the icon name matches the file name of the node that will use it (ex: action.svg for the icon used by action.gd).\
Make sure that the icon typs is .svg and size is 32x32 pixels and use the color palette mentioned above.\
In the import settings in Godot set both `scale with editor` and `convert colors with editor theme` to true.\
And finally to make sure svg files are smaller and don't include unnecessary data run the optimization script found in `scripts/optimize_svgs.bat` which should automatically scan the icons folder and optimize icons using [svgcleaner](https://docs.godotengine.org/en/4.2/contributing/development/editor/creating_icons.html#icon-optimization) which is an open source utility that can be downloaded [here](https://github.com/RazrFalcon/svgcleaner/releases). If you can't be bothered with the optimization step or can't run the .bat script on linux, I'll do it for you.

# Docs
I try my best to keep the docs simple and easy to understand, but I'm not a native English speaker nor a good writer, any help with spelling or writing is very much appreciated.\
When updating node references in [using addon](./(2)%20using%20addon.md) use the same node description as the one in the node script.