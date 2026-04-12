// Two-way traffic light intersection
// Demonstrates: sum types, safety properties, state machines
module traffic_light {
  type Color = Red | Yellow | Green

  var north_south: Color
  var east_west: Color

  action init = all {
    north_south' = Red,
    east_west' = Green,
  }

  // North-South light transitions
  action ns_to_green = all {
    north_south == Red,
    east_west == Red,        // only go green if cross-traffic is red
    north_south' = Green,
    east_west' = east_west,
  }

  action ns_to_yellow = all {
    north_south == Green,
    north_south' = Yellow,
    east_west' = east_west,
  }

  action ns_to_red = all {
    north_south == Yellow,
    north_south' = Red,
    east_west' = east_west,
  }

  // East-West light transitions
  action ew_to_green = all {
    east_west == Red,
    north_south == Red,
    east_west' = Green,
    north_south' = north_south,
  }

  action ew_to_yellow = all {
    east_west == Green,
    east_west' = Yellow,
    north_south' = north_south,
  }

  action ew_to_red = all {
    east_west == Yellow,
    east_west' = Red,
    north_south' = north_south,
  }

  action step = any {
    ns_to_green,
    ns_to_yellow,
    ns_to_red,
    ew_to_green,
    ew_to_yellow,
    ew_to_red,
  }

  // SAFETY: both directions must never be green at the same time
  val no_collision = not(north_south == Green and east_west == Green)

  // Slightly stronger: no two non-red lights at the same time
  val at_most_one_active = not(north_south != Red and east_west != Red)
}
