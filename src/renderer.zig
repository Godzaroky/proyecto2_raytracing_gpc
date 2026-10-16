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
const max_depth = 4;

const RenderJob = struct {
    scene: *const Scene,
    camera: Camera,
    canvas: *Canvas,
    next_row: std.atomic.Value(usize),
};

const Shading = struct {
    diffuse: Vec3,
    specular: Vec3,
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
            pixel.* = color.toRaylib(castRay(job.scene, ray, 0));
        }
    }
}

pub fn castRay(scene: *const Scene, ray: Ray, depth: u32) Vec3 {
    if (depth > max_depth) return background(scene, ray.direction);

    const hit = closestHit(scene, ray, surface_bias, far_distance) orelse return background(scene, ray.direction);
    const mat = hit.material;

    const outer_normal = hit.normal;
    const entering = ray.direction.dot(outer_normal) < 0;
    const facing_normal = if (entering) outer_normal else outer_normal.negate();

    const local = shade(scene, ray, hit);

    var reflect_weight = mat.reflectivity;
    var refract_weight = mat.transparency;
    const local_weight = @max(0, 1 - reflect_weight - refract_weight);

    if (refract_weight > 0) {
        const fresnel = schlick(ray.direction, facing_normal, mat.refractive_index);
        reflect_weight += refract_weight * fresnel;
        refract_weight *= 1 - fresnel;
    }

    var refracted_color = Vec3.zero;
    if (refract_weight > 0) {
        if (refract(ray.direction, facing_normal, entering, mat.refractive_index)) |direction| {
            const refract_ray = Ray{
                .origin = hit.point.sub(facing_normal.scale(surface_bias)),
                .direction = direction,
            };
            refracted_color = castRay(scene, refract_ray, depth + 1);
        } else {
            // Reflexion total interna
            reflect_weight += refract_weight;
            refract_weight = 0;
        }
    }

    var reflected_color = Vec3.zero;
    if (reflect_weight > 0) {
        const reflect_ray = Ray{
            .origin = hit.point.add(facing_normal.scale(surface_bias)),
            .direction = reflect(ray.direction, facing_normal),
        };
        reflected_color = castRay(scene, reflect_ray, depth + 1);
    }

    return local.diffuse.scale(local_weight)
        .add(local.specular)
        .add(reflected_color.scale(reflect_weight))
        .add(refracted_color.scale(refract_weight));
}

fn closestHit(scene: *const Scene, ray: Ray, t_min: f32, t_max: f32) ?Hit {
    var closest: ?Hit = null;
    var nearest = t_max;
    for (scene.shapes) |*shape| {
        if (shape.intersect(ray, t_min, nearest)) |hit| {
            nearest = hit.distance;
            closest = hit;
        }
    }
    return closest;
}

// Los materiales transparentes no bloquean la luz
fn isOccluded(scene: *const Scene, ray: Ray, t_max: f32) bool {
    for (scene.shapes) |*shape| {
        const hit = shape.intersect(ray, surface_bias, t_max) orelse continue;
        if (hit.material.transparency > 0) continue;
        return true;
    }
    return false;
}

// Phong: ambiental + difusa + especular, con sombras
fn shade(scene: *const Scene, ray: Ray, hit: Hit) Shading {
    const mat = hit.material;
    const view_dir = ray.direction.negate();
    const normal = if (hit.normal.dot(view_dir) < 0) hit.normal.negate() else hit.normal;
    const base_color = surfaceColor(scene, hit);

    var diffuse = scene.ambient.mul(base_color).scale(mat.albedo);
    var specular = Vec3.zero;

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

        diffuse = diffuse.add(base_color.mul(radiance).scale(n_dot_l * mat.albedo));

        const reflect_dir = reflect(light_dir.negate(), normal);
        const spec_angle = @max(0, reflect_dir.dot(view_dir));
        specular = specular.add(radiance.scale(std.math.pow(f32, spec_angle, mat.shininess) * mat.specular));
    }

    return .{ .diffuse = diffuse, .specular = specular };
}

fn surfaceColor(scene: *const Scene, hit: Hit) Vec3 {
    const mat = hit.material;
    const texture_id = mat.texture orelse return mat.color;
    return scene.textures.get(texture_id).sample(hit.u, hit.v).mul(mat.color);
}

// incident apunta hacia la superficie
pub fn reflect(incident: Vec3, normal: Vec3) Vec3 {
    return incident.sub(normal.scale(2 * incident.dot(normal)));
}

// Ley de Snell, normal del lado de donde viene el rayo
fn refract(incident: Vec3, normal: Vec3, entering: bool, refractive_index: f32) ?Vec3 {
    const eta = if (entering) 1 / refractive_index else refractive_index;
    const cos_i = -incident.dot(normal);
    const k = 1 - eta * eta * (1 - cos_i * cos_i);
    if (k < 0) return null;
    return incident.scale(eta).add(normal.scale(eta * cos_i - @sqrt(k))).normalize();
}

// Aproximacion de Schlick
fn schlick(incident: Vec3, normal: Vec3, refractive_index: f32) f32 {
    const r0_root = (1 - refractive_index) / (1 + refractive_index);
    const r0 = r0_root * r0_root;
    const cos_i = @abs(incident.dot(normal));
    return r0 + (1 - r0) * std.math.pow(f32, 1 - cos_i, 5);
}

// Fondo con Skybox
fn background(scene: *const Scene, direction: Vec3) Vec3 {
    return scene.skybox.sample(direction);
}
