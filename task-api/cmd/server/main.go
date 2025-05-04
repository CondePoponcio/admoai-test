package main

import (
    "log"
    "net/http"
    "time"

    "task-api/internal/task"
    "task-api/pkg/metrics"

    "github.com/gorilla/mux"
)

func main() {
    svc := task.NewService()
    handler := &task.Handler{Service: svc}

    r := mux.NewRouter()
    handler.RegisterRoutes(r)
    metrics.RegisterPrometheusEndpoint(r)

    srv := &http.Server{
        Addr:              ":8080",
        Handler:           r,
        ReadHeaderTimeout: 5 * time.Second,
        IdleTimeout:       120 * time.Second,
    }

    log.Println("Server listening on", srv.Addr)
    if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
        log.Fatalf("server error: %v", err)
    }
}
