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

	fmt.Fprintf(w, "POST request successful")
	ssid := r.FormValue("ssid")
	psk := r.FormValue("psk")
	createWPA(ssid, psk)
	fmt.Fprintf(w, "%s\n", psk)
}

func test() {
	cmd := exec.Command("./enable-wifi.sh")
	err := cmd.Run()
	if err != nil {
		log.Fatalf("cmd.Run() failed with %s\n", err)
	}
}

func createWPA(ssid string, psk string) {
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
