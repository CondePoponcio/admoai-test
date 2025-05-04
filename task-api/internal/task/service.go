package task

import (
    "errors"
    "sync"
    "time"

    "github.com/google/uuid"
)

type Service struct {
    tasks map[string]*Task
    mu    sync.RWMutex
}

func NewService() *Service {
    return &Service{tasks: make(map[string]*Task)}
}

func (s *Service) Create(title, priority string) *Task {
    s.mu.Lock()
    defer s.mu.Unlock()
    id := uuid.New().String()
    task := &Task{
        ID:        id,
        Title:     title,
        Priority:  priority,
        Status:    "pending",
        CreatedAt: time.Now(),
    }
    s.tasks[id] = task
    return task
}

func (s *Service) Get(id string) (*Task, error) {
    s.mu.RLock()
    defer s.mu.RUnlock()
    task, ok := s.tasks[id]
    if !ok {
        return nil, errors.New("task not found")
    }
    return task, nil
}

func (s *Service) Complete(id string) error {
    s.mu.Lock()
    defer s.mu.Unlock()
    task, ok := s.tasks[id]
    if !ok {
        return errors.New("task not found")
    }
    now := time.Now()
    task.Status = "completed"
    task.CompletedAt = &now
    return nil
}

func (s *Service) ListByStatus(status string) []*Task {
    s.mu.RLock()
    defer s.mu.RUnlock()
    var result []*Task
    for _, task := range s.tasks {
        if task.Status == status {
            result = append(result, task)
        }
    }
    return result
}
