package main // import "github.com/CenturyLinkLabs/chimera/chimerago"

import (
	"flag"
	"os"
	"strings"

    "github.com/CenturyLinkLabs/chimera/chimerago/alert"
    "github.com/CenturyLinkLabs/chimera/chimerago/api"
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

	port := os.Getenv("CHIMERA_PORT")

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

