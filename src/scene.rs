use serde::{Deserialize, Serialize};
use crate::light::DirectionalLight;
use glam::Vec3;

#[derive(Clone, Serialize, Deserialize)]
pub struct Scene {
    directional_lights: Vec<DirectionalLight>,
    ambient_light: Vec3,
}
