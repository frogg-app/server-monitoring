// Package collector provides Docker container collection functionality.
package collector

import (
	"bufio"
	"encoding/json"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/pulse-server/service-node/internal/models"
)

// DockerCollector collects Docker container information.
type DockerCollector struct{}

// NewDockerCollector creates a new DockerCollector.
func NewDockerCollector() *DockerCollector {
	return &DockerCollector{}
}

// GetContainerListScript returns the command to list containers.
func (c *DockerCollector) GetContainerListScript() string {
	return `docker ps -a --format '{{json .}}'`
}

// GetContainerStatsScript returns the command to get container stats.
func (c *DockerCollector) GetContainerStatsScript() string {
	return `docker stats --no-stream --format '{{json .}}'`
}

// GetContainerInspectScript returns the command to inspect a container.
func (c *DockerCollector) GetContainerInspectScript(containerID string) string {
	return `docker inspect ` + containerID
}

// GetContainerLogsScript returns the command to get container logs.
func (c *DockerCollector) GetContainerLogsScript(containerID string, tail int) string {
	if tail <= 0 {
		tail = 100
	}
	return `docker logs --tail ` + itoa(tail) + ` ` + containerID
}

// GetImagesScript returns the command to list images.
func (c *DockerCollector) GetImagesScript() string {
	return `docker images --format '{{json .}}'`
}

// GetNetworksScript returns the command to list networks.
func (c *DockerCollector) GetNetworksScript() string {
	return `docker network ls --format '{{json .}}'`
}

// GetVolumesScript returns the command to list volumes.
func (c *DockerCollector) GetVolumesScript() string {
	return `docker volume ls --format '{{json .}}'`
}

// GetActionScript returns the command to perform an action on a container.
func (c *DockerCollector) GetActionScript(containerID string, action models.ContainerAction) string {
	switch action {
	case models.ActionStart:
		return `docker start ` + containerID
	case models.ActionStop:
		return `docker stop ` + containerID
	case models.ActionRestart:
		return `docker restart ` + containerID
	case models.ActionPause:
		return `docker pause ` + containerID
	case models.ActionUnpause:
		return `docker unpause ` + containerID
	case models.ActionKill:
		return `docker kill ` + containerID
	case models.ActionRemove:
		return `docker rm -f ` + containerID
	default:
		return ""
	}
}

// ParseContainerList parses the output of docker ps.
func (c *DockerCollector) ParseContainerList(serverID uuid.UUID, output string) ([]models.Container, error) {
	var containers []models.Container

	scanner := bufio.NewScanner(strings.NewReader(output))
	for scanner.Scan() {
		line := strings.TrimSpace(scanner.Text())
		if line == "" {
			continue
		}

		var raw struct {
			ID         string `json:"ID"`
			Names      string `json:"Names"`
			Image      string `json:"Image"`
			Command    string `json:"Command"`
			CreatedAt  string `json:"CreatedAt"`
			State      string `json:"State"`
			Status     string `json:"Status"`
			Ports      string `json:"Ports"`
			Labels     string `json:"Labels"`
			Networks   string `json:"Networks"`
			Mounts     string `json:"Mounts"`
		}

		if err := json.Unmarshal([]byte(line), &raw); err != nil {
			continue // Skip invalid lines
		}

		container := models.Container{
			ID:       raw.ID,
			ServerID: serverID,
			Name:     strings.TrimPrefix(raw.Names, "/"),
			Image:    raw.Image,
			Command:  raw.Command,
			State:    parseContainerState(raw.State),
			Status:   raw.Status,
		}

		// Parse created time
		if t, err := time.Parse("2006-01-02 15:04:05 -0700 MST", raw.CreatedAt); err == nil {
			container.Created = t
		}

		// Parse ports
		container.Ports = parsePorts(raw.Ports)

		// Parse labels
		container.Labels = parseLabels(raw.Labels)

		// Parse networks
		if raw.Networks != "" {
			container.Networks = strings.Split(raw.Networks, ",")
		}

		containers = append(containers, container)
	}

	return containers, nil
}

