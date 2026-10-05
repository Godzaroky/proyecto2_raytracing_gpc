const rl = @import("raylib");
const Vec3 = @import("vec3.zig").Vec3;
const htmlColor = @import("cute_colors.zig").htmlColor;

pub fn fromHex(comptime html: []const u8) Vec3 {
    return fromRaylib(htmlColor(html));
}

pub fn fromRaylib(color: rl.Color) Vec3 {
    return .{
        .x = @as(f32, @floatFromInt(color.r)) / 255,
        .y = @as(f32, @floatFromInt(color.g)) / 255,
        .z = @as(f32, @floatFromInt(color.b)) / 255,
    };
}

pub fn toRaylib(color: Vec3) rl.Color {
    return .{
        .r = toByte(color.x),
        .g = toByte(color.y),
        .b = toByte(color.z),
        .a = 255,
    };
}

inline fn toByte(channel: f32) u8 {
    return @intFromFloat(@max(0, @min(255, channel * 255 + 0.5)));
}
