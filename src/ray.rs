use crate::{math::Intersect, shape::Sphere};
use glam::{U64Vec2, Vec3};

pub struct Ray {
    pub origin: Vec3,
    pub direction: Vec3,
    pub source: Option<U64Vec2>,
}

impl Intersect<Ray> for Sphere {
    type Result = f32;

    fn intersect(&self, ray: &Ray) -> Option<f32> {
        let direction = ray.origin - self.pos;
        let ray_magnitude_squared = ray.direction.length_squared();
        let alignment = 2.0 * direction.dot(ray.direction);
        let max_travel = direction.length_squared() - self.radius * self.radius;
        let discriminant_squared = alignment * alignment - 4.0 * ray_magnitude_squared * max_travel;

        if discriminant_squared > 0.0 {
            let discriminant = discriminant_squared.sqrt();
            let t1 = (-alignment - discriminant) / (2.0 * ray_magnitude_squared);
            if t1 > 0.0 {
                return Some(t1)
            }
            let t2 = (-alignment + discriminant) / (2.0 * ray_magnitude_squared);
            if t2 > 0.0 {
                return Some(t2)
            }
        }

        None
    }
}
