// SPDX-FileCopyrightText: 2026 Thuan Phat <laithuanphat@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later
.pragma library

// Dot animations offered in the settings page, in display order.
// `id` is what gets stored in the config and read by Dot.qml.
const MODES = [
    { id: "stretch", name: "Stretch", description: "Stretches into a pill towards the new desktop, then snaps back" },
    { id: "fluid",   name: "Fluid",   description: "Flows over like a drop of liquid, stretching with speed and keeping its momentum when you switch quickly" },
    { id: "glide",   name: "Glide",   description: "Slides smoothly to the new desktop" },
    { id: "bridge",  name: "Bridge",  description: "Spans both desktops for a moment, then draws in onto the new one" },
    { id: "blur",    name: "Blur",    description: "Smears like a motion blur while moving, sharp again when it stops" },
    { id: "streak",  name: "Streak",  description: "Streaks across, leaving a light trail that fades behind it" },
    { id: "zip",     name: "Zip",     description: "Zips across as a fine line and snaps back into a dot" },
    { id: "comet",   name: "Comet",   description: "Glides over, leaving a fading trail behind it" },
    { id: "glow",    name: "Glow",    description: "Glides over inside a soft glow that fades as it lands" },
    { id: "ripple",  name: "Ripple",  description: "Glides over, and a ring ripples out where it lands" },
    { id: "lift",    name: "Lift",    description: "Picked up, carried over, and set down on the new desktop" },
    { id: "roll",    name: "Roll",    description: "Rolls along the row like a ball" },
    { id: "elastic", name: "Elastic", description: "Tethered to the old desktop by a band that stretches, then snaps back" },
    { id: "slingshot", name: "Slingshot", description: "Draws back from the new desktop, shoots over, and settles after a slight overshoot" },
    { id: "hop",     name: "Hop",     description: "Jumps over in a little arc and squashes on landing" },
    { id: "jelly",   name: "Jelly",   description: "Squashes and stretches like jelly, wobbling as it settles" },
    { id: "spring",  name: "Spring",  description: "Slides over and wobbles into place like a spring" },
    { id: "bounce",  name: "Bounce",  description: "Slides over and overshoots a little" },
    { id: "snap",    name: "Snap",    description: "Drawn in faster and faster, hits the new desktop with a squash and springs back to round" },
    { id: "drop",    name: "Drop",    description: "Falls away from the old desktop while a new dot drops onto the new one" },
    { id: "flip",    name: "Flip",    description: "Turns over like a coin, from the old desktop to the new" },
    { id: "sparks",  name: "Sparks",  description: "Bursts into sparks that fly across, each on its own arc, and gather into a new dot" },
    { id: "pop",     name: "Pop",     description: "Shrinks away and pops up at the new desktop" },
    { id: "fade",    name: "Fade",    description: "Cross-fades from the old desktop to the new one" },
    { id: "none",    name: "None",    description: "Jumps instantly" },
];
