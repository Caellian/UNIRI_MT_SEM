use crate::ray::Ray;
use glam::{Quat, U64Vec2, U8Vec2, UVec2, Vec2, Vec3};

pub struct Camera {
    pub position: Vec3,
    pub rotation: Quat,

    pub dimensions: U64Vec2,
    pub samples_per_pixel: U8Vec2,

    pub fov: f32,
}

impl Default for Camera {
    fn default() -> Self {
        Self {
            position: Vec3::ZERO,
            rotation: Default::default(),
            dimensions: U64Vec2::new(800, 600),
            samples_per_pixel: U8Vec2::new(1, 1),
            fov: 90f32.to_radians(),
        }
    }
}

impl Camera {
    pub fn aspect_ratio(&self) -> f32 {
        self.dimensions.x as f32 / self.dimensions.y as f32
    }

    pub fn iter_rays(&self) -> RayIterator<'_> {
        let spp = self.samples_per_pixel.as_vec2();
        let sample_step = Vec2::new(1.0, 1.0) / spp;
        let step = Vec2::new(1.0, 1.0) / spp;
        RayIterator {
            camera: self,
            i: Vec2::new(0.5, 0.5) - (spp / 2.0),
            step,
        }
    }
}

pub struct RayIterator<'c> {
    camera: &'c Camera,
    i: Vec2,
    step: Vec2,
}

impl Iterator for RayIterator<'_> {
    type Item = Ray;

    fn next(&mut self) -> Option<Self::Item> {
        if self.i.y >= self.camera.dimensions.y as f32 - 1. {
            return None;
        }
        if self.i.x >= self.camera.dimensions.x as f32 - 1. {
            self.i.y += self.step.y;
            self.i.x = 0.0;
            if self.i.y >= self.camera.dimensions.y as f32 - 1. {
                return None;
            }
        }
        let ndc: Vec2 = Vec2::new(
            self.i.x / self.camera.dimensions.x as f32,
            self.i.y / self.camera.dimensions.y as f32,
        );
        let screen_x =
            (2.0 * ndc.x - 1.0) * (self.camera.fov / 2.0).tan() * self.camera.aspect_ratio();
        let screen_y = (1.0 - 2.0 * ndc.y) * (self.camera.fov / 2.0).tan();

        self.i.x += self.step.x;

        let direction = Vec3::new(screen_x, screen_y, -1.0).normalize();

        Some(Ray {
            origin: self.camera.position,
            direction,
            source: Some(U64Vec2::new(
                self.i.x.floor() as u64,
                self.i.y.floor() as u64,
            )),
        })
    }
}
