package api // import "github.com/CenturyLinkLabs/chimera/chimerago/api"

import (
	"net/http"
	"time"

	"github.com/gorilla/mux"
	"github.com/CenturyLinkLabs/chimera/chimerago/alert"
	log "github.com/Sirupsen/logrus"
)

// A Server is the HTTP server which responds to API requests.
type Server interface {
	Start(string)
	newRouter() *mux.Router
	isAuthenticated(*http.Request) bool
}

func MakeServer(am alert.AlertManager) Server {
	return MakeInsecureServer(am)
}

func newRouter(am alert.AlertManager, isAuthenticated func(r *http.Request) bool) *mux.Router {
	r := mux.NewRouter()

	for _, route := range routes {
		fct := route.HandlerFunc
		wrap := func(w http.ResponseWriter, r *http.Request) {
			if !isAuthenticated(r) {
				w.WriteHeader(http.StatusUnauthorized)
				return
			}

			// set json header
			w.Header().Set("Content-Type", "application/json; charset=utf-8")

			// log it
			st := time.Now()

			log.Infof(
				"Firing %s\t%s\t%s",
				r.Method,
				r.RequestURI,
				time.Since(st),
			)

			fct(am, w, r)
		}

		r.
			Methods(route.Method).
			Path(route.Pattern).
			Name(route.Name).
			HandlerFunc(wrap)
	}

	return r
}
