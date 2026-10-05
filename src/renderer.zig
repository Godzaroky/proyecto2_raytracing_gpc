const std = @import("std");
const color = @import("color.zig");
const Vec3 = @import("vec3.zig").Vec3;
const Ray = @import("ray.zig").Ray;
const Hit = @import("ray.zig").Hit;
const Scene = @import("scene.zig").Scene;
const Light = @import("light.zig").Light;
const Camera = @import("camera.zig").Camera;
const Canvas = @import("canvas.zig").Canvas;

const surface_bias = 1e-3;
const far_distance = std.math.floatMax(f32);

const RenderJob = struct {
    scene: *const Scene,
    camera: Camera,
    canvas: *Canvas,
    next_row: std.atomic.Value(usize),
};

pub fn render(scene: *const Scene, camera: Camera, canvas: *Canvas, threads: []std.Thread) !void {
    var job = RenderJob{
        .scene = scene,
        .camera = camera,
        .canvas = canvas,
        .next_row = .init(0),
    };

    for (threads) |*thread| {
        thread.* = try std.Thread.spawn(.{}, renderRows, .{&job});
    }
    for (threads) |thread| {
        thread.join();
    }
}

fn renderRows(job: *RenderJob) void {
    const canvas = job.canvas;
    const width_f: f32 = @floatFromInt(canvas.width);
    const height_f: f32 = @floatFromInt(canvas.height);
    const aspect_ratio = width_f / height_f;

    while (true) {
        const y = job.next_row.fetchAdd(1, .monotonic);
        if (y >= canvas.height) return;

        const y_f: f32 = @floatFromInt(y);
        const ndc_y = 1 - (y_f + 0.5) * 2 / height_f;
        const row = canvas.pixels[y * canvas.width ..][0..canvas.width];

        for (row, 0..) |*pixel, x| {
            const x_f: f32 = @floatFromInt(x);
            const ndc_x = (x_f + 0.5) * 2 / width_f - 1;
            const ray = Ray{
                .origin = job.camera.position,
                .direction = job.camera.rayDirection(ndc_x, ndc_y, aspect_ratio),
            };
            pixel.* = color.toRaylib(castRay(job.scene, ray));
        }
    }
}

pub fn castRay(scene: *const Scene, ray: Ray) Vec3 {
    const hit = closestHit(scene, ray, surface_bias, far_distance) orelse return background(scene, ray.direction);
    return shade(scene, ray, hit);
}

fn closestHit(scene: *const Scene, ray: Ray, t_min: f32, t_max: f32) ?Hit {
    var closest: ?Hit = null;
    var nearest = t_max;
    for (scene.shapes) |shape| {
        if (shape.intersect(ray, t_min, nearest)) |hit| {
            nearest = hit.distance;
            closest = hit;
        }
    }
    return closest;
}

fn isOccluded(scene: *const Scene, ray: Ray, t_max: f32) bool {
    for (scene.shapes) |shape| {
        if (shape.intersect(ray, surface_bias, t_max) != null) return true;
    }
    return false;
}

// Phong: ambiental + difusa + especular, con sombras
fn shade(scene: *const Scene, ray: Ray, hit: Hit) Vec3 {
    const mat = hit.material;
    const view_dir = ray.direction.negate();
    const normal = if (hit.normal.dot(view_dir) < 0) hit.normal.negate() else hit.normal;
    const base_color = mat.color;

    var result = scene.ambient.mul(base_color).scale(mat.albedo);

    for (scene.lights) |light| {
        const to_light = light.position.sub(hit.point);
        const light_distance = to_light.length();
        const light_dir = to_light.scale(1 / light_distance);

        const n_dot_l = normal.dot(light_dir);
        if (n_dot_l <= 0) continue;

        const shadow_ray = Ray{
            .origin = hit.point.add(normal.scale(surface_bias)),
            .direction = light_dir,
        };
        if (isOccluded(scene, shadow_ray, light_distance)) continue;

        const radiance = light.color.scale(light.intensity);

        const diffuse = base_color.mul(radiance).scale(n_dot_l * mat.albedo);

        const reflect_dir = reflect(light_dir.negate(), normal);
        const spec_angle = @max(0, reflect_dir.dot(view_dir));
        const specular = radiance.scale(std.math.pow(f32, spec_angle, mat.shininess) * mat.specular);

        result = result.add(diffuse).add(specular);
    }

    return result;
}

// incident apunta hacia la superficie
pub fn reflect(incident: Vec3, normal: Vec3) Vec3 {
    return incident.sub(normal.scale(2 * incident.dot(normal)));
}

// Fondo provisional hasta tener skybox
fn background(scene: *const Scene, direction: Vec3) Vec3 {
    const t = @max(0, direction.y);
    return scene.sky_horizon.lerp(scene.sky_top, t);
}
