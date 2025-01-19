use crate::{math::{RayInterserct, Vec3}, ray::Ray};

pub struct Sphere {
    pub pos: Vec3,
    pub radius: f32,
}

impl RayInterserct for Sphere {
    fn ray_intersect(&self, ray: &Ray) -> Option<f32> {
        let oc = ray.origin - self.pos;
        let a = ray.direction.dot(&ray.direction);
        let b = 2.0 * oc.dot(&ray.direction);
        let c = oc.dot(&oc) - self.radius * self.radius;
        let discriminant = b * b - 4.0 * a * c;

        if discriminant < 0.0 {
            None
        } else {
            let t1 = (-b - discriminant.sqrt()) / (2.0 * a);
            let t2 = (-b + discriminant.sqrt()) / (2.0 * a);
            if t1 > 0.0 {
                Some(t1)
            } else if t2 > 0.0 {
                Some(t2)
            } else {
                None
            }
        }
    }
}