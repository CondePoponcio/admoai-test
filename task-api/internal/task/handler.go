package task

import (
    "encoding/json"
    "log"
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
    log.Println("CreateTask: Received request")
    var input struct {
        Title    string `json:"title"`
        Priority string `json:"priority"`
    }
    if err := json.NewDecoder(r.Body).Decode(&input); err != nil {
        log.Printf("CreateTask: Invalid JSON payload: %v", err)
        http.Error(w, "invalid JSON payload", http.StatusBadRequest)
        return
    }
    if input.Title == "" || input.Priority == "" {
        log.Println("CreateTask: Missing required fields")
        http.Error(w, "both title and priority are required", http.StatusBadRequest)
        return
    }

    task := h.Service.Create(input.Title, input.Priority)
    log.Printf("CreateTask: Task created with ID %s", task.ID)
    w.Header().Set("Content-Type", "application/json")
    w.WriteHeader(http.StatusCreated)
    json.NewEncoder(w).Encode(task)
}

func (h *Handler) GetTask(w http.ResponseWriter, r *http.Request) {
    log.Println("GetTask: Received request")
    id := mux.Vars(r)["id"]
    log.Printf("GetTask: Fetching task with ID %s", id)
    task, err := h.Service.Get(id)
    if err != nil {
        log.Printf("GetTask: Task not found: %v", err)
        http.Error(w, err.Error(), http.StatusNotFound)
        return
    }
    log.Printf("GetTask: Task found with ID %s", id)
    w.Header().Set("Content-Type", "application/json")
    json.NewEncoder(w).Encode(task)
}

func (h *Handler) CompleteTask(w http.ResponseWriter, r *http.Request) {
    log.Println("CompleteTask: Received request")
    id := mux.Vars(r)["id"]
    log.Printf("CompleteTask: Completing task with ID %s", id)
    if err := h.Service.Complete(id); err != nil {
        log.Printf("CompleteTask: Task not found or error: %v", err)
        http.Error(w, err.Error(), http.StatusNotFound)
        return
    }
    log.Printf("CompleteTask: Task with ID %s marked as complete", id)
    w.WriteHeader(http.StatusOK)
}

func (h *Handler) ListTasks(w http.ResponseWriter, r *http.Request) {
    log.Println("ListTasks: Received request")
    status := r.URL.Query().Get("status")
    log.Printf("ListTasks: Listing tasks with status %s", status)
    tasks := h.Service.ListByStatus(status)
    log.Printf("ListTasks: Found %d tasks with status %s", len(tasks), status)
    w.Header().Set("Content-Type", "application/json")
    json.NewEncoder(w).Encode(tasks)
}