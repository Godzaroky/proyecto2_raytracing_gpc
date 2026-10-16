const std = @import("std");
const builtin = @import("builtin");
const rl = @import("raylib");

const color = @import("color.zig");
const materials = @import("materials.zig");
const Vec3 = @import("vec3.zig").Vec3;
const Light = @import("light.zig").Light;
const Shape = @import("shapes/shape.zig").Shape;
const Cube = @import("shapes/cube.zig").Cube;
const Prism = @import("shapes/prism.zig").Prism;
const RotatedCube = @import("shapes/rotated_cube.zig").RotatedCube;
const Scene = @import("scene.zig").Scene;
const Camera = @import("camera.zig").Camera;
const OrbitCamera = @import("camera.zig").OrbitCamera;
const Canvas = @import("canvas.zig").Canvas;
const TextureSet = @import("texture.zig").TextureSet;
const renderer = @import("renderer.zig");
const handleInput = @import("input.zig").handleInput;
const Skybox = @import("skybox.zig").Skybox;

const window_width = 1280;
const window_height = 720;

// Resolucion interna = ventana / preview_scale
const preview_scale = 3;

// Escena de prueba
const base_shapes = [_]Shape{
    .{ .cube = .init(.init(0, -0.5, 0), .init(24, 1, 24), &materials.grass) },
    .{ .cube = .init(.init(0, 0.05, -1), .init(2, 0.1, 12), &materials.cobblestone) },
    .{ .cube = .init(.init(0, 2, 5), .init(12, 4, 1.5), &materials.sandstone) },
    .{ .cube = .init(.init(-3, 1, 0), .init(2, 2, 2), &materials.plaster) },
    .{ .prism = .init(.init(-3, 2, 0), 2.4, 2.4, 1, .z, &materials.roof_tiles) },
    .{ .cube = .init(.init(3, 0.75, 1), .init(1.5, 1.5, 1.5), &materials.marble) },
    .{ .cube = .init(.init(3, -0.225, -3), .init(4, 0.55, 2), &materials.water) },
    .{ .cube = .init(.init(3, 0.15, -3), .init(1, 0.1, 2.4), &materials.wood) },
    .{ .cube = .init(.init(2.3, -0.1, -3), .init(0.2, 0.5, 0.2), &materials.wood) },
    .{ .cube = .init(.init(3.7, -0.1, -3), .init(0.2, 0.5, 0.2), &materials.wood) },
};

// Arco de muralla de prueba
const wall_arc = blk: {
    const center = Vec3.init(-7, 1, -6);
    const radius = 3;
    var segments: [5]Shape = undefined;
    for (&segments, 0..) |*segment, i| {
        const angle = std.math.degreesToRadians(@as(f32, @floatFromInt(i)) * 30);
        const position = center.add(Vec3.init(@sin(angle), 0, @cos(angle)).scale(radius));
        segment.* = .{ .rotated_cube = .init(position, .init(1.7, 2, 0.6), angle, &materials.sandstone) };
    }
    break :blk segments;
};

const test_shapes = base_shapes ++ wall_arc;

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
    rl.setTargetFPS(60);
    defer rl.closeWindow();

    const textures = try TextureSet.load(gpa, "assets/textures");
    defer textures.deinit(gpa);

    const skybox = try Skybox.load(gpa, "assets/skybox/sky.png");
    defer skybox.deinit(gpa);

    const scene = Scene{
        .shapes = &test_shapes,
        .lights = &test_lights,
        .textures = &textures,
        .ambient = color.fromHex("#2a3040"),
        .skybox = &skybox,
    };

    var preview_canvas = try Canvas.init(gpa, window_width / preview_scale, window_height / preview_scale);
    defer preview_canvas.deinit(gpa);

    var full_canvas = try Canvas.init(gpa, window_width, window_height);
    defer full_canvas.deinit(gpa);

    var active: *Canvas = &full_canvas;
    var needs_full_render = true;

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
            try renderer.render(&scene, camera, &preview_canvas, threads);
            preview_canvas.upload();
            active = &preview_canvas;
            needs_full_render = true;
        } else if (needs_full_render) {
            try renderer.render(&scene, camera, &full_canvas, threads);
            full_canvas.upload();
            active = &full_canvas;
            needs_full_render = false;
        }

        if (rl.isKeyPressed(.p)) {
            _ = full_canvas.saveToFile("render.png");
        }

        rl.beginDrawing();
        defer rl.endDrawing();
        active.draw(rl.getScreenWidth(), rl.getScreenHeight());
        rl.drawFPS(10, 10);
    }
}
