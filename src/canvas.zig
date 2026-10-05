const std = @import("std");
const rl = @import("raylib");

pub const Canvas = struct {
    width: usize,
    height: usize,
    pixels: []rl.Color,
    texture: rl.Texture2D,

    pub fn init(allocator: std.mem.Allocator, width: usize, height: usize) !Canvas {
        const pixels = try allocator.alloc(rl.Color, width * height);
        errdefer allocator.free(pixels);
        @memset(pixels, rl.Color.black);

        const image = rl.genImageColor(@intCast(width), @intCast(height), rl.Color.black);
        defer rl.unloadImage(image);
        const texture = try rl.loadTextureFromImage(image);

        return .{
            .width = width,
            .height = height,
            .pixels = pixels,
            .texture = texture,
        };
    }

    pub fn deinit(self: *Canvas, allocator: std.mem.Allocator) void {
        rl.unloadTexture(self.texture);
        allocator.free(self.pixels);
    }

    pub fn upload(self: Canvas) void {
        rl.updateTexture(self.texture, self.pixels.ptr);
    }

    pub fn draw(self: Canvas, screen_width: i32, screen_height: i32) void {
        const source = rl.Rectangle{
            .x = 0,
            .y = 0,
            .width = @floatFromInt(self.width),
            .height = @floatFromInt(self.height),
        };
        const dest = rl.Rectangle{
            .x = 0,
            .y = 0,
            .width = @floatFromInt(screen_width),
            .height = @floatFromInt(screen_height),
        };
        rl.drawTexturePro(self.texture, source, dest, .{ .x = 0, .y = 0 }, 0, .white);
    }

    pub fn saveToFile(self: Canvas, path: [:0]const u8) bool {
        const image = rl.Image{
            .data = @ptrCast(self.pixels.ptr),
            .width = @intCast(self.width),
            .height = @intCast(self.height),
            .mipmaps = 1,
            .format = .uncompressed_r8g8b8a8,
        };
        return rl.exportImage(image, path);
    }
};
