package main

import (
	"log"
	"net/http"
)

type loggingHttpHandler struct {
	http.Handler
}

func (h loggingHttpHandler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	ww := loggingResponseWriter{
		ResponseWriter: w,
		statusCode:     http.StatusOK,
	}
	h.Handler.ServeHTTP(&ww, r)
	log.Printf("%s : %s %s -> %d %s", r.Header.Get("X-Forwarded-For"), r.Method, r.URL.String(), ww.statusCode, ww.Header().Get("Location"))
}

type loggingResponseWriter struct {
	http.ResponseWriter
	statusCode int
}

func (w *loggingResponseWriter) WriteHeader(statusCode int) {
	w.statusCode = statusCode
	w.ResponseWriter.WriteHeader(statusCode)
}
