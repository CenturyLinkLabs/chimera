package alert

import (
	"errors"
	"fmt"
	"log"
)

type promAlertManager struct { }

// MakeAlertManager returns an alertManager.
func MakeAlertManager() AlertManager {
    return promAlertManager{}
}

// HandleAlert handles an Alert, processes it, and sends back an AlertResponse.
func (pam promAlertManager) HandleAlert(pan PrometheusAlertNotification) (AlertResponse, error) {
	var processingStatus string
	var newError error
	var err error

	// extract Alert payload from the notification
	if pan.Status == "firing" {
		// process the active Alert
		processingStatus, err = ProcessActiveAlert(pan.Alert)
	} else {
		// process the resolved Alert
		processingStatus, err = ProcessResolvedAlert(pan.Alert)
	}

	// send response back
	aResponse := AlertResponse{	ID:1,
								Name: "TestResponse",
								Status: processingStatus,
								PrometheusAlertNotification: pan,
							  }
	if err != nil {
		newError = errors.New(fmt.Sprintf("Processing alert failed: %s", err))
	}
    return aResponse, newError
}

func ProcessActiveAlert(alerts []Alert) (string, error) {
	ParseAlert(alerts[0], "Active")
	return "success", nil
}

func ProcessResolvedAlert(alerts []Alert) (string, error) {
	ParseAlert(alerts[0], "Resolved")
	return "success", nil
}

func ParseAlert(alert Alert, message string) (string, error) {
	parseStr := fmt.Sprintf("%s - Alert: %s\t%s\t%s\t%s\t%s\t%s\t%s", message, alert.Summary, alert.Description, alert.Labels.AlertName, alert.Payload.ActiveSince, alert.Payload.AlertingRule, alert.Payload.GeneratorUrl, alert.Payload.Value)
	log.Printf(parseStr)
	return "success", nil
}

func ExecDockerMachineCommand() error {
    return errors.New("Not Implemented")
}
