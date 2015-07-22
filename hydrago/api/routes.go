package api

import (
	"net/http"
)

import "github.com/CenturyLinkLabs/hydra/hydrago/alert"

type route struct {
	Name        string
	Method      string
	Pattern     string
	HandlerFunc func(alert.Manager, http.ResponseWriter, *http.Request)
}

var routes = []route{
	{
		"alert",
		"POST",
		"handlealert",
        HandleAlert,
	},
}