package alert

import (
    "errors")

type alertManager struct { }

// MakeAlertManager returns an alertManager.
func MakeAlertManager() Manager {
    return alertManager{}
}

// CreateAlert handles an Alert and either restarts containers or scales containers as needed.
func (am alertManager) HandleAlert(a Alert) (AlertResponse, error) {
    return AlertResponse{}, errors.New("Not Implemented")
}

func ExecDockerMachineCommand() error {
    return errors.New("Not Implemented")
}
