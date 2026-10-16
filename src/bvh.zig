const std = @import("std");
const Vec3 = @import("vec3.zig").Vec3;
const Ray = @import("ray.zig").Ray;
const Hit = @import("ray.zig").Hit;
const Aabb = @import("aabb.zig").Aabb;
const Shape = @import("shapes/shape.zig").Shape;

const leaf_size = 4;
const max_stack = 64;

// Si count es 0 es nodo interno y sus hijos estan en first y first + 1
const Node = struct {
    bounds: Aabb,
    first: u32,
    count: u32,
};

// Jerarquia de cajas envolventes sobre las figuras de la escena
pub const Bvh = struct {
    nodes: []Node,
    shapes: []Shape,

    pub fn build(allocator: std.mem.Allocator, source: []const Shape) !Bvh {
        const shapes = try allocator.dupe(Shape, source);
        errdefer allocator.free(shapes);

        var nodes: std.ArrayList(Node) = .empty;
        errdefer nodes.deinit(allocator);
        try nodes.ensureTotalCapacity(allocator, 2 * @max(shapes.len, 1));

        nodes.appendAssumeCapacity(undefined);
        buildNode(&nodes, shapes, 0, 0, shapes.len);

        return .{
            .nodes = try nodes.toOwnedSlice(allocator),
            .shapes = shapes,
        };
    }

    pub fn deinit(self: Bvh, allocator: std.mem.Allocator) void {
        allocator.free(self.nodes);
        allocator.free(self.shapes);
    }

    pub fn closestHit(self: *const Bvh, ray: Ray, t_min: f32, t_max: f32) ?Hit {
        const inv_dir = inverse(ray.direction);
        var closest: ?Hit = null;
        var nearest = t_max;

        var stack: [max_stack]u32 = undefined;
        var top: usize = 1;
        stack[0] = 0;

        while (top > 0) {
            top -= 1;
            const node = &self.nodes[stack[top]];
            if (!node.bounds.hit(ray.origin, inv_dir, t_min, nearest)) continue;

            if (node.count > 0) {
                for (self.shapes[node.first..][0..node.count]) |*shape| {
                    if (shape.intersect(ray, t_min, nearest)) |hit| {
                        nearest = hit.distance;
                        closest = hit;
                    }
                }
            } else {
                stack[top] = node.first;
                stack[top + 1] = node.first + 1;
                top += 2;
            }
        }
        return closest;
    }

    // Los materiales transparentes no bloquean la luz
    pub fn isOccluded(self: *const Bvh, ray: Ray, t_min: f32, t_max: f32) bool {
        const inv_dir = inverse(ray.direction);

        var stack: [max_stack]u32 = undefined;
        var top: usize = 1;
        stack[0] = 0;

        while (top > 0) {
            top -= 1;
            const node = &self.nodes[stack[top]];
            if (!node.bounds.hit(ray.origin, inv_dir, t_min, t_max)) continue;

            if (node.count > 0) {
                for (self.shapes[node.first..][0..node.count]) |*shape| {
                    const hit = shape.intersect(ray, t_min, t_max) orelse continue;
                    if (hit.material.transparency > 0) continue;
                    return true;
                }
            } else {
                stack[top] = node.first;
                stack[top + 1] = node.first + 1;
                top += 2;
            }
        }
        return false;
    }
};

fn buildNode(nodes: *std.ArrayList(Node), shapes: []Shape, index: usize, start: usize, end: usize) void {
    var bounds = Aabb.empty;
    var centers = Aabb.empty;
    for (shapes[start..end]) |*shape| {
        const box = shape.bounds();
        bounds = bounds.merge(box);
        const c = box.center();
        centers = centers.merge(.{ .min = c, .max = c });
    }

    const count = end - start;
    if (count <= leaf_size) {
        nodes.items[index] = .{ .bounds = bounds, .first = @intCast(start), .count = @intCast(count) };
        return;
    }

    // Partir por la mitad sobre el eje mas largo
    const extent = centers.max.sub(centers.min);
    const axis: Axis = if (extent.x >= extent.y and extent.x >= extent.z) .x else if (extent.y >= extent.z) .y else .z;
    std.mem.sort(Shape, shapes[start..end], axis, lessThan);
    const middle = start + count / 2;

    const left = nodes.items.len;
    nodes.appendAssumeCapacity(undefined);
    nodes.appendAssumeCapacity(undefined);
    nodes.items[index] = .{ .bounds = bounds, .first = @intCast(left), .count = 0 };

    buildNode(nodes, shapes, left, start, middle);
    buildNode(nodes, shapes, left + 1, middle, end);
}

const Axis = enum { x, y, z };

fn lessThan(axis: Axis, a: Shape, b: Shape) bool {
    const ca = a.bounds().center();
    const cb = b.bounds().center();
    return switch (axis) {
        .x => ca.x < cb.x,
        .y => ca.y < cb.y,
        .z => ca.z < cb.z,
    };
}

fn inverse(direction: Vec3) Vec3 {
    return .init(1 / direction.x, 1 / direction.y, 1 / direction.z);
}
