package main

import "testing"

func TestUnmarshalOrderFromQueue(t *testing.T) {
	order, err := unmarshalOrderFromQueue([]byte(`{"customerId":"7","items":[{"productId":1,"quantity":2,"price":9.99}]}`))
	if err != nil {
		t.Fatalf("expected no error, got %v", err)
	}
	if order.Status != Pending {
		t.Fatalf("expected Pending status, got %v", order.Status)
	}
	if order.OrderID == "" {
		t.Fatal("expected a non-empty order ID")
	}
	for _, c := range order.OrderID {
		if c < '0' || c > '9' {
			t.Fatalf("expected numeric order ID (Atoi sanitize paths depend on it), got %q", order.OrderID)
		}
	}
	if order.CustomerID != "7" {
		t.Fatalf("expected customer passthrough, got %q", order.CustomerID)
	}
}

func TestUnmarshalOrderFromQueueRejectsGarbage(t *testing.T) {
	if _, err := unmarshalOrderFromQueue([]byte(`{nope`)); err == nil {
		t.Fatal("expected an error for invalid JSON")
	}
	if _, err := unmarshalOrderFromQueue([]byte(`"just a string"`)); err == nil {
		t.Fatal("expected an error for non-object JSON")
	}
}
