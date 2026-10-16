const std = @import("std");
const color = @import("color.zig");
const materials = @import("materials.zig");
const Vec3 = @import("vec3.zig").Vec3;
const Light = @import("light.zig").Light;
const Shape = @import("shapes/shape.zig").Shape;
const RidgeAxis = @import("shapes/prism.zig").RidgeAxis;
const Material = @import("material.zig").Material;

// Muralla ovalada
const wall_radius_x: f32 = 14.0;
const wall_radius_z: f32 = 10.0;
const wall_segments = 36;
const wall_height: f32 = 2.5;
const wall_thickness: f32 = 0.9;

// Canal
const canal_x: f32 = 9.0;
const canal_half_width: f32 = 0.7;
const canal_half_length: f32 = 7.0;
const water_top: f32 = 0.15;

// Palacio
const palace_center = Vec3.init(-4, 0, -1.5);

const street_height: f32 = 0.02;
const lot_spacing: f32 = 1.7;
const tree_count = 22;

pub const lights = [_]Light{
    .{ .position = .init(-30, 45, -18), .color = color.fromHex("#ffe2b8"), .intensity = 1.0 },
    .{ .position = .init(30, 18, 30), .color = color.fromHex("#b8d4ff"), .intensity = 0.25 },
};

const Builder = struct {
    shapes: std.ArrayList(Shape),
    allocator: std.mem.Allocator,
    random: std.Random,

    fn add(self: *Builder, shape: Shape) !void {
        try self.shapes.append(self.allocator, shape);
    }

    fn cube(self: *Builder, center: Vec3, size: Vec3, material: *const Material) !void {
        try self.add(.{ .cube = .init(center, size, material) });
    }

    fn range(self: *Builder, min: f32, max: f32) f32 {
        return min + self.random.float(f32) * (max - min);
    }
};

pub fn build(allocator: std.mem.Allocator) ![]Shape {
    var prng = std.Random.DefaultPrng.init(24170);
    var builder = Builder{
        .shapes = .empty,
        .allocator = allocator,
        .random = prng.random(),
    };
    errdefer builder.shapes.deinit(allocator);

    try builder.cube(.init(0, -0.5, 0), .init(60, 1, 60), &materials.grass);
    try addStreets(&builder);
    try addWall(&builder);
    try addCanal(&builder);
    try addPalace(&builder);
    try addHouses(&builder);
    try addTrees(&builder);

    return builder.shapes.toOwnedSlice(allocator);
}

// Piso de adoquin en franjas que siguen el ovalo
fn addStreets(builder: *Builder) !void {
    const rows = 20;
    const row_depth = 2 * wall_radius_z / @as(f32, rows);
    for (0..rows) |i| {
        const z0 = -wall_radius_z + @as(f32, @floatFromInt(i)) * row_depth;
        const z1 = z0 + row_depth;
        const outer_z = @max(@abs(z0), @abs(z1));
        const half_width = ellipseHalfWidth(outer_z);
        if (half_width < 0.5) continue;
        try builder.cube(
            .init(0, street_height / 2, (z0 + z1) / 2),
            .init(2 * half_width, street_height, row_depth),
            &materials.cobblestone,
        );
    }
}

fn addWall(builder: *Builder) !void {
    const step = 2 * std.math.pi / @as(f32, wall_segments);
    for (0..wall_segments) |i| {
        const t0 = @as(f32, @floatFromInt(i)) * step;
        const t1 = t0 + step;
        const p0 = ellipsePoint(t0);
        const p1 = ellipsePoint(t1);
        const tangent = p1.sub(p0);
        const length = tangent.length() + 0.15;
        const angle = std.math.atan2(-tangent.z, tangent.x);
        const middle = p0.add(p1).scale(0.5);

        try builder.add(.{ .rotated_cube = .init(
            .init(middle.x, wall_height / 2, middle.z),
            .init(length, wall_height, wall_thickness),
            angle,
            &materials.sandstone,
        ) });

        // Contrafuertes hacia afuera
        if (i % 2 == 0) {
            const outward = Vec3.init(p0.x / (wall_radius_x * wall_radius_x), 0, p0.z / (wall_radius_z * wall_radius_z)).normalize();
            const base = p0.add(outward.scale(wall_thickness / 2 + 0.15));
            try builder.add(.{ .rotated_cube = .init(
                .init(base.x, (wall_height + 0.2) / 2, base.z),
                .init(0.5, wall_height + 0.2, 0.4),
                angle,
                &materials.sandstone,
            ) });
        }
    }
}

fn addCanal(builder: *Builder) !void {
    const length = 2 * canal_half_length;
    try builder.cube(
        .init(canal_x, (water_top - 0.3) / 2, 0),
        .init(2 * canal_half_width, water_top + 0.3, length),
        &materials.water,
    );

    // Bordes del canal
    for ([_]f32{ -1, 1 }) |side| {
        try builder.cube(
            .init(canal_x + side * (canal_half_width + 0.15), 0.125, 0),
            .init(0.3, 0.25, length),
            &materials.sandstone,
        );
    }

    // Puentes
    for ([_]f32{ -4, 0, 4 }) |z| {
        try builder.cube(
            .init(canal_x, 0.3, z),
            .init(2 * canal_half_width + 0.8, 0.1, 0.8),
            &materials.wood,
        );
    }
}

