package task

import (
    "testing"
)

func TestService_CreateAndGet(t *testing.T) {
    svc := NewService()

    // Crear
    task := svc.Create("foo", "high")
    if task.ID == "" {
        t.Fatal("esperaba un ID no vacío")
    }
    if task.Status != "pending" {
        t.Errorf("esperaba status pending, got %s", task.Status)
    }

    // Get
    got, err := svc.Get(task.ID)
    if err != nil {
        t.Fatalf("Get devolvió error: %v", err)
    }
    if got.Title != "foo" {
        t.Errorf("esperaba Title foo, got %s", got.Title)
    }
}

func TestService_Complete(t *testing.T) {
    svc := NewService()
    task := svc.Create("bar", "low")

    // Complete
    if err := svc.Complete(task.ID); err != nil {
        t.Fatalf("Complete devolvió error: %v", err)
    }
    updated, _ := svc.Get(task.ID)
    if updated.Status != "completed" {
        t.Errorf("esperaba status completed, got %s", updated.Status)
    }
    if updated.CompletedAt == nil {
        t.Error("esperaba CompletedAt no-nil después de completar")
    }
}

func TestService_ListByStatus(t *testing.T) {
    svc := NewService()
    a := svc.Create("a", "one")
    b := svc.Create("b", "two")
    svc.Complete(b.ID)

    pendings := svc.ListByStatus("pending")
    if len(pendings) != 1 || pendings[0].ID != a.ID {
        t.Errorf("ListByStatus pending devolvió %v, esperaba [%s]", pendings, a.ID)
    }
}
