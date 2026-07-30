package main

import (
	"fmt"
	"net/http"
)

func main() {
	http.HandleFunc("/summarize", func(w http.ResponseWriter, r *http.Request) {
		o := &Order{Amount: 42}
		fmt.Fprint(w, Summarize(o))
	})
	http.ListenAndServe(":8080", nil)
}
