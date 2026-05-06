// =============================================================
// Wall-plate + slide-in cradle for Guition ESP32-S3-4848S040
// -------------------------------------------------------------
// Single printed part:
//   - 100 x 120 wall plate, mounts to a US single-gang box
//     via 2 screws at 83.3 mm vertical spacing (gang box at the
//     plate's vertical center; extra height is above the cradle).
//   - 93 x 93 cradle rising 16 mm forward, aligned with the BOTTOM
//     edge of the plate (plate extends upward above the cradle).
//     Pocket 88 x 88 x 13 (cradle_depth = 13 mm device + 3 mm lip).
//     Front has a 4-sided 5 mm retention frame (bottom + top bars,
//     left/right posts) that drops into the device's 5 mm front
//     notch. Device installs by tilting it in from the front.
//   - 50 x 60 wire passthrough straight through the plate center.
//
// Material: PETG. 0.2 mm layer, 30% infill, 4 perimeters.
// Orient:   wall plate flat on the bed, cradle rising up.
// =============================================================

// ---------- DEVICE ----------
device_w       = 88;
device_h       = 88;
device_d       = 13;
clearance      = 0.4;

// ---------- WALL PLATE ----------
plate_w        = 100;
plate_h        = 110;    // 10 mm trimmed off the top vs original 120
plate_t        = 5;
plate_bottom_z = -60;    // Z of plate's bottom edge (fixed anchor)
plate_corner_r = 2;      // outer corner radius (capped at plate_t/2 = 2.5 by sphere-minkowski)

// ---------- CRADLE ----------
cradle_outer_w = 93;
cradle_outer_h = 93;
cradle_depth   = 16;   // device_d (13) + front_lip_t (3) — full 13 mm pocket behind the lip
wall_bottom_t  = 5;   // bottom lip the device rests on

// ---------- FRONT RETENTION LIP ----------
// The device has a 5 mm-wide notch around its entire front perimeter.
// The cradle has a matching 5 mm-wide frame on all 4 sides (bottom,
// top, left, right) that drops into that notch.
front_lip_w    = 5;   // inward projection (matches 5 mm notch width)
front_lip_t    = 3;   // Y thickness at the front face

// ---------- WIRE PASSTHROUGH (through the plate) ----------
wire_hole_w    = 80;
wire_hole_h    = 70;

// ---------- GANG-BOX SCREWS ----------
box_hole_spacing = 83.3;
box_hole_d       = 4.2;  // #6-32 clearance
// Counterbore on the device-facing surface so the screw head sits
// below Y=plate_t and doesn't impede the device. Sized for #6 pan/oval
// heads (~7.4 mm OD, ~2.5 mm tall).
csk_d            = 8;    // counterbore diameter
csk_h            = 3;    // counterbore depth (Y)

// ---------- BOTTOM SLOT (USB-C + SD card) ----------
// Wide opening through the cradle's bottom lip so the USB-C port and
// microSD slot on the device's bottom edge are reachable. Cuts the full
// Y depth and full Z thickness of the lip; the device still rests on
// the remaining lip on each side of the slot.
bottom_slot_w    = 60;

// ---------- CENTER SPINES ----------
// Uncut strips of plate material forming a cross through the wire
// passthrough: one vertical (aligned with the screw centerline), one
// horizontal. Not separate ribs — they are the portions of the plate
// the wire hole does NOT cut away. The wire passthrough is split into
// four quadrants around them.
spine_w_v        = 10;   // vertical spine width (X), narrower so the screws still anchor
spine_w_h        = 10;   // horizontal spine height (Z)

// ---------- PRESSURE RIDGE ----------
// Smooth-curve wedge on the plate's cradle-side face, centered on the
// vertical spine. Cross-section in Y-Z is a half-ellipse: chord on
// Y=plate_t, peak at the middle. Extends ridge_w along X.
// Pushes the device against the front retention frame.
ridge_w          = 10;   // X extent (matches spine width)
ridge_h          = 30;   // Z extent (chord)
ridge_r          =  1;   // Y peak (sagitta) above plate's back face
ridge_z          = -19;  // Z center (shifted 5 mm up from prior -24)

$fn = 48;

// ---------- DERIVED ----------
cavity_w = device_w + clearance;
cavity_h = device_h + clearance;

// Z offset for the cradle: bottom aligned with the plate's bottom
// edge, then lifted so the cradle sits slightly above it.
cradle_lift = 5;
cradle_z    = plate_bottom_z + cradle_outer_h/2 + cradle_lift;

// ---------- BUILD ----------

