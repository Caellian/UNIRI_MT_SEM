#![feature(test)]

use image::{Rgb, RgbImage};
use math::Intersect;
use shape::Sphere;
use camera::Camera;
use pbr::ProgressBar;
use glam::Vec3;

mod camera;
mod shape;
mod ray;
mod math;
mod material;
mod scene;
mod light;

fn main() {
    let camera = Camera::default();

    let sphere = Sphere {
        pos: Vec3::new(0.0, 0.0, -2.0),
        radius: 1.0,
    };
    let directional_light = Vec3::new(1.0, 1.0, -0.5).normalize();

    let mut img = RgbImage::new(camera.dimensions.x as u32, camera.dimensions.y as u32);

    let total_rays = camera.dimensions.element_product() * camera.samples_per_pixel.as_u64vec2().element_product();
    let mut progress_bar = ProgressBar::new(total_rays);
    progress_bar.format("[=>-]");
    for ray in camera.iter_rays() {
        progress_bar.inc();
        let target = ray.source.expect("camera ray must have target");

        if let Some(distance) = sphere.intersect(&ray) {
            let hit_point = ray.origin + (ray.direction * distance);
            let normal = (hit_point - sphere.pos).normalize();
            let light_intensity = normal.dot(directional_light).max(0.0);

            let color = (255.0 * light_intensity) as u8;
            img.put_pixel(target.x as u32, target.y as u32, Rgb([color, color, color]));
        } else {
            img.put_pixel(target.x as u32, target.y as u32, Rgb([0, 0, 0]));
        }
    }
    progress_bar.finish_print("saving output...");

    img.save("output.png").unwrap();
    println!("\rdone!\x1B[J")
}

#[cfg(test)]
mod tests {
    use super::*;
    use glam::U64Vec2;

    extern crate test;

    #[bench]
    fn time_per_ray(b: &mut test::Bencher) {
        let camera = Camera {
            dimensions: U64Vec2::new(5, 5),
            ..Camera::default()
        };
    
        let sphere = Sphere {
            pos: Vec3::new(0.0, 0.0, -2.0),
            radius: 1.0,
        };
        let directional_light = Vec3::new(1.0, 1.0, -0.5).normalize();
    
        for ray in camera.iter_rays() {
            b.iter(|| {
                if let Some(t) = sphere.intersect(&ray) {
                    let hit_point = ray.origin + (ray.direction * t);
                    let normal = (hit_point - sphere.pos).normalize();
                    let light_intensity = normal.dot(directional_light).max(0.0);
                    test::black_box(light_intensity); // assume it will be used
                }
            });
        }
    }
}
