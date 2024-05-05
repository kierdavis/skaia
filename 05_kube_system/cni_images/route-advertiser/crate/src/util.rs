use futures_util::stream::{FusedStream, Stream};
use pin_project::pin_project;
use std::pin::Pin;
use std::task::{Context, Poll};

pub trait DedupAdjacentStreamExt: Stream {
  fn dedup_adjacent(self) -> DedupAdjacentStream<Self>
  where
    Self: Sized,
  {
    DedupAdjacentStream {
      source: self,
      last: None,
    }
  }
}

impl<S> DedupAdjacentStreamExt for S where S: Stream + ?Sized {}

#[derive(Debug)]
#[pin_project]
pub struct DedupAdjacentStream<S: Stream> {
  #[pin]
  source: S,
  last: Option<S::Item>,
}

impl<S> Stream for DedupAdjacentStream<S>
where
  S: FusedStream,
  S::Item: Clone + Eq,
{
  type Item = S::Item;
  fn poll_next(self: Pin<&mut Self>, cx: &mut Context) -> Poll<Option<Self::Item>> {
    let mut this = self.project();
    while !this.source.is_terminated() {
      match this.source.as_mut().poll_next(cx) {
        Poll::Ready(Some(val)) => match *this.last {
          Some(ref last) if *last == val => {}
          _ => {
            *this.last = Some(val.clone());
            return Poll::Ready(Some(val));
          }
        },
        Poll::Ready(None) => return Poll::Ready(None),
        Poll::Pending => return Poll::Pending,
      }
    }
    Poll::Ready(None)
  }
  fn size_hint(&self) -> (usize, Option<usize>) {
    self.source.size_hint()
  }
}

impl<S> FusedStream for DedupAdjacentStream<S>
where
  S: FusedStream,
  S::Item: Clone + Eq,
{
  fn is_terminated(&self) -> bool {
    self.source.is_terminated()
  }
}
