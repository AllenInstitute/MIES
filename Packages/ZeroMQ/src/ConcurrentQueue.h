#pragma once

#include <queue>
#include <mutex>

/// Implementation of a multi-consumer/multi-producer queue
///
/// The contention due to locks is deemed acceptable.
///
/// Heavily inspired by
/// https://www.justsoftwaresolutions.co.uk/threading/implementing-a-thread-safe-queue-using-condition-variables.html
template <typename T>
class ConcurrentQueue
{
  using Lock = std::unique_lock<std::mutex>;

public:
  void push(T data)
  {
    Lock lock(m_mutex);

    m_queue.emplace(data);
  }

  bool empty() const
  {
    Lock lock(m_mutex);

    return m_queue.empty();
  }

  bool try_pop(T &popped_value)
  {
    Lock lock(m_mutex);

    if(m_queue.empty())
    {
      return false;
    }

    popped_value = m_queue.front();
    m_queue.pop();

    return true;
  }

  /// Apply the given functor to all elements in the queue
  ///
  /// @tparam F Functor must accept an object of type T
  ///           and *never* throw
  template <typename Functor>
  void apply_to_all(Functor F)
  {
    Lock lock(m_mutex);

    for(; !m_queue.empty();)
    {
      F(m_queue.front());
      m_queue.pop();
    }
  }

private:
  std::queue<T> m_queue;
  mutable std::mutex m_mutex;
};
