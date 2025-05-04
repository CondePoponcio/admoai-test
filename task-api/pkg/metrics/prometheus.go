package metrics

import (
    "github.com/gorilla/mux"
    "github.com/prometheus/client_golang/prometheus/promhttp"
)

// Ahora recibimos *mux.Router en lugar de *http.ServeMux
func RegisterPrometheusEndpoint(r *mux.Router) {
    // Registramos /metrics directamente sobre el router de gorilla/mux
    r.Handle("/metrics", promhttp.Handler())
}
