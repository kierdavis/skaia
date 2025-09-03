pub use std::convert::Infallible as Never;

#[derive(Clone, Copy, Debug, Eq, Hash, PartialEq)]
pub enum MaybeReady<T> {
  NotReady,
  Ready(T),
}

impl<T> MaybeReady<T> {
  pub fn as_mut(&mut self) -> MaybeReady<&mut T> {
    match *self {
      Self::NotReady => MaybeReady::NotReady,
      Self::Ready(ref mut val) => MaybeReady::Ready(val),
    }
  }

  pub fn insert_default_if_not_ready(&mut self) -> &mut T
  where
    T: Default,
  {
    if matches!(*self, Self::NotReady) {
      *self = Self::Ready(T::default());
    }
    self.as_mut().unwrap_ready()
  }

  pub fn unwrap_ready(self) -> T {
    match self {
      Self::NotReady => panic!("not ready"),
      Self::Ready(val) => val,
    }
  }
}
