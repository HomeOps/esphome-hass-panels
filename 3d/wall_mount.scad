// =============================================================
// Slide-in wall mount for Guition ESP32-S3-4848S040
// -------------------------------------------------------------
// Strategy:
//   Reuse the engagement geometry from the Upright desk stand
//   (the ~50 mm crossbar that slides into the device's holding
//   tabs at the top of its back), but replace the desk foot
//   with a wall-mount plate.
//
//   The STL lives at ./Upright+Stand.stl  -- adjust path below
//   if you've moved it. OpenSCAD imports binary STLs directly.
//
// Material:  PETG (survives 40 C). NOT PLA.
// Print:     0.2 mm layer, 30% infill, 4 perimeters
// Orientation: lay the wall plate flat on the bed, arm pointing up
// =============================================================

// ---------- PATH TO SOURCE STL ----------
// Either put the STL alongside this .scad file, or set an absolute
// path. OpenSCAD needs the file at render time (F6).
stl_path = "C:/Users/oscar/Downloads/Upright+Stand.stl";

// ---------- WALL PLATE DIMENSIONS ----------
plate_w            = 120;   // plate width (X)
plate_h            = 140;   // plate height (Z in final orientation)
plate_t            = 4;     // plate thickness (Y in final orientation)
corner_r           = 4;

// ---------- STAND GRAFT REGION ----------
// Keep everything in the source STL at or above this Z value.
// Z=8 is just above the foot; Z=12 discards the foot entirely
// and keeps the rising arm + top crossbar.
graft_z_min        = 12;

// Source stand dimensions (from STL analysis):
//   Foot:      Z = 0..8,   86 x 86 mm
//   Rising arm: Z = 13..46 (varies, narrows to ~8 mm wide)
//   Top crossbar: Z = 48..50, 50 x 3 mm (the engagement)
src_foot_z         = 8;     // where the foot ends
src_top_z          = 51.06; // total stand height
src_back_y         = 43;    // stand's flat back is at Y = -43

// Amount of the stand above the foot we want to graft (mm)
graft_height       = src_top_z - graft_z_min;   // ~39 mm

// ---------- US SINGLE-GANG BOX HOLES (optional) ----------
// Standard US device-screw spacing: 83.3 mm vertical, centered
box_hole_spacing   = 83.3;
box_hole_d         = 4.2;   // clearance for #6-32
use_box_holes      = true;

// ---------- DRYWALL KEYHOLES (optional) ----------
use_keyholes       = true;
keyhole_head_d     = 9.0;
keyhole_shank_d    = 4.5;
keyhole_slide      = 8;
keyhole_inset_x    = 10;
keyhole_inset_z    = 10;

$fn = 64;

// ---------- MODULES ----------

module rounded_plate() {
    // Plate lies in the XZ plane, thickness along Y
    translate([0, -plate_t/2, 0])
        rotate([90, 0, 0])
            linear_extrude(plate_t, center = true)
                offset(r = corner_r)
                    square([plate_w - 2*corner_r, plate_h - 2*corner_r],
                           center = true);
}

module keyhole_cut() {
    // Centered on origin in XZ plane, head above, shank below
    rotate([90, 0, 0]) linear_extrude(plate_t + 2, center = true) union() {
        circle(d = keyhole_head_d);
        translate([0, -keyhole_slide]) circle(d = keyhole_shank_d);
        translate([-keyhole_shank_d/2, -keyhole_slide])
            square([keyhole_shank_d, keyhole_slide]);
    }
}

// Crops the source stand to keep only Z >= graft_z_min, then
// translates so the cropped cut-plane sits on the wall plate.
module stand_graft() {
    // Translate the stand so its flat back face (originally at
    // Y = -src_back_y = -43) aligns with Y = 0 (plate's front face),
    // and its graft cut plane (originally Z = graft_z_min = 12)
    // aligns with Z = 0 (plate's vertical center).
    translate([0, 0, -graft_z_min])
        translate([0, src_back_y, 0])
            intersection() {
                import(stl_path);
                translate([-200, -200, graft_z_min])
                    cube([400, 400, 200]);
            }
}

// ---------- BUILD ----------

difference() {
    union() {
        rounded_plate();
        stand_graft();
    }

    // US single-gang box screws (two holes on vertical centerline)
    if (use_box_holes) {
        for (sz = [-1, 1])
            translate([0, 0, sz * box_hole_spacing / 2])
                rotate([-90, 0, 0])
                    cylinder(h = plate_t + 2, d = box_hole_d, center = true);
    }

    // Drywall keyholes at the 4 corners
    if (use_keyholes) {
        for (sx = [-1, 1], sz = [-1, 1])
            translate([sx * (plate_w/2 - keyhole_inset_x),
                       0,
                       sz * (plate_h/2 - keyhole_inset_z)])
                keyhole_cut();
    }
}