// ParseContainerStats parses the output of docker stats.
func (c *DockerCollector) ParseContainerStats(output string) ([]models.ContainerStats, error) {
	var stats []models.ContainerStats

	scanner := bufio.NewScanner(strings.NewReader(output))
	for scanner.Scan() {
		line := strings.TrimSpace(scanner.Text())
		if line == "" {
			continue
		}

		var raw struct {
			ID        string `json:"ID"`
			Name      string `json:"Name"`
			CPUPerc   string `json:"CPUPerc"`
			MemUsage  string `json:"MemUsage"`
			MemPerc   string `json:"MemPerc"`
			NetIO     string `json:"NetIO"`
			BlockIO   string `json:"BlockIO"`
			PIDs      string `json:"PIDs"`
		}

		if err := json.Unmarshal([]byte(line), &raw); err != nil {
			continue
		}

		stat := models.ContainerStats{
			ContainerID: raw.ID,
			Name:        strings.TrimPrefix(raw.Name, "/"),
			Timestamp:   time.Now().UTC(),
		}

		// Parse CPU percentage
		stat.CPUPercent = parsePercent(raw.CPUPerc)

		// Parse memory usage and percentage
		stat.MemoryUsage, stat.MemoryLimit = parseMemoryUsage(raw.MemUsage)
		stat.MemoryPercent = parsePercent(raw.MemPerc)

		// Parse network I/O
		stat.NetworkRx, stat.NetworkTx = parseIO(raw.NetIO)

		// Parse block I/O
		stat.BlockRead, stat.BlockWrite = parseIO(raw.BlockIO)

		// Parse PIDs
		stat.PIDs = atoi(strings.TrimSpace(raw.PIDs))

		stats = append(stats, stat)
	}

	return stats, nil
}

// ParseImages parses the output of docker images.
func (c *DockerCollector) ParseImages(serverID uuid.UUID, output string) ([]models.DockerImage, error) {
	var images []models.DockerImage

	scanner := bufio.NewScanner(strings.NewReader(output))
	for scanner.Scan() {
		line := strings.TrimSpace(scanner.Text())
		if line == "" {
			continue
		}

		var raw struct {
			ID         string `json:"ID"`
			Repository string `json:"Repository"`
			Tag        string `json:"Tag"`
			CreatedAt  string `json:"CreatedAt"`
			Size       string `json:"Size"`
		}

		if err := json.Unmarshal([]byte(line), &raw); err != nil {
			continue
		}

		image := models.DockerImage{
			ID:       raw.ID,
			ServerID: serverID,
			Size:     parseSize(raw.Size),
		}

		// Build repo tag
		if raw.Repository != "<none>" {
			tag := raw.Tag
			if tag == "<none>" {
				tag = "latest"
			}
			image.RepoTags = []string{raw.Repository + ":" + tag}
		}

		// Parse created time
		if t, err := time.Parse("2006-01-02 15:04:05 -0700 MST", raw.CreatedAt); err == nil {
			image.Created = t
		}

		images = append(images, image)
	}

	return images, nil
}

// parseContainerState converts a string to ContainerState.
func parseContainerState(state string) models.ContainerState {
	switch strings.ToLower(state) {
	case "running":
		return models.ContainerRunning
	case "paused":
		return models.ContainerPaused
	case "restarting":
		return models.ContainerRestarting
	case "exited":
		return models.ContainerExited
	case "dead":
		return models.ContainerDead
	case "created":
		return models.ContainerCreated
	default:
		return models.ContainerExited
	}
}

// parsePorts parses port bindings string.
func parsePorts(portsStr string) []models.PortBinding {
	if portsStr == "" {
		return nil
	}

	var ports []models.PortBinding
	parts := strings.Split(portsStr, ", ")

	for _, part := range parts {
		port := models.PortBinding{}

		// Format: 0.0.0.0:8080->80/tcp or 80/tcp
		if strings.Contains(part, "->") {
			// Has host binding
			arrow := strings.Index(part, "->")
			hostPart := part[:arrow]
			containerPart := part[arrow+2:]

			// Parse host IP and port
			if strings.Contains(hostPart, ":") {
				lastColon := strings.LastIndex(hostPart, ":")
				port.IP = hostPart[:lastColon]
				port.PublicPort = atoi(hostPart[lastColon+1:])
			}

			// Parse container port and protocol
			if strings.Contains(containerPart, "/") {
				slash := strings.Index(containerPart, "/")
				port.PrivatePort = atoi(containerPart[:slash])
				port.Type = containerPart[slash+1:]
			}
		} else {
			// Only container port
			if strings.Contains(part, "/") {
				slash := strings.Index(part, "/")
				port.PrivatePort = atoi(part[:slash])
				port.Type = part[slash+1:]
			}
		}

		if port.PrivatePort > 0 {
			ports = append(ports, port)
		}
	}

	return ports
}

