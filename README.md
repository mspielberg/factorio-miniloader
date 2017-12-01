# Miniloaders

This mod introduces miniloaders, 1x1 entities that efficiently transfer a full
belt worth of items into and out of containers, including train cargo wagons,
with minimal UPS impact.

![Miniloaders in action with cargo wagons](https://github.com/mspielberg/factorio-miniloader/raw/master/demo.gif)

They can also be used as compact priority splitters, or single-belt lane
rebalancers.

![Miniloaders in action with cargo wagons](https://github.com/mspielberg/factorio-miniloader/raw/master/tricks.gif)

Faster belts from Bob's Logistics are fully supported.

## Balancing

Miniloaders require stack inserter research, are relatively expensive to build,
and consume approximately the power of two fully-upgraded stack inserters.

## How it works

Each miniloader hides a set of very fast invisible inserters, one for each lane
of the belt.  Lua scripting adjusts pickup and drop points accordingly when the
direction of the miniloader is changed.

Since item movement is handled by inserters, there is no on_tick handler, no Lua
impact on UPS, and miniloaders will benefit from any future improvements to belt
and inserter performance made by Wube in the Factorio core.

## Known Issues

* Items currently held in the hand of the invisible inserters can still be seen,
  leading to odd graphical artifacts.
* It would be nice to have some custom graphics.
