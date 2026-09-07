// SPDX-FileCopyrightText: 2026 Thuan Phat <laithuanphat@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later
.pragma library

// Dot animations offered in the settings page, in display order.
// `id` is what gets stored in the config and read by Dot.qml.
const MODES = [
    { id: "stretch", name: "Stretch", description: "Stretches into a pill towards the new desktop, then snaps back" },
    { id: "glide",   name: "Glide",   description: "Slides smoothly to the new desktop" },
    { id: "lift",    name: "Lift",    description: "Picked up, carried over, and set down on the new desktop" },
    { id: "roll",    name: "Roll",    description: "Rolls along the row like a ball" },
    { id: "elastic", name: "Elastic", description: "Tethered to the old desktop by a band that stretches, then snaps back" },
    { id: "streak",  name: "Streak",  description: "Streaks across, leaving a light trail that fades behind it" },
    { id: "glow",    name: "Glow",    description: "Glides over inside a soft glow that fades as it lands" },
    { id: "comet",   name: "Comet",   description: "Glides over, leaving a fading trail behind it" },
    { id: "ripple",  name: "Ripple",  description: "Glides over, and a ring ripples out where it lands" },
    { id: "hop",     name: "Hop",     description: "Jumps over in a little arc and squashes on landing" },
    { id: "jelly",   name: "Jelly",   description: "Squashes and stretches like jelly, wobbling as it settles" },
    { id: "spring",  name: "Spring",  description: "Slides over and wobbles into place like a spring" },
    { id: "bounce",  name: "Bounce",  description: "Slides over and overshoots a little" },
    { id: "pop",     name: "Pop",     description: "Shrinks away and pops up at the new desktop" },
    { id: "fade",    name: "Fade",    description: "Cross-fades from the old desktop to the new one" },
    { id: "none",    name: "None",    description: "Jumps instantly" },
];
