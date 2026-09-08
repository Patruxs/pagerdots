// SPDX-FileCopyrightText: 2026 Thuan Phat <laithuanphat@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later
.pragma library

// Base duration of the dot animations in ms: Plasma's own (`base`, usually
// Kirigami.Units.longDuration) scaled by the speed setting, a percentage, so 50
// plays at half speed and 200 at double.
function unitFor(base, speedPercent) {
    return Math.round(base * 100 / Math.max(25, speedPercent));
}

// Dot animations offered in the settings page, in display order.
// `id` is what gets stored in the config and read by Dot.qml.
// Each one has a silhouette of its own at panel size; variants that only differ in
// how they are drawn or eased look identical on a dot a few pixels across.
const MODES = [
    { id: "stretch", name: "Stretch", description: "Stretches into a pill towards the new desktop, then snaps back" },
    { id: "glide",   name: "Glide",   description: "Slides smoothly to the new desktop" },
    { id: "elastic", name: "Elastic", description: "Tethered to the old desktop by a band that stretches, then snaps back" },
    { id: "spring",  name: "Spring",  description: "Slides over and wobbles into place like a spring" },
    { id: "hop",     name: "Hop",     description: "Jumps over in a little arc and squashes on landing" },
    { id: "swing",   name: "Swing",   description: "Swings over in a smooth arc, like a pendulum" },
    { id: "lift",    name: "Lift",    description: "Picked up, carried over, and set down on the new desktop" },
    { id: "glow",    name: "Glow",    description: "Glides over inside a soft glow that fades as it lands" },
    { id: "ripple",  name: "Ripple",  description: "Glides over, and a ring ripples out where it lands" },
    { id: "footprints", name: "Footprints", description: "Glides over, leaving a fading footprint on each desktop it passes" },
    { id: "ring",    name: "Ring",    description: "Opens out into a ring that fades from the old desktop, while a ring closes in and fills to a dot on the new one" },
    { id: "sparks",  name: "Sparks",  description: "Bursts into sparks that fly across, each on its own arc, and gather into a new dot" },
    { id: "pour",    name: "Pour",    description: "Drains from the old desktop into the new one down a thin stream, shrinking on one as it grows on the other" },
    { id: "drop",    name: "Drop",    description: "Falls away from the old desktop while a new dot drops onto the new one" },
    { id: "pop",     name: "Pop",     description: "Shrinks away and pops up at the new desktop" },
    { id: "fade",    name: "Fade",    description: "Cross-fades from the old desktop to the new one" },
    { id: "beam",    name: "Beam",    description: "Stretches into a tall thin beam that fades from the old desktop, while a beam appears on the new one and collapses into a dot" },
    { id: "split",   name: "Split",   description: "Splits into two half dots that swing out to either side, cross over, and merge again on the new desktop" },
    { id: "flash",   name: "Flash",   description: "Appears on the new desktop at once and blinks twice" },
    { id: "wrap",    name: "Wrap",    description: "Leaves past the end of the row and comes back in from the other end, the long way round" },
    { id: "steps",   name: "Steps",   description: "Jumps over in a few discrete stops, stop-motion style" },
    { id: "boomerang", name: "Boomerang", description: "Draws back a whole desktop away, then flies across and lands" },
    { id: "topple",  name: "Topple",  description: "Stands up into a post that topples over like a domino onto the new desktop, then fades away to leave the dot there" },
    { id: "cartwheel", name: "Cartwheel", description: "Flattens into a short bar that turns end over end as it crosses, and rounds off into a dot again" },
    { id: "arrow",   name: "Arrow",   description: "Sharpens into an arrowhead that shoots over to the new desktop and rounds off into a dot again" },
    { id: "train",   name: "Train",   description: "Breaks into a file of three beads that run across in line and merge again on the new desktop" },
    { id: "twinkle", name: "Twinkle", description: "Collapses into a spinning four-point star that shrinks away on the old desktop, while a star flares up on the new one and rounds off into a dot" },
    { id: "hoop",    name: "Hoop",    description: "Opens out into a hollow hoop, larger than itself, that rolls across to the new desktop and closes back into a dot" },
    { id: "billiards", name: "Billiards", description: "Slides across at a steady pace and stops dead on the new desktop, knocking a second dot out ahead of it that flies on and fades" },
    { id: "recoil",  name: "Recoil",  description: "Pops up on the new desktop at once, kicking the old dot back the other way, where it fades" },
    { id: "loop",    name: "Loop",    description: "Loops the loop on the way over: forward and up over the top, back underneath, and on to the new desktop" },
    { id: "volley",  name: "Volley",  description: "Flies over, is batted straight back to the old desktop, and flies over again to stay" },
    { id: "flip",    name: "Flip",    description: "Slides across while flipping over like a coin, thinning to a sliver edge on and back" },
    { id: "burst",   name: "Burst",   description: "Bursts into pieces that fly out all round and fade on the old desktop, while pieces fly in from all round the new one and gather into a dot" },
    { id: "none",    name: "None",    description: "Jumps instantly" },
];

// The id of a known animation, or the default one for an id that is not offered any
// more (a setting saved by an older version). An empty id is left alone: the settings
// page has one until Plasma hands it the config.
function normalize(id) {
    if (id === "" || MODES.some(m => m.id === id)) return id;
    return "stretch";
}
