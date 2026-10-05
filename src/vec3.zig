pub const Vec3 = struct {
    x: f32,
    y: f32,
    z: f32,

    pub const zero = Vec3{ .x = 0, .y = 0, .z = 0 };
    pub const one = Vec3{ .x = 1, .y = 1, .z = 1 };
    pub const up = Vec3{ .x = 0, .y = 1, .z = 0 };

    pub inline fn init(x: f32, y: f32, z: f32) Vec3 {
        return .{ .x = x, .y = y, .z = z };
    }

    pub inline fn splat(value: f32) Vec3 {
        return .{ .x = value, .y = value, .z = value };
    }

    pub inline fn add(a: Vec3, b: Vec3) Vec3 {
        return .{ .x = a.x + b.x, .y = a.y + b.y, .z = a.z + b.z };
    }

    pub inline fn sub(a: Vec3, b: Vec3) Vec3 {
        return .{ .x = a.x - b.x, .y = a.y - b.y, .z = a.z - b.z };
    }

    pub inline fn mul(a: Vec3, b: Vec3) Vec3 {
        return .{ .x = a.x * b.x, .y = a.y * b.y, .z = a.z * b.z };
    }

    pub inline fn scale(a: Vec3, s: f32) Vec3 {
        return .{ .x = a.x * s, .y = a.y * s, .z = a.z * s };
    }

    pub inline fn negate(a: Vec3) Vec3 {
        return .{ .x = -a.x, .y = -a.y, .z = -a.z };
    }

    pub inline fn dot(a: Vec3, b: Vec3) f32 {
        return a.x * b.x + a.y * b.y + a.z * b.z;
    }

    pub inline fn cross(a: Vec3, b: Vec3) Vec3 {
        return .{
            .x = a.y * b.z - a.z * b.y,
            .y = a.z * b.x - a.x * b.z,
            .z = a.x * b.y - a.y * b.x,
        };
    }

    pub inline fn lengthSqr(a: Vec3) f32 {
        return a.dot(a);
    }

    pub inline fn length(a: Vec3) f32 {
        return @sqrt(a.dot(a));
    }

    pub inline fn normalize(a: Vec3) Vec3 {
        const len = a.length();
        if (len == 0) return a;
        return a.scale(1 / len);
    }

    pub inline fn lerp(a: Vec3, b: Vec3, t: f32) Vec3 {
        return a.add(b.sub(a).scale(t));
    }
};
