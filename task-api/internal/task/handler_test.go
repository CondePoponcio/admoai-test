package task

import (
    "bytes"
    "encoding/json"
    "io"
    "net/http"
    "net/http/httptest"
    "testing"

    "github.com/gorilla/mux"
)

func setupRouter() *mux.Router {
    svc := NewService()
    h := &Handler{Service: svc}
    r := mux.NewRouter()
    h.RegisterRoutes(r)
    return r
}

func TestCreateAndGetTaskHandler(t *testing.T) {
    r := setupRouter()

    // Crear
    payload := `{"title":"xyz","priority":"high"}`
    req := httptest.NewRequest("POST", "/tasks", bytes.NewBufferString(payload))
    req.Header.Set("Content-Type", "application/json")
    rec := httptest.NewRecorder()
    r.ServeHTTP(rec, req)

    if rec.Code != http.StatusCreated {
        t.Fatalf("esperaba 201 Created, got %d", rec.Code)
    }
    var out Task
    body, _ := io.ReadAll(rec.Body)
    json.Unmarshal(body, &out)
    if out.ID == "" {
        t.Error("ID vacío en respuesta")
    }

    // Obtener
    req2 := httptest.NewRequest("GET", "/tasks/"+out.ID, nil)
    rec2 := httptest.NewRecorder()
    r.ServeHTTP(rec2, req2)
    if rec2.Code != http.StatusOK {
        t.Fatalf("esperaba 200 OK, got %d", rec2.Code)
    }
}

func TestCreateTask_InvalidPayload(t *testing.T) {
    r := setupRouter()
    req := httptest.NewRequest("POST", "/tasks", bytes.NewBufferString(`{"bad": "data"}`))
    req.Header.Set("Content-Type", "application/json")
    rec := httptest.NewRecorder()
    r.ServeHTTP(rec, req)

    if rec.Code != http.StatusBadRequest {
        t.Errorf("esperaba 400 Bad Request, got %d", rec.Code)
    }
    if rec.Body.String() == "" {
        t.Error("esperaba mensaje de error en el body")
    }
}