fn addPalace(builder: *Builder) !void {
    const c = palace_center;

    // Plaza
    try builder.cube(.init(c.x, street_height + 0.015, c.z), .init(5.5, 0.03, 4.6), &materials.marble);

    // Cuerpo principal y techo
    try builder.cube(.init(c.x, 0.85, c.z), .init(3.2, 1.6, 2.4), &materials.marble);
    try builder.add(.{ .prism = .init(.init(c.x, 1.65, c.z), 2.6, 3.4, 0.9, .x, &materials.roof_tiles) });

    // Torre central
    try builder.cube(.init(c.x, 2.3, c.z), .init(0.9, 1.3, 0.9), &materials.marble);
    try builder.add(.{ .prism = .init(.init(c.x, 2.95, c.z), 1.1, 1.1, 0.6, .z, &materials.roof_tiles) });

    // Torres de las esquinas
    for ([_]f32{ -1, 1 }) |sx| {
        for ([_]f32{ -1, 1 }) |sz| {
            const x = c.x + sx * 1.75;
            const z = c.z + sz * 1.35;
            try builder.cube(.init(x, 1.2, z), .init(0.7, 2.4, 0.7), &materials.marble);
            try builder.add(.{ .prism = .init(.init(x, 2.4, z), 0.85, 0.85, 0.5, .x, &materials.roof_tiles) });
        }
    }
}

fn addHouses(builder: *Builder) !void {
    const lots_x: i32 = @intFromFloat(wall_radius_x / lot_spacing);
    const lots_z: i32 = @intFromFloat(wall_radius_z / lot_spacing);

    var ix: i32 = -lots_x;
    while (ix <= lots_x) : (ix += 1) {
        var iz: i32 = -lots_z;
        while (iz <= lots_z) : (iz += 1) {
            const x = @as(f32, @floatFromInt(ix)) * lot_spacing + builder.range(-0.2, 0.2);
            const z = @as(f32, @floatFromInt(iz)) * lot_spacing + builder.range(-0.2, 0.2);

            // Plazas al azar
            const keep = builder.random.float(f32) > 0.1;
            if (!keep or !isBuildable(x, z)) continue;

            try addHouse(builder, x, z);
        }
    }
}

fn addHouse(builder: *Builder, x: f32, z: f32) !void {
    const width = builder.range(0.9, 1.3);
    const depth = builder.range(0.9, 1.3);
    const height = builder.range(0.6, 1.6);
    const roof_height = builder.range(0.45, 0.65);
    const ridge: RidgeAxis = if (builder.random.boolean()) .x else .z;
    const base_y = street_height;

    try builder.cube(.init(x, base_y + height / 2, z), .init(width, height, depth), &materials.plaster);

    const overhang = 0.15;
    const roof_width = (if (ridge == .z) width else depth) + overhang;
    const roof_length = (if (ridge == .z) depth else width) + overhang;
    try builder.add(.{ .prism = .init(
        .init(x, base_y + height, z),
        roof_width,
        roof_length,
        roof_height,
        ridge,
        &materials.roof_tiles,
    ) });
}

fn addTrees(builder: *Builder) !void {
    var placed: usize = 0;
    while (placed < tree_count) {
        const angle = builder.range(0, 2 * std.math.pi);
        const ring = builder.range(1.25, 1.9);
        const x = @cos(angle) * wall_radius_x * ring;
        const z = @sin(angle) * wall_radius_z * ring;
        const height = builder.range(0.6, 1.0);
        const crown = builder.range(0.9, 1.4);

        try builder.cube(.init(x, height / 2, z), .init(0.25, height, 0.25), &materials.wood);
        try builder.cube(.init(x, height + crown / 2, z), .init(crown, crown, crown), &materials.leaves);
        placed += 1;
    }
}

fn ellipsePoint(t: f32) Vec3 {
    return .init(wall_radius_x * @cos(t), 0, wall_radius_z * @sin(t));
}

fn ellipseHalfWidth(z: f32) f32 {
    const ratio = z / wall_radius_z;
    if (ratio >= 1) return 0;
    return wall_radius_x * @sqrt(1 - ratio * ratio);
}

fn isBuildable(x: f32, z: f32) bool {
    const margin = 1.6;
    const ex = x / (wall_radius_x - margin);
    const ez = z / (wall_radius_z - margin);
    if (ex * ex + ez * ez > 1) return false;

    if (@abs(x - canal_x) < canal_half_width + 1.2 and @abs(z) < canal_half_length + 1) return false;

    if (@abs(x - palace_center.x) < 3.6 and @abs(z - palace_center.z) < 3.2) return false;

    return true;
}
