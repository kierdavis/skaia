package main

import (
	"fmt"
	"gopkg.in/yaml.v2"
	"math/rand"
	"net/http"
	"os"
)

const (
	mediaFile   = "/secret/media.yaml"
	tlsCertFile = "/secret/origin.crt"
	tlsKeyFile  = "/secret/origin.key"
)

func main() {
	err := app()
	if err != nil {
		fmt.Fprintln(os.Stderr, err.Error())
		writeTerminationMessage(err.Error())
		os.Exit(1)
	} else {
		writeTerminationMessage("ok")
		os.Exit(0)
	}
}

func writeTerminationMessage(msg string) {
	f, err := os.Create("/dev/termination-log")
	if err != nil {
		fmt.Fprintf(os.Stderr, "warning: failed to open /dev/termination-log: %s\n", err.Error())
		return
	}
	defer f.Close()
	_, err = fmt.Fprint(f, msg)
	if err != nil {
		fmt.Fprintf(os.Stderr, "warning: failed to write to /dev/termination-log: %s\n", err.Error())
	}
}

func app() error {
	media, err := loadMedia()
	if err != nil {
		return fmt.Errorf("failed to load media: %w", err)
	}
	handler := httpHandler{media: media}
	err = http.ListenAndServeTLS(":443", tlsCertFile, tlsKeyFile, handler)
	return fmt.Errorf("failed to serve HTTPS: %w", err)
}

func loadMedia() (items []mediaItem, err error) {
	f, err := os.Open(mediaFile)
	if err != nil {
		return nil, fmt.Errorf("failed to open %s: %w", mediaFile, err)
	}
	defer f.Close()
	err = yaml.NewDecoder(f).Decode(&items)
	if err != nil {
		return nil, fmt.Errorf("failed to parse %s: %w", mediaFile, err)
	}
	return items, nil
}

type mediaItem struct {
	Id       string `yaml:"id"`
	Redirect string `yaml:"redirect"`
}

type httpHandler struct {
	media []mediaItem
}

func (h httpHandler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	if r.Method != "GET" {
		http.Error(w, "Method not allowed.", http.StatusMethodNotAllowed)
		return
	}
	item := h.chooseItem()
	w.Header().Set("Location", item.Redirect)
	w.WriteHeader(http.StatusMovedPermanently)
}

func (h httpHandler) chooseItem() mediaItem {
	return h.media[rand.Intn(len(h.media))]
}
