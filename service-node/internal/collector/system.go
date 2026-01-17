// Package collector provides metric collection functionality.
package collector

import (
	"bufio"
	"fmt"
	"strconv"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/pulse-server/service-node/internal/models"
)

// SystemCollector collects system metrics from command output.
type SystemCollector struct{}

// NewSystemCollector creates a new SystemCollector.
func NewSystemCollector() *SystemCollector {
	return &SystemCollector{}
}

// ParseSystemMetrics parses system metrics from various command outputs.
// This is designed to work with output from remote SSH commands.
func (c *SystemCollector) ParseSystemMetrics(serverID uuid.UUID, output string) (*models.SystemMetrics, error) {
	metrics := &models.SystemMetrics{
		Timestamp: time.Now().UTC(),
		ServerID:  serverID,
	}

	// The output should contain sections separated by markers
	sections := parseSections(output)

	// Parse each section
	if cpu, ok := sections["CPU"]; ok {
		metrics.CPU = parseCPUMetrics(cpu)
	}
	if mem, ok := sections["MEMORY"]; ok {
		metrics.Memory = parseMemoryMetrics(mem)
	}
	if disk, ok := sections["DISK"]; ok {
		metrics.Disks = parseDiskMetrics(disk)
	}
	if net, ok := sections["NETWORK"]; ok {
		metrics.Network = parseNetworkMetrics(net)
	}
	if load, ok := sections["LOAD"]; ok {
		metrics.LoadAverage = parseLoadMetrics(load)
	}
	if uptime, ok := sections["UPTIME"]; ok {
		metrics.Uptime = parseUptime(uptime)
	}

	return metrics, nil
}

// GetCollectionScript returns the bash script to collect system metrics.
func (c *SystemCollector) GetCollectionScript() string {
	return `#!/bin/bash
set -e

echo "===CPU==="
# CPU usage from /proc/stat
head -1 /proc/stat | awk '{print $2,$3,$4,$5,$6,$7,$8}'
# CPU cores
nproc

echo "===MEMORY==="
# Memory from /proc/meminfo
grep -E '^(MemTotal|MemFree|MemAvailable|Buffers|Cached|SwapTotal|SwapFree):' /proc/meminfo | awk '{print $1,$2}'

echo "===DISK==="
# Disk usage
df -P -B1 | tail -n +2 | awk '{print $1,$2,$3,$4,$5,$6}'

echo "===NETWORK==="
# Network stats
cat /proc/net/dev | tail -n +3 | awk '{gsub(/:/, "", $1); print $1,$2,$3,$4,$5,$10,$11,$12,$13}'

echo "===LOAD==="
# Load average
cat /proc/loadavg | awk '{print $1,$2,$3}'

echo "===UPTIME==="
# Uptime in seconds
cat /proc/uptime | awk '{print int($1)}'
`
}

// parseSections splits output into named sections.
func parseSections(output string) map[string]string {
	sections := make(map[string]string)
	var currentSection string
	var currentContent strings.Builder

	scanner := bufio.NewScanner(strings.NewReader(output))
	for scanner.Scan() {
		line := scanner.Text()
		if strings.HasPrefix(line, "===") && strings.HasSuffix(line, "===") {
			if currentSection != "" {
				sections[currentSection] = strings.TrimSpace(currentContent.String())
			}
			currentSection = strings.Trim(line, "=")
			currentContent.Reset()
		} else if currentSection != "" {
			currentContent.WriteString(line + "\n")
		}
	}
	if currentSection != "" {
		sections[currentSection] = strings.TrimSpace(currentContent.String())
	}

	return sections
}

