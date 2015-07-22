package alert

// Deployment represents a stored deployment.
type Alert struct {
	ID         int
	Name       string
	Template   string
}

// A Manager is responsible for coordinating deployment related use cases.
type Manager interface {
	HandleAlert(Alert) (AlertResponse, error)
}


// AlertResponse is the minimal representation of a Deployment
// typically used for listings, etc.
type AlertResponse struct {
	ID           int      `json:"id"`
	Name         string   `json:"name"`
	ServiceIDs   []string `json:"service_ids"`
}