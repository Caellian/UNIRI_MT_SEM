use glam::{Mat3, Vec3, Vec4};
use serde::{Deserialize, Serialize};
use std::{fmt::Display, sync::OnceLock};

/// Light wavelength in nanometers.
#[derive(Debug, Clone, Copy, PartialEq)]
pub struct Wavelength(f32);

impl Display for Wavelength {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{:.02}nm", self.0)
    }
}

/// CIE XYZ color space that's used for intermediate conversion of wavelength
/// for accuracy.
#[derive(Debug, Clone, Copy, PartialEq)]
pub struct CieXyz {
    x: f32,
    y: f32,
    z: f32,
    a: f32,
}

static CIE_CMF: &[[f32; 3]] = include!("./cie-cmf");

impl From<CieXyz> for Vec3 {
    #[inline]
    fn from(value: CieXyz) -> Self {
        Vec3::new(value.x, value.y, value.z)
    }
}
impl From<Vec3> for CieXyz {
    #[inline]
    fn from(value: Vec3) -> Self {
        CieXyz {
            x: value.x,
            y: value.y,
            z: value.z,
            a: 1.,
        }
    }
}
impl From<Vec4> for CieXyz {
    #[inline]
    fn from(value: Vec4) -> Self {
        CieXyz {
            x: value.x,
            y: value.y,
            z: value.z,
            a: value.w,
        }
    }
}
impl From<Wavelength> for CieXyz {
    fn from(value: Wavelength) -> Self {
        if value.0 < 380.0 || value.0 > 777.0 {
            // out of visible light spectrum
            return CieXyz {
                x: 0.,
                y: 0.,
                z: 0.,
                a: 1.,
            };
        }
        let index = (value.0 - 380.).floor() as usize;
        let index_next = (value.0 - 380.).ceil() as usize;
        let a = Vec3::from_array(CIE_CMF[index]);
        let b = Vec3::from_array(CIE_CMF[index_next]);
        let t = value.0 - value.0.floor();
        CieXyz::from(a.lerp(b, t))
    }
}
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct SrgbU8 {
    r: u8,
    g: u8,
    b: u8,
    a: u8,
}
impl From<SrgbU8> for Vec3 {
    fn from(value: SrgbU8) -> Self {
        Vec3::new(
            value.r as f32 / 255.,
            value.g as f32 / 255.,
            value.b as f32 / 255.,
        )
    }
}

#[rustfmt::skip]
static RGB_TO_CIE: Mat3 = Mat3::from_cols_array(&[
    0.4124, 0.2126, 0.0193,
    0.3576, 0.7152, 0.1192,
    0.1805, 0.0722, 0.9505,
]);
#[rustfmt::skip]
static CIE_TO_RGB: Mat3 = Mat3::from_cols_array(&[
     3.2406255, -0.9689307,  0.0557101,
    -1.537208,   1.8757561, -0.2040211,
    -0.4986286,  0.0415175,  1.0569959,
]);

impl From<CieXyz> for SrgbU8 {
    fn from(value: CieXyz) -> Self {
        let result: Vec3 = CIE_TO_RGB * Into::<Vec3>::into(value);
        SrgbU8 {
            r: (result.x * 255.) as u8,
            g: (result.y * 255.) as u8,
            b: (result.z * 255.) as u8,
            a: (value.a * 255.) as u8,
        }
    }
}
impl From<SrgbU8> for CieXyz {
    fn from(value: SrgbU8) -> Self {
        let result: Vec3 = RGB_TO_CIE * Into::<Vec3>::into(value);
        CieXyz {
            x: result.x,
            y: result.y,
            z: result.z,
            a: value.a as f32 / 255.,
        }
    }
}

#[derive(Clone, Serialize, Deserialize)]
pub struct DirectionalLight {
    pub color: Vec3,
}
