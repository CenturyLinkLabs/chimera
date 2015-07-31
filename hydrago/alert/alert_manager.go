package alert

import (
    "errors"
    "fmt"
    "strings"
    "os"
    "path/filepath"
    "os/exec"
    "strconv"
    "github.com/Sirupsen/logrus")

type promAlertManager struct { }

// MakeAlertManager returns an alertManager.
func MakeAlertManager() AlertManager {
    return promAlertManager{}
}

// HandleAlert handles an Alert, processes it, and sends back an AlertResponse.
func (pam promAlertManager) HandleAlert(pan PrometheusAlertNotification) (AlertResponse, error) {
    var processingStatus string = "failure"
    var newError error
    var err error

    // extract Alert payload from the notification
    if pan.Status == "firing" {
        // process the active Alert
        err = processActiveAlert(pan.Alert)
    } else {
        // process the resolved Alert
        err = processResolvedAlert(pan.Alert)
    }

    if err == nil {
        processingStatus = "success"
    }

    // send response back
    aResponse := AlertResponse{ID:1,
        Name: "Handling_" + pan.Alert[0].Labels.AlertName,
        Status: processingStatus,
        PrometheusAlertNotification: pan,
    }
    if err != nil {
        newError = errors.New(fmt.Sprintf("\nProcessing alert failed: '%s'", err))
    }
    return aResponse, newError
}

func processActiveAlert(alerts []Alert) error {
    var newError, err error

    srvcName, alertName := parseAlert(alerts[0], "Active")

    switch alertName {
        case "container_down":
        err = restartService(srvcName)
        case "container_high_memory_usage", "container_high_cpu_usage":
        err = scaleService(srvcName, true)
    }

    if err != nil {
        newError = errors.New(fmt.Sprintf("\nFailed processing active alert '%s' for service '%s': '%s'", alertName, srvcName, err))
    }
    return newError
}

func processResolvedAlert(alerts []Alert) error {
    var newError, err error

    srvcName, alertName := parseAlert(alerts[0], "Resolved")

    switch alertName {
        case "container_high_memory_usage", "container_high_cpu_usage":
        err = scaleService(srvcName, false)
    }

    if err != nil {
        newError = errors.New(fmt.Sprintf("\nFailed processing resolved alert '%s' for service '%s': '%s'", alertName, srvcName, err))
    }
    return newError
}

func parseAlert(alert Alert, message string) (string, string) {
    srvcName := strings.Split(alert.Summary, " ")[1]
    alertName := alert.Labels.AlertName
    logrus.Debug("\nHandled %s - Service '%s' for Alert '%s'", message, srvcName, alertName)
    return srvcName, alertName
}


func restartService(svcName string) error {
    names := strings.Split(svcName, "_")
    if len(names) < 2 {
        return errors.New(fmt.Sprintf("\nInvalid service name: '%s'", svcName))
    }

    cmd := fmt.Sprintf("eval \"$(docker-machine env --swarm %s)\" && " +
    "cd %s && docker-compose up --no-recreate -d && eval \"$(docker-machine env -u)\"",
    os.Getenv("SWARM_MASTER"), filepath.Join(os.Getenv("APP_BASE_FOLDER"), names[0]))

    _, err := exec.Command("bash", "-c", cmd).Output()

    logrus.Debug("\nrestartService called: Service '%s' with Command '%s'", names[0], cmd)
    logrus.Debug(err)

    if err != nil {
        return err
    }
    return nil
}

func scaleService(svcName string, up bool) error {
    logrus.Debug("\nScaling Service: '%s'", svcName)
    names := strings.Split(svcName, "_")
    if len(names) < 3 {
        return errors.New(fmt.Sprintf("\nInvalid service name: '%s'", svcName))
    }

    cnt, e := strconv.Atoi(names[2])
    if e != nil {
        return e
    }

    if up {
        cnt = cnt + 1
    } else if cnt > 1 {
        cnt = cnt -1
    } else {
        return nil
    }

    cmd := fmt.Sprintf("eval \"$(docker-machine env --swarm %s)\" && " +
    " cd %s &&  docker-compose scale %s=%d && " +
    " eval \"$(docker-machine env -u)\"",
    os.Getenv("SWARM_MASTER"), filepath.Join(os.Getenv("APP_BASE_FOLDER"), names[0]), names[1], cnt)

    _, err := exec.Command("bash", "-c", cmd).Output()

    logrus.Debug("\nScaleService called: App: '%s', Service '%s' for Count: %d with Command '%s' ", names[0], names[1], cnt, cmd)
    logrus.Debug(err)

    if err != nil {
        return err
    }
    return nil
}
