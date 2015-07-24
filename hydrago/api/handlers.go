package api

import (
    "log"
    "net/http"
	"encoding/json"

    "github.com/CenturyLinkLabs/hydra/hydrago/alert"
)

func UpDown(am alert.AlertManager, w http.ResponseWriter, r *http.Request) {
	status := map[string]string{"status": "up"}
	json.NewEncoder(w).Encode(status)
}

func ReceiveAlert(am alert.AlertManager, w http.ResponseWriter, r *http.Request) {
    pan := &alert.PrometheusAlertNotification{}
    jd := json.NewDecoder(r.Body)
    if err := jd.Decode(pan); err != nil {
        log.Fatal(err)
    }

    dr, err := am.HandleAlert(*pan)
    if err != nil {
        log.Fatal(err)
    }

    drj, errr := json.Marshal(dr)
    if errr != nil {
        log.Fatal(errr)
    }

    w.WriteHeader(http.StatusCreated)
    _, err = w.Write(drj)
    if err != nil {
        log.Fatal(err)
    }
}
