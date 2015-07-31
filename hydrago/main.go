package main // import "github.com/CenturyLinkLabs/hydra/hydrago"

import (
	"flag"
	"os"
	"strings"

    "github.com/CenturyLinkLabs/hydra/hydrago/alert"
    "github.com/CenturyLinkLabs/hydra/hydrago/api"
	log "github.com/Sirupsen/logrus"
)

const (
	defaultLogLevel = log.InfoLevel
)

func init() {
	log.SetOutput(os.Stdout)
	log.SetLevel(defaultLogLevel)
}

func main() {
	log.SetLevel(logLevel())

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

func logLevel() log.Level {
	levelString := os.Getenv("LOG_LEVEL")

	if len(levelString) == 0 {
		return defaultLogLevel
	}

	level, err := log.ParseLevel(strings.ToLower(levelString))
	if err != nil {
		log.Errorf("Invalid log level: %s", levelString)
		return defaultLogLevel
	}

	return level
}

