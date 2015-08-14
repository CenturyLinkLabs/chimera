package api

import (
	"net/http"
	"github.com/CenturyLinkLabs/chimera/chimerago/alert"
)

type route struct {
	Name        string
	Method      string
	Pattern     string
	HandlerFunc func(alert.AlertManager, http.ResponseWriter, *http.Request)
}

var routes = []route{
	{
		"health",
		"GET",
		"/health",
		UpDown,
	},
	{
		"alert",
		"POST",
		"/alert",
        ReceiveAlert,
	},
}
