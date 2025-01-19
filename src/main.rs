#![feature(test)]

use image::{Rgb, RgbImage};
use math::{RayInterserct, Vec3};
use sphere::Sphere;
use camera::Camera;

mod camera;
mod sphere;
mod ray;
mod math;

fn main() {
    let camera = Camera::default();

    let sphere = Sphere {
        pos: Vec3::new(0.0, 0.0, -2.0),
        radius: 1.0,
    };
    let directional_light = Vec3::new(1.0, 1.0, -0.5).normalize();

    let mut img = RgbImage::new(camera.dimensions.x as u32, camera.dimensions.y as u32);

    for ray in camera.iter_rays() {
        let target = ray.target.expect("camera ray must have target");

        if let Some(t) = sphere.ray_intersect(&ray) {
            let hit_point = ray.origin + ray.direction.scale(t);
            let normal = (hit_point - sphere.pos).normalize();
            let light_intensity = normal.dot(&directional_light).max(0.0);

            let color = (255.0 * light_intensity) as u8;
            img.put_pixel(target.x, target.y, Rgb([color, color, color]));
        } else {
            img.put_pixel(target.x, target.y, Rgb([0, 0, 0]));
        }
    }

    img.save("output.png").unwrap();
}

#[cfg(test)]
mod tests {
    use super::*;
    use nalgebra::Vector2;

    extern crate test;

    #[bench]
    fn time_per_ray(b: &mut test::Bencher) {
        let camera = Camera {
            dimensions: Vector2::new(5, 5),
            ..Camera::default()
        };
    
        let sphere = Sphere {
            pos: Vec3::new(0.0, 0.0, -2.0),
            radius: 1.0,
        };
        let directional_light = Vec3::new(1.0, 1.0, -0.5).normalize();
    
        for ray in camera.iter_rays() {
            b.iter(|| {
                if let Some(t) = sphere.ray_intersect(&ray) {
                    let hit_point = ray.origin + ray.direction.scale(t);
                    let normal = (hit_point - sphere.pos).normalize();
                    let light_intensity = normal.dot(&directional_light).max(0.0);
                    test::black_box(light_intensity); // assume it will be used
                }
            });
        }
    }
}