// parseCPUMetrics parses CPU metrics from /proc/stat output.
func parseCPUMetrics(data string) models.CPUMetrics {
	lines := strings.Split(strings.TrimSpace(data), "\n")
	if len(lines) < 2 {
		return models.CPUMetrics{}
	}

	// First line: user nice system idle iowait irq softirq
	fields := strings.Fields(lines[0])
	if len(fields) < 7 {
		return models.CPUMetrics{}
	}

	user, _ := strconv.ParseFloat(fields[0], 64)
	nice, _ := strconv.ParseFloat(fields[1], 64)
	system, _ := strconv.ParseFloat(fields[2], 64)
	idle, _ := strconv.ParseFloat(fields[3], 64)
	iowait, _ := strconv.ParseFloat(fields[4], 64)
	irq, _ := strconv.ParseFloat(fields[5], 64)
	softirq, _ := strconv.ParseFloat(fields[6], 64)

	total := user + nice + system + idle + iowait + irq + softirq
	if total == 0 {
		total = 1 // Prevent division by zero
	}

	coreCount, _ := strconv.Atoi(strings.TrimSpace(lines[1]))

	return models.CPUMetrics{
		UsagePercent:  100.0 * (total - idle) / total,
		UserPercent:   100.0 * (user + nice) / total,
		SystemPercent: 100.0 * system / total,
		IdlePercent:   100.0 * idle / total,
		IOWaitPercent: 100.0 * iowait / total,
		CoreCount:     coreCount,
	}
}

// parseMemoryMetrics parses memory metrics from /proc/meminfo output.
func parseMemoryMetrics(data string) models.MemoryMetrics {
	metrics := models.MemoryMetrics{}
	
	lines := strings.Split(data, "\n")
	values := make(map[string]uint64)

	for _, line := range lines {
		fields := strings.Fields(line)
		if len(fields) >= 2 {
			key := strings.TrimSuffix(fields[0], ":")
			val, _ := strconv.ParseUint(fields[1], 10, 64)
			values[key] = val * 1024 // Convert from KB to bytes
		}
	}

	metrics.TotalBytes = values["MemTotal"]
	metrics.FreeBytes = values["MemFree"]
	metrics.AvailableBytes = values["MemAvailable"]
	
	// Calculate used memory (accounting for buffers/cache)
	buffers := values["Buffers"]
	cached := values["Cached"]
	metrics.UsedBytes = metrics.TotalBytes - metrics.FreeBytes - buffers - cached
	
	if metrics.TotalBytes > 0 {
		metrics.UsagePercent = 100.0 * float64(metrics.UsedBytes) / float64(metrics.TotalBytes)
	}

	metrics.SwapTotalBytes = values["SwapTotal"]
	swapFree := values["SwapFree"]
	if metrics.SwapTotalBytes > 0 {
		metrics.SwapUsedBytes = metrics.SwapTotalBytes - swapFree
		metrics.SwapPercent = 100.0 * float64(metrics.SwapUsedBytes) / float64(metrics.SwapTotalBytes)
	}

	return metrics
}

// parseDiskMetrics parses disk metrics from df output.
func parseDiskMetrics(data string) []models.DiskMetrics {
	var disks []models.DiskMetrics

	lines := strings.Split(data, "\n")
	for _, line := range lines {
		fields := strings.Fields(line)
		if len(fields) < 6 {
			continue
		}

		// Skip pseudo filesystems
		device := fields[0]
		if strings.HasPrefix(device, "tmpfs") || 
		   strings.HasPrefix(device, "devtmpfs") ||
		   strings.HasPrefix(device, "overlay") ||
		   strings.HasPrefix(device, "shm") {
			continue
		}

		total, _ := strconv.ParseUint(fields[1], 10, 64)
		used, _ := strconv.ParseUint(fields[2], 10, 64)
		free, _ := strconv.ParseUint(fields[3], 10, 64)

		var usagePercent float64
		if total > 0 {
			usagePercent = 100.0 * float64(used) / float64(total)
		}

		disks = append(disks, models.DiskMetrics{
			Device:       device,
			MountPoint:   fields[5],
			TotalBytes:   total,
			UsedBytes:    used,
			FreeBytes:    free,
			UsagePercent: usagePercent,
		})
	}

	return disks
}

