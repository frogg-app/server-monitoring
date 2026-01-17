package models

import (
	"time"

	"github.com/google/uuid"
)

// ContainerState represents the state of a container.
type ContainerState string

const (
	ContainerRunning    ContainerState = "running"
	ContainerPaused     ContainerState = "paused"
	ContainerRestarting ContainerState = "restarting"
	ContainerExited     ContainerState = "exited"
	ContainerDead       ContainerState = "dead"
	ContainerCreated    ContainerState = "created"
)

// Container represents a Docker container.
type Container struct {
	ID         string         `json:"id"`
	ServerID   uuid.UUID      `json:"server_id"`
	Name       string         `json:"name"`
	Image      string         `json:"image"`
	ImageID    string         `json:"image_id"`
	Command    string         `json:"command"`
	Created    time.Time      `json:"created"`
	State      ContainerState `json:"state"`
	Status     string         `json:"status"`
	Ports      []PortBinding  `json:"ports,omitempty"`
	Labels     map[string]string `json:"labels,omitempty"`
	Mounts     []MountPoint   `json:"mounts,omitempty"`
	Networks   []string       `json:"networks,omitempty"`
}

// PortBinding represents a container port binding.
type PortBinding struct {
	PrivatePort int    `json:"private_port"`
	PublicPort  int    `json:"public_port,omitempty"`
	Type        string `json:"type"` // tcp, udp
	IP          string `json:"ip,omitempty"`
}

// MountPoint represents a container mount.
type MountPoint struct {
	Type        string `json:"type"` // bind, volume, tmpfs
	Source      string `json:"source"`
	Destination string `json:"destination"`
	ReadOnly    bool   `json:"read_only"`
}

// ContainerStats represents container resource statistics.
type ContainerStats struct {
	ContainerID   string    `json:"container_id"`
	Name          string    `json:"name"`
	CPUPercent    float64   `json:"cpu_percent"`
	MemoryUsage   uint64    `json:"memory_usage"`
	MemoryLimit   uint64    `json:"memory_limit"`
	MemoryPercent float64   `json:"memory_percent"`
	NetworkRx     uint64    `json:"network_rx"`
	NetworkTx     uint64    `json:"network_tx"`
	BlockRead     uint64    `json:"block_read"`
	BlockWrite    uint64    `json:"block_write"`
	PIDs          int       `json:"pids"`
	Timestamp     time.Time `json:"timestamp"`
}

// ContainerAction represents an action to perform on a container.
type ContainerAction string

const (
	ActionStart   ContainerAction = "start"
	ActionStop    ContainerAction = "stop"
	ActionRestart ContainerAction = "restart"
	ActionPause   ContainerAction = "pause"
	ActionUnpause ContainerAction = "unpause"
	ActionKill    ContainerAction = "kill"
	ActionRemove  ContainerAction = "remove"
)

// DockerImage represents a Docker image.
type DockerImage struct {
	ID          string    `json:"id"`
	ServerID    uuid.UUID `json:"server_id"`
	RepoTags    []string  `json:"repo_tags"`
	RepoDigests []string  `json:"repo_digests,omitempty"`
	Size        int64     `json:"size"`
	Created     time.Time `json:"created"`
	Labels      map[string]string `json:"labels,omitempty"`
}

// DockerNetwork represents a Docker network.
type DockerNetwork struct {
	ID       string            `json:"id"`
	ServerID uuid.UUID         `json:"server_id"`
	Name     string            `json:"name"`
	Driver   string            `json:"driver"`
	Scope    string            `json:"scope"`
	IPAM     NetworkIPAM       `json:"ipam,omitempty"`
	Options  map[string]string `json:"options,omitempty"`
}

// NetworkIPAM represents IPAM configuration for a network.
type NetworkIPAM struct {
	Driver string     `json:"driver"`
	Config []IPAMPool `json:"config,omitempty"`
}

// IPAMPool represents an IP address pool.
type IPAMPool struct {
	Subnet  string `json:"subnet"`
	Gateway string `json:"gateway,omitempty"`
}

// DockerVolume represents a Docker volume.
type DockerVolume struct {
	Name       string            `json:"name"`
	ServerID   uuid.UUID         `json:"server_id"`
	Driver     string            `json:"driver"`
	Mountpoint string            `json:"mountpoint"`
	Labels     map[string]string `json:"labels,omitempty"`
	Options    map[string]string `json:"options,omitempty"`
	CreatedAt  time.Time         `json:"created_at"`
}

// ComposeStack represents a Docker Compose stack.
type ComposeStack struct {
	Name       string      `json:"name"`
	ServerID   uuid.UUID   `json:"server_id"`
	Status     string      `json:"status"`
	Services   int         `json:"services"`
	Running    int         `json:"running"`
	Containers []Container `json:"containers,omitempty"`
}

// ContainerLogRequest represents a request for container logs.
type ContainerLogRequest struct {
	ContainerID string `json:"container_id"`
	Tail        int    `json:"tail,omitempty"`
	Since       string `json:"since,omitempty"`
	Until       string `json:"until,omitempty"`
	Follow      bool   `json:"follow,omitempty"`
	Timestamps  bool   `json:"timestamps,omitempty"`
}

// ContainerLogs represents container log output.
type ContainerLogs struct {
	ContainerID string   `json:"container_id"`
	Logs        []string `json:"logs"`
}

// ContainerInspect represents detailed container information.
type ContainerInspect struct {
	Container
	HostConfig struct {
		Binds           []string          `json:"binds,omitempty"`
		NetworkMode     string            `json:"network_mode"`
		PortBindings    map[string][]struct {
			HostIP   string `json:"host_ip"`
			HostPort string `json:"host_port"`
		} `json:"port_bindings,omitempty"`
		RestartPolicy struct {
			Name              string `json:"name"`
			MaximumRetryCount int    `json:"maximum_retry_count"`
		} `json:"restart_policy"`
		AutoRemove bool              `json:"auto_remove"`
		Privileged bool              `json:"privileged"`
		Env        []string          `json:"env,omitempty"`
	} `json:"host_config"`
	Config struct {
		Hostname     string            `json:"hostname"`
		User         string            `json:"user,omitempty"`
		Env          []string          `json:"env,omitempty"`
		Cmd          []string          `json:"cmd,omitempty"`
		Entrypoint   []string          `json:"entrypoint,omitempty"`
		WorkingDir   string            `json:"working_dir,omitempty"`
		ExposedPorts map[string]struct{} `json:"exposed_ports,omitempty"`
		Volumes      map[string]struct{} `json:"volumes,omitempty"`
	} `json:"config"`
	NetworkSettings struct {
		IPAddress   string `json:"ip_address"`
		Gateway     string `json:"gateway"`
		MacAddress  string `json:"mac_address"`
		Networks    map[string]struct {
			IPAddress string `json:"ip_address"`
			Gateway   string `json:"gateway"`
		} `json:"networks,omitempty"`
	} `json:"network_settings"`
}
