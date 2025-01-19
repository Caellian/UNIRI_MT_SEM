use nalgebra::{Matrix3, Matrix4, Vector2, Vector3, Vector4};
use crate::ray::Ray;

pub type Vec2 = Vector2<f32>;
pub type Vec3 = Vector3<f32>;
pub type Vec4 = Vector4<f32>;

pub type Mat3 = Matrix3<f32>;
pub type Mat4 = Matrix4<f32>;

pub trait RayInterserct {
    fn ray_intersect(&self, ray: &Ray) -> Option<f32>;
}