// parseNetworkMetrics parses network metrics from /proc/net/dev output.
func parseNetworkMetrics(data string) []models.NetworkMetrics {
	var networks []models.NetworkMetrics

	lines := strings.Split(data, "\n")
	for _, line := range lines {
		fields := strings.Fields(line)
		if len(fields) < 9 {
			continue
		}

		iface := fields[0]
		// Skip loopback
		if iface == "lo" {
			continue
		}

		bytesRecv, _ := strconv.ParseUint(fields[1], 10, 64)
		packetsRecv, _ := strconv.ParseUint(fields[2], 10, 64)
		errorsIn, _ := strconv.ParseUint(fields[3], 10, 64)
		dropsIn, _ := strconv.ParseUint(fields[4], 10, 64)
		bytesSent, _ := strconv.ParseUint(fields[5], 10, 64)
		packetsSent, _ := strconv.ParseUint(fields[6], 10, 64)
		errorsOut, _ := strconv.ParseUint(fields[7], 10, 64)
		dropsOut, _ := strconv.ParseUint(fields[8], 10, 64)

		networks = append(networks, models.NetworkMetrics{
			Interface:   iface,
			BytesRecv:   bytesRecv,
			BytesSent:   bytesSent,
			PacketsRecv: packetsRecv,
			PacketsSent: packetsSent,
			ErrorsIn:    errorsIn,
			ErrorsOut:   errorsOut,
			DropsIn:     dropsIn,
			DropsOut:    dropsOut,
		})
	}

	return networks
}

// parseLoadMetrics parses load average from /proc/loadavg output.
func parseLoadMetrics(data string) models.LoadAverageMetrics {
	fields := strings.Fields(strings.TrimSpace(data))
	if len(fields) < 3 {
		return models.LoadAverageMetrics{}
	}

	load1, _ := strconv.ParseFloat(fields[0], 64)
	load5, _ := strconv.ParseFloat(fields[1], 64)
	load15, _ := strconv.ParseFloat(fields[2], 64)

	return models.LoadAverageMetrics{
		Load1:  load1,
		Load5:  load5,
		Load15: load15,
	}
}

// parseUptime parses uptime in seconds.
func parseUptime(data string) int64 {
	uptime, _ := strconv.ParseInt(strings.TrimSpace(data), 10, 64)
	return uptime
}

