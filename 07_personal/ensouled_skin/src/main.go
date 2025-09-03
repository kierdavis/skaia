package main

import (
	"fmt"
	"gopkg.in/yaml.v2"
	"gorm.io/gorm"
	"log"
	"net/http"
	"os"
	"time"
)

const (
	mediaFile   = "/secret/media.yaml"
	tlsCertFile = "/secret/origin.crt"
	tlsKeyFile  = "/secret/origin.key"

	assignmentTTL = time.Hour * 24 * 30
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
	db, err := initDB()
	if err != nil {
		return fmt.Errorf("failed to open database connection: %w", err)
	}
	handler := loggingHttpHandler{httpHandler{media: media, db: db}}
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

type httpHandler struct {
	media []mediaItem
	db    *gorm.DB
}

func (h httpHandler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	if r.Method != "GET" {
		http.Error(w, "Method not allowed.", http.StatusMethodNotAllowed)
		return
	}
	query := r.URL.Query()
	clientFingerprint := query.Get("fp")
	if clientFingerprint == "" {
		serveFingerprinter(w, r)
		return
	}
	h.serveAssignedMedia(w, r, clientFingerprint)
}

func (h httpHandler) serveAssignedMedia(w http.ResponseWriter, r *http.Request, clientFingerprint string) {
	clientAddr := r.Header.Get("X-Forwarded-For")
	db := h.db.WithContext(r.Context())
	item, err := getAssignment(db, h.media, clientAddr, clientFingerprint)
	if err != nil {
		log.Printf("failed to get assignment from database: %w", err)
		item = getRandomMediaItem(h.media)
	}
	h.serveMedia(w, r, item)
}

func (h httpHandler) serveMedia(w http.ResponseWriter, r *http.Request, item mediaItem) {
	if item.Redirect != "" {
		w.Header().Set("Location", item.Redirect)
		w.WriteHeader(http.StatusMovedPermanently)
	} else if item.Text != "" {
		w.Header().Set("Content-Type", "text/plain")
		w.Write([]byte(item.Text))
	} else {
		log.Printf("item '%s' does not have either 'redirect' or 'text' defined; don't know how to serve it", item.Id)
		http.Error(w, "internal server error", http.StatusInternalServerError)
	}
}

func serveFingerprinter(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "text/html")
	w.Write([]byte(`
		<html>
			<head>
				<title>ensouled.skin</title>
				<script>
					import("https://openfpcdn.io/fingerprintjs/v4")
						.then(fjs => fjs.load())
						.then(fp => fp.get())
						.then(result => {
							window.location = "/?fp=" + result.visitorId
						})
				</script>
			</head>
			<body>
			</body>
		</html>
	`))
}
