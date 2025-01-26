use glam::Vec3;
use serde::Deserialize;

#[derive(Debug, Clone, Copy, PartialEq, Deserialize)]
pub struct Material {
    metalness: f32,
    /// Index of Refraction
    ior: f32,
    transmission_color: Vec3,
    /// Dispersion Abbe
    /// 
    /// Abbe number, also known as the Vd-number or constringence of a
    /// transparent material, is an approximate measure of the material's
    /// dispersion (change of refractive index versus wavelength), with high
    /// values of Vd indicating low dispersion.
    dispersion_abbe: f32
}

impl Default for Material {
    fn default() -> Self {
        Self {
            metalness: 0.0,
            ior: 1.0,
            transmission_color: Vec3::new(1.0, 1.0, 1.0),
            dispersion_abbe: Default::default()
        }
    }
}