// ToMetricBatch converts SystemMetrics to a batch of individual metrics.
func ToMetricBatch(sm *models.SystemMetrics) []models.Metric {
	var metrics []models.Metric
	t := sm.Timestamp

	// CPU metrics
	metrics = append(metrics,
		models.Metric{Time: t, ServerID: sm.ServerID, MetricType: models.MetricTypeCPU, MetricName: "usage_percent", Value: sm.CPU.UsagePercent},
		models.Metric{Time: t, ServerID: sm.ServerID, MetricType: models.MetricTypeCPU, MetricName: "user_percent", Value: sm.CPU.UserPercent},
		models.Metric{Time: t, ServerID: sm.ServerID, MetricType: models.MetricTypeCPU, MetricName: "system_percent", Value: sm.CPU.SystemPercent},
		models.Metric{Time: t, ServerID: sm.ServerID, MetricType: models.MetricTypeCPU, MetricName: "idle_percent", Value: sm.CPU.IdlePercent},
		models.Metric{Time: t, ServerID: sm.ServerID, MetricType: models.MetricTypeCPU, MetricName: "iowait_percent", Value: sm.CPU.IOWaitPercent},
		models.Metric{Time: t, ServerID: sm.ServerID, MetricType: models.MetricTypeCPU, MetricName: "core_count", Value: float64(sm.CPU.CoreCount)},
	)

	// Memory metrics
	metrics = append(metrics,
		models.Metric{Time: t, ServerID: sm.ServerID, MetricType: models.MetricTypeMemory, MetricName: "usage_percent", Value: sm.Memory.UsagePercent},
		models.Metric{Time: t, ServerID: sm.ServerID, MetricType: models.MetricTypeMemory, MetricName: "total_bytes", Value: float64(sm.Memory.TotalBytes)},
		models.Metric{Time: t, ServerID: sm.ServerID, MetricType: models.MetricTypeMemory, MetricName: "used_bytes", Value: float64(sm.Memory.UsedBytes)},
		models.Metric{Time: t, ServerID: sm.ServerID, MetricType: models.MetricTypeMemory, MetricName: "available_bytes", Value: float64(sm.Memory.AvailableBytes)},
		models.Metric{Time: t, ServerID: sm.ServerID, MetricType: models.MetricTypeMemory, MetricName: "swap_percent", Value: sm.Memory.SwapPercent},
	)

	// Disk metrics
	for _, disk := range sm.Disks {
		tags := map[string]string{
			"device":      disk.Device,
			"mount_point": disk.MountPoint,
		}
		metrics = append(metrics,
			models.Metric{Time: t, ServerID: sm.ServerID, MetricType: models.MetricTypeDisk, MetricName: "usage_percent", Value: disk.UsagePercent, Tags: tags},
			models.Metric{Time: t, ServerID: sm.ServerID, MetricType: models.MetricTypeDisk, MetricName: "total_bytes", Value: float64(disk.TotalBytes), Tags: tags},
			models.Metric{Time: t, ServerID: sm.ServerID, MetricType: models.MetricTypeDisk, MetricName: "used_bytes", Value: float64(disk.UsedBytes), Tags: tags},
		)
	}

	// Network metrics
	for _, net := range sm.Network {
		tags := map[string]string{"interface": net.Interface}
		metrics = append(metrics,
			models.Metric{Time: t, ServerID: sm.ServerID, MetricType: models.MetricTypeNetwork, MetricName: "bytes_sent", Value: float64(net.BytesSent), Tags: tags},
			models.Metric{Time: t, ServerID: sm.ServerID, MetricType: models.MetricTypeNetwork, MetricName: "bytes_recv", Value: float64(net.BytesRecv), Tags: tags},
			models.Metric{Time: t, ServerID: sm.ServerID, MetricType: models.MetricTypeNetwork, MetricName: "packets_sent", Value: float64(net.PacketsSent), Tags: tags},
			models.Metric{Time: t, ServerID: sm.ServerID, MetricType: models.MetricTypeNetwork, MetricName: "packets_recv", Value: float64(net.PacketsRecv), Tags: tags},
		)
	}

	// Load average
	metrics = append(metrics,
		models.Metric{Time: t, ServerID: sm.ServerID, MetricType: models.MetricTypeSystem, MetricName: "load1", Value: sm.LoadAverage.Load1},
		models.Metric{Time: t, ServerID: sm.ServerID, MetricType: models.MetricTypeSystem, MetricName: "load5", Value: sm.LoadAverage.Load5},
		models.Metric{Time: t, ServerID: sm.ServerID, MetricType: models.MetricTypeSystem, MetricName: "load15", Value: sm.LoadAverage.Load15},
		models.Metric{Time: t, ServerID: sm.ServerID, MetricType: models.MetricTypeSystem, MetricName: "uptime_seconds", Value: float64(sm.Uptime)},
	)

	return metrics
}

// FormatBytes formats bytes into human-readable format.
func FormatBytes(bytes uint64) string {
	const unit = 1024
	if bytes < unit {
		return fmt.Sprintf("%d B", bytes)
	}
	div, exp := uint64(unit), 0
	for n := bytes / unit; n >= unit; n /= unit {
		div *= unit
		exp++
	}
	return fmt.Sprintf("%.1f %cB", float64(bytes)/float64(div), "KMGTPE"[exp])
}
