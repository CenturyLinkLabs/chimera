package api

import (
    "log"
    "net/http"
    "github.com/CenturyLinkLabs/hydra/hydrago/alert"
    "encoding/json")

func HandleAlert(am alert.Manager, w http.ResponseWriter, r *http.Request) {
    alert := &alert.Alert{}
    jd := json.NewDecoder(r.Body)
    if err := jd.Decode(alert); err != nil {
        log.Fatal(err)
    }

    dr, err := am.HandleAlert(*alert)
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
