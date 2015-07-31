package main // import "github.com/CenturyLinkLabs/hydra/hydrago"

import (
	"flag"
	"os"
    "github.com/CenturyLinkLabs/hydra/hydrago/alert"
    "github.com/CenturyLinkLabs/hydra/hydrago/api"
)

func main() {
    am := alert.MakeAlertManager()
	s := api.MakeServer(am)
	s.Start(serverPort())
}

func serverPort() string {
	var portFlag string
	flag.StringVar(&portFlag, "p", "", "port on which the server will run")

	port := os.Getenv("HYDRA_PORT")

	if port == "" {
		flag.Parse()
		port = portFlag
	}

	if port == "" {
		// use the default port
		port = "8888"
	}
	return port
}
