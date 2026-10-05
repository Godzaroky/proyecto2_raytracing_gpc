const std = @import("std");
const rl = @import("raylib");
const color = @import("color.zig");
const Vec3 = @import("vec3.zig").Vec3;

pub const TextureId = enum {
    sandstone,
    plaster,
    roof_tiles,
    grass,
    water,
    marble,
    cobblestone,
    wood,
};

pub const Texture = struct {
    width: usize,
    height: usize,
    pixels: []Vec3,

    pub fn load(allocator: std.mem.Allocator, path: [:0]const u8) !Texture {
        const image = try rl.loadImage(path);
        defer rl.unloadImage(image);

        const colors = try rl.loadImageColors(image);
        defer rl.unloadImageColors(colors);

        const width: usize = @intCast(image.width);
        const height: usize = @intCast(image.height);
        const pixels = try allocator.alloc(Vec3, width * height);
        for (pixels, colors[0..pixels.len]) |*pixel, source| {
            pixel.* = color.fromRaylib(source);
        }

        return .{ .width = width, .height = height, .pixels = pixels };
    }

    pub fn deinit(self: Texture, allocator: std.mem.Allocator) void {
        allocator.free(self.pixels);
    }

    // Muestreo nearest con repeticion
    pub fn sample(self: Texture, u: f32, v: f32) Vec3 {
        const fu = u - @floor(u);
        const fv = v - @floor(v);
        const width_f: f32 = @floatFromInt(self.width);
        const height_f: f32 = @floatFromInt(self.height);
        const x = @min(self.width - 1, @as(usize, @intFromFloat(fu * width_f)));
        const y = @min(self.height - 1, @as(usize, @intFromFloat((1 - fv) * height_f)));
        return self.pixels[y * self.width + x];
    }
};

pub const TextureSet = struct {
    textures: std.EnumArray(TextureId, Texture),

    pub fn load(allocator: std.mem.Allocator, comptime directory: []const u8) !TextureSet {
        var set = TextureSet{ .textures = undefined };
        var loaded: usize = 0;
        errdefer for (set.textures.values[0..loaded]) |texture| texture.deinit(allocator);

        inline for (std.meta.fields(TextureId)) |field| {
            const path = directory ++ "/" ++ field.name ++ ".png";
            set.textures.set(@enumFromInt(field.value), try Texture.load(allocator, path));
            loaded += 1;
        }
        return set;
    }

    pub fn deinit(self: TextureSet, allocator: std.mem.Allocator) void {
        for (self.textures.values) |texture| texture.deinit(allocator);
    }

    pub fn get(self: *const TextureSet, id: TextureId) *const Texture {
        return self.textures.getPtrConst(id);
    }
};
