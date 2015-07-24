package alert

// PrometheusAlertNotification represents an alert notification from Prometheus.
type PrometheusAlertNotification struct {
	Version		string	`json:"version"`
	Status		string	`json:"status"`
	Alert		[]Alert	`json:"alert,omitempty"`
}

type Alert struct {
	Summary 	string	`json:"summary"`
	Description	string	`json:"description"`
	Labels		Labels	`json:"labels,omitempty"`
	Payload		Payload	`json:"payload,omitempty"`
}
type Labels struct {
	AlertName	string `json:"alertname"`
}

type Payload struct {
	ActiveSince 	string	`json:"activeSince"`
	AlertingRule	string	`json:"alertingRule"`
	GeneratorUrl	string	`json:"generatorURL"`
	Value			string	`json:"value"`
}

// An AlertManager is responsible for coordinating Prometheus alerts sent to it.
type AlertManager interface {
	HandleAlert(PrometheusAlertNotification) (AlertResponse, error)
}

// AlertResponse is the minimal representation of an Alert
// typically used for listings, etc.
type AlertResponse struct {
	ID		int     `json:"id"`
	Name	string  `json:"name"`
	Status	string	`json:"status"`
	PrometheusAlertNotification	PrometheusAlertNotification `json:"promAlertNotification,omitempty"`
}
