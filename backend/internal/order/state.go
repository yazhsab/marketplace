package order

// validTransitions defines the allowed state transitions for an order.
// Each key is the current status, and the value is a slice of statuses
// the order is allowed to move to from that state.
var validTransitions = map[string][]string{
	"pending":          {"confirmed", "cancelled"},
	"confirmed":        {"preparing", "cancelled"},
	"preparing":        {"ready", "cancelled"},
	"ready":            {"assigned", "out_for_delivery"},
	"assigned":         {"out_for_delivery", "cancelled"},
	"out_for_delivery": {"delivered"},
	"delivered":        {"refunded"},
	"cancelled":        {},
	"refunded":         {},
}

// CanTransition reports whether moving from the current status to the
// target status is a valid state transition.
func CanTransition(from, to string) bool {
	allowed, ok := validTransitions[from]
	if !ok {
		return false
	}
	for _, s := range allowed {
		if s == to {
			return true
		}
	}
	return false
}

// IsTerminal reports whether the given status is a terminal state
// (i.e., no further transitions are possible).
func IsTerminal(status string) bool {
	allowed, ok := validTransitions[status]
	if !ok {
		return false
	}
	return len(allowed) == 0
}
