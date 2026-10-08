const std = @import("std");
const builtin = @import("builtin");
const rl = @import("raylib");

const color = @import("color.zig");
const materials = @import("materials.zig");
const Vec3 = @import("vec3.zig").Vec3;
const Light = @import("light.zig").Light;
const Shape = @import("shapes/shape.zig").Shape;
const Cube = @import("shapes/cube.zig").Cube;
const Scene = @import("scene.zig").Scene;
const Camera = @import("camera.zig").Camera;
const OrbitCamera = @import("camera.zig").OrbitCamera;
const Canvas = @import("canvas.zig").Canvas;
const TextureSet = @import("texture.zig").TextureSet;
const renderer = @import("renderer.zig");
const handleInput = @import("input.zig").handleInput;

const window_width = 1280;
const window_height = 720;

// Resolucion interna = ventana / render_scale
const render_scale = 1;

// Escena de prueba
const test_shapes = [_]Shape{
    .{ .cube = .init(.init(0, -0.5, 0), .init(24, 1, 24), &materials.grass) },
    .{ .cube = .init(.init(0, 0.05, -1), .init(2, 0.1, 12), &materials.cobblestone) },
    .{ .cube = .init(.init(0, 2, 5), .init(12, 4, 1.5), &materials.sandstone) },
    .{ .cube = .init(.init(-3, 1, 0), .init(2, 2, 2), &materials.plaster) },
    .{ .cube = .init(.init(-3, 2.25, 0), .init(2.2, 0.5, 2.2), &materials.roof_tiles) },
    .{ .cube = .init(.init(3, 0.75, 1), .init(1.5, 1.5, 1.5), &materials.marble) },
    .{ .cube = .init(.init(3, 0.02, -3), .init(4, 0.04, 2), &materials.water) },
    .{ .cube = .init(.init(3, 0.15, -3), .init(1, 0.1, 2.4), &materials.wood) },
};

const test_lights = [_]Light{
    .{ .position = .init(-8, 10, -6), .color = color.fromHex("#ffe2b8"), .intensity = 1.0 },
    .{ .position = .init(10, 6, -4), .color = color.fromHex("#b8d4ff"), .intensity = 0.3 },
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

    const textures = try TextureSet.load(gpa, "assets/textures");
    defer textures.deinit(gpa);

    const scene = Scene{
        .shapes = &test_shapes,
        .lights = &test_lights,
        .textures = &textures,
        .ambient = color.fromHex("#2a3040"),
        .sky_top = color.fromHex("#4a7bc8"),
        .sky_horizon = color.fromHex("#cfe3f5"),
    };

    var canvas = try Canvas.init(gpa, window_width / render_scale, window_height / render_scale);
    defer canvas.deinit(gpa);

    const thread_count = std.Thread.getCpuCount() catch 1;
    const threads = try gpa.alloc(std.Thread, @max(1, thread_count));
    defer gpa.free(threads);

    var orbit = OrbitCamera{
        .target = .init(0, 1, 1),
        .yaw = std.math.pi,
        .pitch = std.math.degreesToRadians(35.0),
        .distance = 12,
    };

    while (!rl.windowShouldClose()) {
        const dt = @min(rl.getFrameTime(), 0.1);
        const moved = handleInput(&orbit, dt);
        const camera = orbit.toCamera();

        if (moved) {
            std.debug.print("yaw={d:.2} pitch={d:.2} distance={d:.2}\n", .{ orbit.yaw, orbit.pitch, orbit.distance });
        }

        try renderer.render(&scene, camera, &canvas, threads);
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
