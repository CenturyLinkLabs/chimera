package alert

import (
    "errors"
    "fmt"
    "strings"
    "os"
    "path/filepath"
    "os/exec"
    "strconv"

    log "github.com/Sirupsen/logrus"
)

type promAlertManager struct { }

// MakeAlertManager returns an alertManager.
func MakeAlertManager() AlertManager {
    return promAlertManager{}
}

// HandleAlert handles an Alert, processes it, and sends back an AlertResponse.
func (pam promAlertManager) HandleAlert(pan PrometheusAlertNotification) []AlertResponse {
    var err error

	alerts := pan.Alert

	aResponses := []AlertResponse{}

    // send response(s) back for each alert
	for i := range alerts {
		var processingStatus string = "failure"

		log.Debugf("Processing Alert: ", alerts[i])

		// extract Alert payload from the notification
		if pan.Status == "firing" {
			// process the active Alert
			err = processActiveAlert(alerts[i])
		} else {
			// process the resolved Alert
			err = processResolvedAlert(alerts[i])
		}

		if err == nil {
			processingStatus = "success"
		}

		aResponses = append(aResponses, AlertResponse{ID:1,
				Name: "Handled alert: '" + alerts[i].Labels.AlertName + "'",
				Status: processingStatus,
				Alert: alerts[i],
			})

		if err != nil {
			log.Error(err)
		}
	}
    return aResponses
}

func processActiveAlert(alert Alert) error {
	var err error

	srvcName, alertName := parseAlert(alert)

	log.Debugf("Processing Active Alert '%s' for Service name '%s'", alertName, srvcName)

	switch alertName {
	case "container_down":
		err = restartService(srvcName)
	case "container_high_memory_usage", "container_high_cpu_usage", "container_high_http_load":
		err = scaleService(srvcName, true)
	}

    return err
}

func processResolvedAlert(alert Alert) error {
    var err error

	srvcName, alertName := parseAlert(alert)

	log.Debugf("Processing Resolved Alert '%s' for Service name '%s'", alertName, srvcName)

	switch alertName {
	case "container_high_memory_usage", "container_high_cpu_usage", "container_high_http_load":
		err = scaleService(srvcName, false)
	}

    return err
}

func parseAlert(alert Alert) (string, string) {
    srvcName := strings.Split(alert.Summary, " ")[1]
    alertName := alert.Labels.AlertName
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

    log.Debugf("restartService called: Service '%s' with Command '%s'", names[0], cmd)

    if err != nil {
        return err
    }
    return nil
}

func scaleService(svcName string, up bool) error {
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

    log.Debugf("scaleService called: App: '%s', Service '%s' for Count: %d with Command '%s' ", names[0], names[1], cnt, cmd)

    if err != nil {
        return err
    }
    return nil
}
