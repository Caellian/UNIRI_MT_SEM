use crate::math::Vec3;
use nalgebra::Vector2;

pub struct Ray {
    pub origin: Vec3,
    pub direction: Vec3,
    pub target: Option<Vector2<u32>>,
}
