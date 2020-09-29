package main

import (
	"fmt"
	"log"
	"net/http"
	"os"
	"os/exec"
	"text/template"
)

func formHandler(w http.ResponseWriter, r *http.Request) {
	if err := r.ParseForm(); err != nil {
		fmt.Fprintf(w, "ParseForm() err: %v", err)
		return
	}

	ssid := r.FormValue("ssid")
	psk := r.FormValue("psk")
	createWPAFile(ssid, psk)
	reconfigWifi()
	fmt.Fprintf(w, "<h1>Successfully configured Wifi, rebooting now.</h1><h1>Visit <a href=http://pi-hole.local/admin>http://pi-hole.local/admin</a> to view the application.</h1><br><br><a href=\"/\">Home</a>")
	reboot()
}

func reboot() {
	cmd := exec.Command("sudo", "reboot", "now")
	err := cmd.Run()
	if err != nil {
		log.Fatalf("cmd.Run() failed with %s\n", err)
	}
}

func reconfigWifi() {
	cmd := exec.Command("./enable-wifi.sh")
	err := cmd.Run()
	if err != nil {
		log.Fatalf("cmd.Run() failed with %s\n", err)
	}
}

func createWPAFile(ssid string, psk string) {
	type Creds struct {
		SSID string
		PSK  string
	}
	creds := Creds{ssid, psk}

	wpaTemplate := `country=US
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1
network={
ssid="{{.SSID}}"
psk="{{.PSK}}"
key_mgmt=WPA-PSK
}
`

	tmpl, err := template.New("creds").Parse(wpaTemplate)
	if err != nil {
		panic(err)
	}

	f, err := os.Create("./wpa_supplicant.conf")
	if err != nil {
		log.Println("create file: ", err)
		return
	}
	err = tmpl.Execute(f, creds)
	if err != nil {
		log.Print("execute: ", err)
		return
	}
	f.Close()
}

func main() {
	fileServer := http.FileServer(http.Dir("./static"))
	http.Handle("/", fileServer)
	http.HandleFunc("/form", formHandler)

	fmt.Printf("Starting server at port 8080\n")
	if err := http.ListenAndServe(":8080", nil); err != nil {
		log.Fatal(err)
	}
}
