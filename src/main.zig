const std = @import("std");
const builtin = @import("builtin");
const rl = @import("raylib");

const color = @import("color.zig");
const Vec3 = @import("vec3.zig").Vec3;
const Material = @import("material.zig").Material;
const Light = @import("light.zig").Light;
const Shape = @import("shapes/shape.zig").Shape;
const Scene = @import("scene.zig").Scene;
const Camera = @import("camera.zig").Camera;
const Canvas = @import("canvas.zig").Canvas;
const renderer = @import("renderer.zig");

const window_width = 1280;
const window_height = 720;

// Resolucion interna = ventana / render_scale
const render_scale = 1;

// Escena de prueba
const ground = Material{
    .color = color.fromHex("#8a9a5b"),
    .albedo = 0.9,
    .specular = 0.05,
    .shininess = 8,
};

const red_plastic = Material{
    .color = color.fromHex("#c0392b"),
    .albedo = 0.85,
    .specular = 0.5,
    .shininess = 64,
};

const sandstone = Material{
    .color = color.fromHex("#d8c39a"),
    .albedo = 0.9,
    .specular = 0.1,
    .shininess = 12,
};

const polished_marble = Material{
    .color = color.fromHex("#eeeae0"),
    .albedo = 0.7,
    .specular = 0.8,
    .shininess = 200,
};

const test_shapes = [_]Shape{
    .{ .sphere = .{ .center = .init(0, -1000, 0), .radius = 1000, .material = &ground } },
    .{ .sphere = .{ .center = .init(-2.5, 1, 0), .radius = 1, .material = &red_plastic } },
    .{ .sphere = .{ .center = .init(0, 1.5, 1), .radius = 1.5, .material = &sandstone } },
    .{ .sphere = .{ .center = .init(2.5, 0.8, -0.5), .radius = 0.8, .material = &polished_marble } },
};

const test_lights = [_]Light{
    .{ .position = .init(-8, 10, -6), .color = color.fromHex("#ffe2b8"), .intensity = 1.0 },
    .{ .position = .init(10, 6, -4), .color = color.fromHex("#b8d4ff"), .intensity = 0.3 },
};

const test_scene = Scene{
    .shapes = &test_shapes,
    .lights = &test_lights,
    .ambient = color.fromHex("#2a3040"),
    .sky_top = color.fromHex("#4a7bc8"),
    .sky_horizon = color.fromHex("#cfe3f5"),
};

pub fn main() !void {
    var debug_allocator: std.heap.DebugAllocator(.{}) = .init;
    defer if (builtin.mode == .Debug) {
        _ = debug_allocator.deinit();
    };
    const gpa = if (builtin.mode == .Debug) debug_allocator.allocator() else std.heap.smp_allocator;

    rl.setTraceLogLevel(.warning);
    rl.initWindow(window_width, window_height, "Diorama - Raytracer");
    defer rl.closeWindow();

    var canvas = try Canvas.init(gpa, window_width / render_scale, window_height / render_scale);
    defer canvas.deinit(gpa);

    const thread_count = std.Thread.getCpuCount() catch 1;
    const threads = try gpa.alloc(std.Thread, @max(1, thread_count));
    defer gpa.free(threads);

    const camera = Camera.lookAt(.init(0, 3, -9), .init(0, 1, 0), std.math.pi / 3.0);

    while (!rl.windowShouldClose()) {
        try renderer.render(&test_scene, camera, &canvas, threads);
        canvas.upload();

        if (rl.isKeyPressed(.p)) {
            _ = canvas.saveToFile("render.png");
        }

        rl.beginDrawing();
        defer rl.endDrawing();
        canvas.draw(rl.getScreenWidth(), rl.getScreenHeight());
        rl.drawFPS(10, 10);
    }
}
