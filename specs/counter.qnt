// A minimal counter -- the "hello world" of Quint
// Demonstrates: state variables, actions, invariants, init/step
module counter {
  var count: int

  action init = {
    count' = 0
  }

  action increment = {
    count' = count + 1
  }

  action decrement = all {
    count > 0,              // guard: only decrement if positive
    count' = count - 1,
  }

  action step = any {
    increment,
    decrement,
  }

  // Invariant: count should never go negative
  val non_negative = count >= 0

  // Invariant: count should stay below some bound (will this hold?)
  val bounded = count < 5
}
