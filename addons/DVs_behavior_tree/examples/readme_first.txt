The examples folder provides different use cases and feature showcase of the addon.
Each scene includes a ReadMe node with a description explaining how the scene works.

Note that the examples were designed with a base resolution of 1280x720
which means changing the base resolution to something else could cause some nodes
to go offscreen or be too small/big. I couldn't take advantage of automatic resizing since
nodes are Node2D rather than Control.
Please set your base resolution (viewport_width and viewport_height in project settings) to 1280x720
while browsing examples.

This can be solved by using a combination of a Subviewport, SubviewportContainer
and AspectRatioContainer, just not sure if it's the best approach.
