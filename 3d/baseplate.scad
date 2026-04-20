// =============================================================
// US wall-box adapter plate for Guition ESP32-S3-4848S040
// -------------------------------------------------------------
// Role: translates the device's EU 60 mm mounting pattern to
//       a US single-gang old-work box OR direct drywall anchors.
//       Also provides recesses for the 8-pin header and JST
//       connectors that protrude from the device's back.
// -------------------------------------------------------------
// Material:  PETG (survives 40 C ambient). NOT PLA.
// Print:     0.2 mm layer, 30% infill, 4 perimeters, no supports
// Orientation: flat on bed, pockets face UP
// =============================================================

// ---------- VERIFY THESE WITH CALIPERS BEFORE PRINTING ----------
// The device dimensions below are derived from the EU mount
// (which targets 60 mm screw spacing) and published device specs.
// Measure YOUR unit and adjust if they differ.

// Device outer bezel (silver frame)
dev_w              = 108;   // device width  (silver bezel outer, measured earlier)
dev_h              = 108;   // device height (silver bezel outer)

// Device mounting holes (on the 4 corner ears, EU 60 mm pattern)
dev_hole_spacing_x = 60;    // horizontal center-to-center (EU standard)
dev_hole_spacing_y = 60;    // vertical  center-to-center (EU standard)
dev_hole_d         = 3.8;   // through-hole for M3.5 or #6 screws

// ---------- US SINGLE-GANG BOX PATTERN ----------
// Standard US device-screw spacing: 3.281" = 83.3 mm vertical
box_hole_spacing_y = 83.3;
box_hole_d         = 3.8;   // #6-32 fits; widen to 4.2 for slack

// ---------- PLATE OUTLINE ----------
// Sized to slightly overhang a standard US single-gang opening
// (~70 x 115 mm) and fully cover the device footprint.
plate_w            = 120;
plate_h            = 140;
plate_t            = 4;
corner_r           = 4;

// ---------- DRYWALL-ANCHOR KEYHOLES (optional, for no-box installs) ----------
// Set use_keyholes = false if installing into a wall box.
use_keyholes       = true;
keyhole_head_d     = 9.0;   // #8 screw head + clearance
keyhole_shank_d    = 4.5;
keyhole_slide      = 8;
keyhole_inset_x    = 8;
keyhole_inset_y    = 8;

// ---------- CONNECTOR POCKETS (device-facing side) ----------
// The device's back has an 8-pin header and three JSTs that
// protrude ~8 mm. The plate has pockets so the device sits flush.
header_w           = 20;
header_h           = 10;
header_depth       = 9;
header_offset_y    = 25;    // +Y from plate center (top area)

jst_w              = 10;
jst_h              = 6;
jst_depth          = 6;
// Three JSTs: top-left, top-right, bottom-left (approx from photo)
jst_positions = [
    [-30,  28],
    [ 30,  28],
    [-18, -28],
];

// ---------- CABLE NOTCH (aligns with device's oval slot) ----------
cable_notch_w      = 22;
cable_notch_h      = 10;
cable_notch_y      = -40;   // toward bottom edge

$fn = 64;

// ---------- MODULES ----------

module rounded_rect(w, h, r) {
    hull() for (x=[-1,1], y=[-1,1])
        translate([x*(w/2-r), y*(h/2-r)]) circle(r=r);
}

module keyhole_2d(head_d, shank_d, slide) {
    union() {
        circle(d = head_d);
        translate([0, -slide]) circle(d = shank_d);
        translate([-shank_d/2, -slide]) square([shank_d, slide]);
    }
}

// ---------- BUILD ----------

difference() {
    // Main plate
    linear_extrude(plate_t) rounded_rect(plate_w, plate_h, corner_r);

    // Device mounting holes (60 x 60 mm pattern, through the plate)
    for (sx=[-1,1], sy=[-1,1])
        translate([sx*dev_hole_spacing_x/2, sy*dev_hole_spacing_y/2, -0.1])
            cylinder(h = plate_t + 0.2, d = dev_hole_d);

    // US single-gang box screws (2 holes, 83.3 mm vertical, on Y axis)
    for (sy=[-1,1])
        translate([0, sy*box_hole_spacing_y/2, -0.1])
            cylinder(h = plate_t + 0.2, d = box_hole_d);

    // Drywall keyholes (4 corners, optional)
    if (use_keyholes) {
        for (sx=[-1,1], sy=[-1,1])
            translate([sx*(plate_w/2 - keyhole_inset_x),
                       sy*(plate_h/2 - keyhole_inset_y),
                       -0.1])
                linear_extrude(plate_t + 0.2)
                    keyhole_2d(keyhole_head_d, keyhole_shank_d, keyhole_slide);
    }

    // 8-pin header pocket (top of device area)
    translate([0, header_offset_y, plate_t - header_depth])
        linear_extrude(header_depth + 0.1)
            square([header_w, header_h], center = true);

    // JST connector pockets
    for (p = jst_positions)
        translate([p[0], p[1], plate_t - jst_depth])
            linear_extrude(jst_depth + 0.1)
                square([jst_w, jst_h], center = true);

    // Cable notch at the bottom, open to the edge
    translate([0, cable_notch_y, -0.1])
        linear_extrude(plate_t + 0.2)
            square([cable_notch_w, cable_notch_h + 20], center = true);
}
