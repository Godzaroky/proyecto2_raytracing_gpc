const Material = @import("material.zig").Material;

pub const sandstone = Material{
    .texture = .sandstone,
    .texture_scale = 2,
    .albedo = 0.9,
    .specular = 0.1,
    .shininess = 10,
};

pub const plaster = Material{
    .texture = .plaster,
    .albedo = 0.9,
    .specular = 0.05,
    .shininess = 8,
};

pub const roof_tiles = Material{
    .texture = .roof_tiles,
    .albedo = 0.85,
    .specular = 0.3,
    .shininess = 24,
};

pub const grass = Material{
    .texture = .grass,
    .texture_scale = 2,
    .albedo = 0.9,
    .specular = 0.02,
    .shininess = 4,
};

pub const water = Material{
    .texture = .water,
    .texture_scale = 2,
    .albedo = 0.4,
    .specular = 0.9,
    .shininess = 180,
    .transparency = 0.6,
    .reflectivity = 0.3,
    .refractive_index = 1.33,
};

pub const marble = Material{
    .texture = .marble,
    .albedo = 0.75,
    .specular = 0.7,
    .shininess = 120,
    .reflectivity = 0.15,
};

pub const cobblestone = Material{
    .texture = .cobblestone,
    .albedo = 0.85,
    .specular = 0.15,
    .shininess = 16,
};

pub const wood = Material{
    .texture = .wood,
    .albedo = 0.85,
    .specular = 0.1,
    .shininess = 10,
};
