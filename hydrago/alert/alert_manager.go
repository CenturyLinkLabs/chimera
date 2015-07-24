package alert

import (
    "errors"
    "fmt"
    "log"
    "strings"
    "os"
    "path/filepath"
    "os/exec"
    "strconv")

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
    aResponse := AlertResponse{ID:1,
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
    log.Print(parseStr)
    fmt.Print(parseStr)
    return "success", nil
}


func restartService(svcName string) error {
    names := strings.Split(svcName, "_")
    if len(names) < 2 {
        return errors.New(fmt.Sprintf("Invalid service name: %s", svcName))
    }
    cmd := fmt.Sprintf("eval \"$(docker-machine env --swarm %s)\" && " +
    "cd %s && docker-compose up --no-recreate -d && eval \"$(docker-machine env -u)\"",
    os.Getenv("SWARM_MASTER"), filepath.Join(os.Getenv("APP_BASE_FOLDER"), names[0]))
    _, err := exec.Command("bash", "-c", cmd).Output()
    if err != nil {
        return err
    }
    return nil
}

func scaleService(svcName string, up bool) error {
    names := strings.Split(svcName, "_")
    if len(names) < 3 {
        return errors.New(fmt.Sprintf("Invalid service name: %s", svcName))
    }
    cnt, e := strconv.Atoi(names[2])
    if e != nil {
        return e
    }
    if up {
        cnt = cnt + 1
    } else {
        cnt = cnt -1
    }
    cmd := fmt.Sprintf("eval \"$(docker-machine env --swarm %s)\" && " +
    " cd %s &&  docker-compose scale %s=%d && " +
    " eval \"$(docker-machine env -u)\"",
    os.Getenv("SWARM_MASTER"), filepath.Join(os.Getenv("APP_BASE_FOLDER"), names[0]), names[1], cnt)

    _, err := exec.Command("bash", "-c", cmd).Output()
    if err != nil {
        return err
    }
    return nil
}