// parseLabels parses labels string.
func parseLabels(labelsStr string) map[string]string {
	if labelsStr == "" {
		return nil
	}

	labels := make(map[string]string)
	parts := strings.Split(labelsStr, ",")

	for _, part := range parts {
		if eq := strings.Index(part, "="); eq > 0 {
			key := strings.TrimSpace(part[:eq])
			value := strings.TrimSpace(part[eq+1:])
			labels[key] = value
		}
	}

	return labels
}

// parsePercent parses a percentage string like "25.5%".
func parsePercent(s string) float64 {
	s = strings.TrimSuffix(strings.TrimSpace(s), "%")
	return parseFloat(s)
}

// parseMemoryUsage parses memory usage string like "100MiB / 1GiB".
func parseMemoryUsage(s string) (uint64, uint64) {
	parts := strings.Split(s, " / ")
	if len(parts) != 2 {
		return 0, 0
	}
	return parseByteSize(strings.TrimSpace(parts[0])), parseByteSize(strings.TrimSpace(parts[1]))
}

// parseIO parses I/O string like "100MB / 50MB".
func parseIO(s string) (uint64, uint64) {
	parts := strings.Split(s, " / ")
	if len(parts) != 2 {
		return 0, 0
	}
	return parseByteSize(strings.TrimSpace(parts[0])), parseByteSize(strings.TrimSpace(parts[1]))
}

// parseByteSize parses a byte size string like "100MB", "1.5GiB", etc.
func parseByteSize(s string) uint64 {
	s = strings.ToUpper(strings.TrimSpace(s))

	multipliers := map[string]uint64{
		"B":   1,
		"KB":  1000,
		"KIB": 1024,
		"MB":  1000 * 1000,
		"MIB": 1024 * 1024,
		"GB":  1000 * 1000 * 1000,
		"GIB": 1024 * 1024 * 1024,
		"TB":  1000 * 1000 * 1000 * 1000,
		"TIB": 1024 * 1024 * 1024 * 1024,
	}

	for suffix, mult := range multipliers {
		if strings.HasSuffix(s, suffix) {
			numStr := strings.TrimSuffix(s, suffix)
			num := parseFloat(numStr)
			return uint64(num * float64(mult))
		}
	}

	return uint64(parseFloat(s))
}

// parseSize parses a size string from docker images output.
func parseSize(s string) int64 {
	return int64(parseByteSize(s))
}

// parseFloat parses a float string, returning 0 on error.
func parseFloat(s string) float64 {
	s = strings.TrimSpace(s)
	var f float64
	for i, c := range s {
		if c >= '0' && c <= '9' {
			f = f*10 + float64(c-'0')
		} else if c == '.' {
			// Parse decimal part
			decimal := 0.1
			for _, d := range s[i+1:] {
				if d >= '0' && d <= '9' {
					f += float64(d-'0') * decimal
					decimal /= 10
				} else {
					break
				}
			}
			break
		} else {
			break
		}
	}
	return f
}

// atoi converts string to int, returning 0 on error.
func atoi(s string) int {
	var n int
	for _, c := range s {
		if c >= '0' && c <= '9' {
			n = n*10 + int(c-'0')
		} else {
			break
		}
	}
	return n
}

// itoa converts int to string.
func itoa(n int) string {
	if n == 0 {
		return "0"
	}
	var digits []byte
	for n > 0 {
		digits = append([]byte{byte('0' + n%10)}, digits...)
		n /= 10
	}
	return string(digits)
}
