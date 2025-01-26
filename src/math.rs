use crate::ray::Ray;

pub trait Intersect<T> {
    type Result;

    fn intersect(&self, other: &T) -> Option<Self::Result>;
}
