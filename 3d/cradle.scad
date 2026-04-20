// =============================================================
// Wall-plate + slide-in cradle for Guition ESP32-S3-4848S040
// -------------------------------------------------------------
// Single printed part:
//   - 100 x 120 wall plate, mounts to a US single-gang box
//     via 2 screws at 83.3 mm vertical spacing (gang box at the
//     plate's vertical center; extra height is above the cradle).
//   - 93 x 93 cradle rising 13 mm forward, aligned with the BOTTOM
//     edge of the plate (plate extends upward above the cradle).
//     Cavity 88 x 88 x 13. Front has a 4-sided 5 mm retention frame
//     (bottom + top bars, left/right posts) that drops into the
//     device's 5 mm front notch. Device installs by tilting it in
//     from the front.
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
plate_h        = 120;
plate_t        = 5;

// ---------- CRADLE ----------
cradle_outer_w = 93;
cradle_outer_h = 93;
cradle_depth   = 13;
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

// ---------- 8-PIN CONNECTOR SLIDE-IN CHANNEL ----------
// Vertical groove on the cradle-facing side of the wall plate so the
// device's 3 mm-raised 8-pin header can slide down from the top into
// its seated position. Runs from above the wire hole up through the
// top edge of the plate. Adjust conn_chan_x to match the connector.
conn_chan_w      = 25;   // X width of the channel
conn_chan_depth  = 3;    // Y recess into plate (matches header height)
conn_chan_x      = 30;   // X center (upper-RIGHT front view = X > 0)

// ---------- BOTTOM SLOT (USB-C + SD card) ----------
// Wide opening through the cradle's bottom lip so the USB-C port and
// microSD slot on the device's bottom edge are reachable. Cuts the full
// Y depth and full Z thickness of the lip; the device still rests on
// the remaining lip on each side of the slot.
bottom_slot_w    = 60;

$fn = 48;

// ---------- DERIVED ----------
cavity_w = device_w + clearance;
cavity_h = device_h + clearance;

// Z offset so the cradle's outer bottom aligns with the plate's
// outer bottom (instead of both being centered). For plate_h = 120
// and cradle_outer_h = 93, this is -13.5 mm.
cradle_z = -(plate_h - cradle_outer_h) / 2;

// ---------- BUILD ----------

union() {
    // Plate + hollow cradle shell, with all plate-side subtractions.
    // The retention lip is added AFTER this block so the bottom slot
    // can extend generously in Y and Z without creating coincident
    // planes with the lip.
    difference() {
        union() {
            // Wall plate
            translate([-plate_w/2, 0, -plate_h/2])
                cube([plate_w, plate_t, plate_h]);

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

        // Wire passthrough: rectangular hole through the plate
        translate([-wire_hole_w/2, -0.1, -wire_hole_h/2])
            cube([wire_hole_w, plate_t + 0.2, wire_hole_h]);

        // 8-pin connector slide-in channel (cradle-facing side, upper portion)
        translate([conn_chan_x - conn_chan_w/2,
                   plate_t - conn_chan_depth,
                   wire_hole_h/2 - 0.01])
            cube([conn_chan_w,
                  conn_chan_depth + 0.02,
                  plate_h/2 - wire_hole_h/2 + 1]);

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

        // US single-gang box screws (vertical centerline)
        for (sz = [-1, 1])
            translate([0, -0.1, sz * box_hole_spacing / 2])
                rotate([-90, 0, 0])
                    cylinder(h = plate_t + 0.2, d = box_hole_d);
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
               cradle_z - cradle_outer_h/2 + wall_bottom_t])
        cube([cavity_w, front_lip_t, front_lip_w]);           // bottom bar

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
}
