package api

import (
    "net/http"
	"encoding/json"

    "github.com/CenturyLinkLabs/chimera/chimerago/alert"
    "github.com/Sirupsen/logrus")

func UpDown(am alert.AlertManager, w http.ResponseWriter, r *http.Request) {
	status := map[string]string{"status": "up"}
	json.NewEncoder(w).Encode(status)
}

func ReceiveAlert(am alert.AlertManager, w http.ResponseWriter, r *http.Request) {
    pan := &alert.PrometheusAlertNotification{}
    jd := json.NewDecoder(r.Body)
    if err := jd.Decode(pan); err != nil {
        logrus.Debug(err)
    }

    dr := am.HandleAlert(*pan)

    drj, err := json.Marshal(dr)
    if err != nil {
        logrus.Debug(err)
    }

    w.WriteHeader(http.StatusCreated)
    _, err = w.Write(drj)
    if err != nil {
        logrus.Debug(err)
    }
}
