package task

import "time"

type Task struct {
    ID          string     `json:"id"`
    Title       string     `json:"title"`
    Priority    string     `json:"priority"`
    Status      string     `json:"status"`
    CreatedAt   time.Time  `json:"created_at"`
    CompletedAt *time.Time `json:"completed_at,omitempty"`
}
