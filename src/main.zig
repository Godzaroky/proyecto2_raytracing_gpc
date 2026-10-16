const std = @import("std");
const builtin = @import("builtin");
const rl = @import("raylib");

const color = @import("color.zig");
const diorama = @import("diorama.zig");
const Bvh = @import("bvh.zig").Bvh;
const Scene = @import("scene.zig").Scene;
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

// Grabacion: una vuelta completa, 10 s a 30 fps
const recording_frames = 300;

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

    const shapes = try diorama.build(gpa);
    defer gpa.free(shapes);

    const bvh = try Bvh.build(gpa, shapes);
    defer bvh.deinit(gpa);

    const scene = Scene{
        .bvh = &bvh,
        .lights = &diorama.lights,
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
        .target = .init(0, 0, 0),
        .yaw = std.math.degreesToRadians(150.0),
        .pitch = std.math.degreesToRadians(40.0),
        .distance = 18,
    };

    var recording = false;
    var recorded: u32 = 0;

    while (!rl.windowShouldClose()) {
        if (rl.isKeyPressed(.v)) {
            recording = !recording;
            recorded = 0;
            if (recording) _ = rl.makeDirectory("frames");
        }

        if (recording) {
            orbit.yaw += 2 * std.math.pi / @as(f32, recording_frames);
            try renderer.render(&scene, orbit.toCamera(), &full_canvas, threads);
            full_canvas.upload();
            active = &full_canvas;
            needs_full_render = false;

            var path_buffer: [64]u8 = undefined;
            const path = try std.fmt.bufPrintZ(&path_buffer, "frames/frame_{d:0>4}.png", .{recorded});
            _ = full_canvas.saveToFile(path);

            recorded += 1;
            if (recorded == recording_frames) recording = false;
        } else {
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
        }

        if (rl.isKeyPressed(.p)) {
            _ = full_canvas.saveToFile("render.png");
        }

        rl.beginDrawing();
        defer rl.endDrawing();
        active.draw(rl.getScreenWidth(), rl.getScreenHeight());
        rl.drawFPS(10, 10);

        if (recording) {
            var text_buffer: [64]u8 = undefined;
            const text = try std.fmt.bufPrintZ(&text_buffer, "Recording {d}/{d}", .{ recorded, recording_frames });
            rl.drawText(text, 10, 40, 20, .red);
        }
    }
}
