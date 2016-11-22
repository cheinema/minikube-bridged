# minikube-bridged

Ziel des Projektes ist der Betrieb von [minikube](https://github.com/kubernetes/minikube "minikube") in [VirtualBox](https://www.virtualbox.org/) unter Windows mit einem überbrückten Netzwerk in ein öffentliches WLAN statt NAT über LAN oder VPN des Hosts.  

## Hintergrund

Minikube basiert auf [docker-machine](https://github.com/docker/machine). Beim Aufbau der VM für VirtualBox werden zwei Netzwerkadapter eingerichtet:

* NAT für den Zugriff der VM auf externe Ressourcen wie Internet. Der Netzwerkverkehr wird über die Standardverbindung des Hosts per [NAT](https://de.wikipedia.org/wiki/Netzwerkadress%C3%BCbersetzung) weitergeleitet.
* Host-only-Adapter für den Zugriff des Hosts auf die VM.

Möglicherweise ist es aus Sicherheitsgründen nicht zulässig, dass solche VMs die Standardverbindung des Hosts per NAT nutzen. Damit sind potentiell Ressourcen im Intranet über LAN oder VPN erreichbar. Andererseits soll die VM trotzdem noch auf Internet zugreifen können. Bei Verfügbarkeit einer weiteren physischen Netzwerkverbindung per WLAN (ohne Intranetanbindung) kann die NAT-Verbindung auf ein überbrückten Netzwerk ("Bridged") umgestellt werden. Die Überbrückung erfolgt dabei von der VM zum WLAN hin. Die VM erscheint damit wie ein weiterer Host im WLAN und ist auch darüber von außerhalb erreichbar.

Minikube (genauer `docker-machine`) konfiguriert in VirtualBox eine Portweiterleitung für den SSH-Zugriff der VM. Es wird dabei ein freier Port auf `localhost` gewählt, welche auf den SSH-Port 22 der VM weiterleitet. Der Mechanismus wird vermutlich verwendet, damit bei wechselnder IP-Adresse der VM (DHCP!) ein fester Zugriffspunkt vorhanden ist. Der SSH-Zugriff wird beim Hochfahren von Minikube benötigt. Es werden darüber Konfigurationen der VM vorgenommen. Außerdem basieren etliche Kommandos wie `minikube ip`, `minikube ssh` und `minikube dashboard` darauf.

Unglücklicherweise ist die Portweiterleitung durch VirtualBox nur in Verbindung mit NAT möglich. Bei einer Umstellung auf eine Netzwerkbrücke muss die Portweiterleitung extern realisiert werden, damit die bekannten Werkzeuge weiterhin verwendet werden können. Das vorliegende Projekt bietet dafür ein Lösung.

## Voraussetzungen
* VirtualBox ist installiert.
* [minikube](https://github.com/kubernetes/minikube "minikube") ist installiert und `minikube` per `PATH` erreichbar.
* [Git for Windows](https://git-scm.com/download/win) ist installiert. Dies ist Voraussetzung für die Ausführung der Shell-/Perl-Skripte.
* Es exitsiert eine WLAN-Verbindung mit Internetzugriff.

## Verwendung
Es genügt die Ausführung von `minikube-run.sh` um zu einer laufenden Minikube-VM zu kommen. Falls diese noch nicht existiert, wird sie zunächst angelegt und dabei die Netzwerkkonfiguration angepasst (NAT -> Bridged). Die VM wird gestartet, falls sie existiert, aber gerade nicht läuft. In allen Fällen wird das erforderliche SSH-Port-Forwarding in einem separaten Fenster gestartet. 

## Copyright
* `tcp-proxy2.pl`: Copyright (C) 2011 by Peteris Krumins, [https://github.com/pkrumins/perl-tcp-proxy2](https://github.com/pkrumins/perl-tcp-proxy2)