union() {
    // Plate + hollow cradle shell, with all plate-side subtractions.
    // The retention lip is added AFTER this block so the bottom slot
    // can extend generously in Y and Z without creating coincident
    // planes with the lip.
    difference() {
        union() {
            // Wall plate with all 12 edges and 8 vertices rounded.
            // Inset cube + sphere minkowski rounds every edge by
            // plate_corner_r without changing the plate's bounding box.
            minkowski() {
                translate([-plate_w/2 + plate_corner_r,
                           plate_corner_r,
                           plate_bottom_z + plate_corner_r])
                    cube([plate_w - 2*plate_corner_r,
                          plate_t - 2*plate_corner_r,
                          plate_h - 2*plate_corner_r]);
                sphere(r = plate_corner_r);
            }

            // Cradle: hollow shell (open top + open front).
            difference() {
                translate([-cradle_outer_w/2, plate_t, cradle_z - cradle_outer_h/2])
                    cube([cradle_outer_w, cradle_depth, cradle_outer_h]);

                // Full cavity: open top, open front
                translate([-cavity_w/2,
                           plate_t - 0.01,
                           cradle_z - cradle_outer_h/2 + wall_bottom_t])
                    cube([cavity_w,
                          cradle_depth + 0.02,
                          cavity_h + 20]);
            }
        }

        // Wire passthrough: split into four quadrants separated by a
        // cross of plate strips (vertical on the screw centerline,
        // horizontal at the plate vertical center).
        wire_half_w = (wire_hole_w - spine_w_v) / 2;
        wire_half_h = (wire_hole_h - spine_w_h) / 2;
        translate([-wire_hole_w/2, -0.1,  spine_w_h/2])
            cube([wire_half_w, plate_t + 0.2, wire_half_h]);  // upper-left
        translate([ spine_w_v/2,  -0.1,  spine_w_h/2])
            cube([wire_half_w, plate_t + 0.2, wire_half_h]);  // upper-right
        // Lower quadrants extend 10 mm further down than upper, so the
        // side strips of the bottom bar shrink from 25 mm to 15 mm while
        // the central column keeps its full 25 mm to anchor the lower screw.
        lower_extra_h = 10;
        translate([-wire_hole_w/2, -0.1, -wire_hole_h/2 - lower_extra_h])
            cube([wire_half_w, plate_t + 0.2, wire_half_h + lower_extra_h]);  // lower-left
        translate([ spine_w_v/2,  -0.1, -wire_hole_h/2 - lower_extra_h])
            cube([wire_half_w, plate_t + 0.2, wire_half_h + lower_extra_h]);  // lower-right

// Bottom slot (USB-C + SD card) through the cradle's bottom lip.
        // Full Y depth of the cradle; Z extends 1 mm up into the cavity
        // so there's no coincident plane with the retention lip (added
        // back as a separate solid below).
        translate([-bottom_slot_w/2,
                   plate_t - 0.01,
                   cradle_z - cradle_outer_h/2 - 0.1])
            cube([bottom_slot_w,
                  cradle_depth + 0.02,
                  wall_bottom_t + 1.1]);

        // US single-gang box screws (vertical centerline). Through-hole
        // plus counterbore on the device-facing surface so the screw
        // head sits below Y=plate_t.
        for (sz = [-1, 1])
            translate([0, -0.1, sz * box_hole_spacing / 2])
                rotate([-90, 0, 0]) {
                    cylinder(h = plate_t + 0.2, d = box_hole_d);
                    translate([0, 0, plate_t - csk_h + 0.1])
                        cylinder(h = csk_h + 0.1, d = csk_d);
                }
    }

    // Retention frame at the front face: 4-sided 5 mm-wide border that
    // drops into the device's front notch (bottom bar + top bar +
    // left/right posts). Added AFTER the plate-side subtractions so
    // the bars keep their full cross-section through the bottom slot.
    // NOTE: with the top bar in place the device can no longer slide in
    // through the top — installation requires tilting the device in
    // from the front.
    translate([-cavity_w/2,
               plate_t + cradle_depth - front_lip_t,
               cradle_z - cradle_outer_h/2])
        cube([cavity_w, front_lip_t,
              wall_bottom_t + front_lip_w]);                  // bottom bar

    translate([-cavity_w/2,
               plate_t + cradle_depth - front_lip_t,
               cradle_z + cradle_outer_h/2 - front_lip_w])
        cube([cavity_w, front_lip_t, front_lip_w]);           // top bar

    translate([-cavity_w/2,
               plate_t + cradle_depth - front_lip_t,
               cradle_z - cradle_outer_h/2 + wall_bottom_t])
        cube([front_lip_w, front_lip_t,
              cradle_outer_h - wall_bottom_t]);               // left post

    translate([cavity_w/2 - front_lip_w,
               plate_t + cradle_depth - front_lip_t,
               cradle_z - cradle_outer_h/2 + wall_bottom_t])
        cube([front_lip_w, front_lip_t,
              cradle_outer_h - wall_bottom_t]);               // right post

    // Pressure ridge: half-ellipse cross-section in Y-Z (chord ridge_h,
    // sagitta ridge_r), extruded along X. Rotation maps the polygon's
    // X→model Z and the extrusion axis (polygon Z) → model X.
    translate([0, plate_t, ridge_z])
        rotate([0, -90, 0])
            linear_extrude(height = ridge_w, center = true)
                polygon([
                    for (i = [0 : 48])
                        let (
                            u = -ridge_h/2 + ridge_h * i/48,
                            v = ridge_r * sqrt(1 - (2*u/ridge_h) * (2*u/ridge_h))
                        )
                        [u, v]
                ]);
}
