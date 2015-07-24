package api

import (
	"log"
	"fmt"
	"net/http"

	"github.com/CenturyLinkLabs/hydra/hydrago/alert"
	"github.com/gorilla/mux"
)

type insecureServer struct {
	Manager alert.AlertManager
}

// MakeInsecureServer returns a new Server instance containing a manager to which it will defer work.
func MakeInsecureServer(am alert.AlertManager) Server {
	return insecureServer{
		Manager: am,
	}
}

func (s insecureServer) Start(port string) {
	r := s.newRouter()

	log.Printf("Server running on port: %s", port)
	portString := fmt.Sprintf(":%s", port)
	log.Fatal(http.ListenAndServe(portString, r))
}

func (s insecureServer) newRouter() *mux.Router {
	return newRouter(s.Manager, s.isAuthenticated)
}

func (s insecureServer) isAuthenticated(r *http.Request) bool {
	return true
}
