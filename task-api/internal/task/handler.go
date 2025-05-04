package task

import (
    "encoding/json"
    "net/http"

    "github.com/gorilla/mux"
)

type Handler struct {
    Service *Service
}

func (h *Handler) RegisterRoutes(r *mux.Router) {
    r.HandleFunc("/tasks", h.CreateTask).Methods("POST")
    r.HandleFunc("/tasks/{id}", h.GetTask).Methods("GET")
    r.HandleFunc("/tasks/{id}/complete", h.CompleteTask).Methods("POST")
    r.HandleFunc("/tasks", h.ListTasks).Methods("GET").Queries("status", "{status}")
}

func (h *Handler) CreateTask(w http.ResponseWriter, r *http.Request) {
    var input struct {
        Title    string `json:"title"`
        Priority string `json:"priority"`
    }
    if err := json.NewDecoder(r.Body).Decode(&input); err != nil {
        http.Error(w, "invalid JSON payload", http.StatusBadRequest)
        return
    }
    // Validación de campos obligatorios
    if input.Title == "" || input.Priority == "" {
        http.Error(w, "both title and priority are required", http.StatusBadRequest)
        return
    }

    task := h.Service.Create(input.Title, input.Priority)
    w.Header().Set("Content-Type", "application/json")
    w.WriteHeader(http.StatusCreated) // 201 en creación
    json.NewEncoder(w).Encode(task)
}

func (h *Handler) GetTask(w http.ResponseWriter, r *http.Request) {
    id := mux.Vars(r)["id"]
    task, err := h.Service.Get(id)
    if err != nil {
        http.Error(w, err.Error(), http.StatusNotFound)
        return
    }
    w.Header().Set("Content-Type", "application/json")
    json.NewEncoder(w).Encode(task)
}

func (h *Handler) CompleteTask(w http.ResponseWriter, r *http.Request) {
    id := mux.Vars(r)["id"]
    if err := h.Service.Complete(id); err != nil {
        http.Error(w, err.Error(), http.StatusNotFound)
        return
    }
    w.WriteHeader(http.StatusOK)
}

func (h *Handler) ListTasks(w http.ResponseWriter, r *http.Request) {
    status := r.URL.Query().Get("status")
    tasks := h.Service.ListByStatus(status)
    w.Header().Set("Content-Type", "application/json")
    json.NewEncoder(w).Encode(tasks)
}
