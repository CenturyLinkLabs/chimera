package main

import (
    "github.com/CenturyLinkLabs/hydra/hydrago/alert"
    "github.com/CenturyLinkLabs/hydra/hydrago/api"
    "os"
)

func main() {
    am := alert.MakeAlertManager()
    s := makeServer(am)
    s.Start(serverPort())
}

func makeServer(dm alert.Manager) api.Server {
    return api.MakeInsecureServer(dm)
}

func serverPort() string {
    p := os.Getenv("SERVER_PORT")
    if p == "" {
        p = "3000"
    }
    return ":" + p
}