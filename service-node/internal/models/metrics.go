package models

import (
	"time"

	"github.com/google/uuid"
)

// MetricType represents the type of metric being collected.
type MetricType string

const (
	MetricTypeCPU     MetricType = "cpu"
	MetricTypeMemory  MetricType = "memory"
	MetricTypeDisk    MetricType = "disk"
	MetricTypeNetwork MetricType = "network"
	MetricTypeProcess MetricType = "process"
	MetricTypeSystem  MetricType = "system"
)

// Metric represents a single metric data point.
type Metric struct {
	Time       time.Time         `json:"time"`
	ServerID   uuid.UUID         `json:"server_id"`
	MetricType MetricType        `json:"metric_type"`
	MetricName string            `json:"metric_name"`
	Value      float64           `json:"value"`
	Tags       map[string]string `json:"tags,omitempty"`
}

// MetricBatch is a collection of metrics to be inserted together.
type MetricBatch struct {
	Metrics []Metric `json:"metrics"`
}

// SystemMetrics represents collected system metrics from a host.
type SystemMetrics struct {
	Timestamp   time.Time `json:"timestamp"`
	ServerID    uuid.UUID `json:"server_id"`
	CPU         CPUMetrics         `json:"cpu"`
	Memory      MemoryMetrics      `json:"memory"`
	Disks       []DiskMetrics      `json:"disks"`
	Network     []NetworkMetrics   `json:"network"`
	LoadAverage LoadAverageMetrics `json:"load_average"`
	Uptime      int64              `json:"uptime"` // seconds
}

// CPUMetrics represents CPU usage metrics.
type CPUMetrics struct {
	UsagePercent float64   `json:"usage_percent"`
	UserPercent  float64   `json:"user_percent"`
	SystemPercent float64  `json:"system_percent"`
	IdlePercent  float64   `json:"idle_percent"`
	IOWaitPercent float64  `json:"iowait_percent,omitempty"`
	CoreCount    int       `json:"core_count"`
	PerCore      []float64 `json:"per_core,omitempty"`
}

// MemoryMetrics represents memory usage metrics.
type MemoryMetrics struct {
	TotalBytes     uint64  `json:"total_bytes"`
	UsedBytes      uint64  `json:"used_bytes"`
	FreeBytes      uint64  `json:"free_bytes"`
	AvailableBytes uint64  `json:"available_bytes"`
	UsagePercent   float64 `json:"usage_percent"`
	SwapTotalBytes uint64  `json:"swap_total_bytes"`
	SwapUsedBytes  uint64  `json:"swap_used_bytes"`
	SwapPercent    float64 `json:"swap_percent"`
}

// DiskMetrics represents disk usage metrics.
type DiskMetrics struct {
	Device       string  `json:"device"`
	MountPoint   string  `json:"mount_point"`
	FSType       string  `json:"fs_type"`
	TotalBytes   uint64  `json:"total_bytes"`
	UsedBytes    uint64  `json:"used_bytes"`
	FreeBytes    uint64  `json:"free_bytes"`
	UsagePercent float64 `json:"usage_percent"`
	InodesTotal  uint64  `json:"inodes_total,omitempty"`
	InodesUsed   uint64  `json:"inodes_used,omitempty"`
	InodesFree   uint64  `json:"inodes_free,omitempty"`
}

// NetworkMetrics represents network interface metrics.
type NetworkMetrics struct {
	Interface    string `json:"interface"`
	BytesSent    uint64 `json:"bytes_sent"`
	BytesRecv    uint64 `json:"bytes_recv"`
	PacketsSent  uint64 `json:"packets_sent"`
	PacketsRecv  uint64 `json:"packets_recv"`
	ErrorsIn     uint64 `json:"errors_in"`
	ErrorsOut    uint64 `json:"errors_out"`
	DropsIn      uint64 `json:"drops_in"`
	DropsOut     uint64 `json:"drops_out"`
}

// LoadAverageMetrics represents system load averages.
type LoadAverageMetrics struct {
	Load1  float64 `json:"load1"`
	Load5  float64 `json:"load5"`
	Load15 float64 `json:"load15"`
}

// ProcessInfo represents information about a running process.
type ProcessInfo struct {
	PID          int     `json:"pid"`
	Name         string  `json:"name"`
	User         string  `json:"user"`
	CPUPercent   float64 `json:"cpu_percent"`
	MemoryPercent float64 `json:"memory_percent"`
	MemoryRSS    uint64  `json:"memory_rss"` // bytes
	Status       string  `json:"status"`
	StartTime    int64   `json:"start_time"` // unix timestamp
	Command      string  `json:"command"`
}

// MetricQuery represents a query for metrics.
type MetricQuery struct {
	ServerID   uuid.UUID  `json:"server_id"`
	MetricType MetricType `json:"metric_type"`
	MetricName string     `json:"metric_name,omitempty"`
	StartTime  time.Time  `json:"start_time"`
	EndTime    time.Time  `json:"end_time"`
	Interval   string     `json:"interval,omitempty"` // e.g., "1m", "5m", "1h"
}

// MetricSeries represents a time series of metric values.
type MetricSeries struct {
	MetricType MetricType            `json:"metric_type"`
	MetricName string                `json:"metric_name"`
	Tags       map[string]string     `json:"tags,omitempty"`
	DataPoints []MetricDataPoint     `json:"data_points"`
}

// MetricDataPoint represents a single point in a time series.
type MetricDataPoint struct {
	Time  time.Time `json:"time"`
	Value float64   `json:"value"`
}
