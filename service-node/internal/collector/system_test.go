package collector

import (
	"testing"

	"github.com/google/uuid"
	"github.com/pulse-server/service-node/internal/models"
)

func TestParseSections(t *testing.T) {
	output := `===CPU===
1234 567 890 1000 100 50 25
4
===MEMORY===
MemTotal: 16384000
MemFree: 8192000
MemAvailable: 10240000
===LOAD===
0.50 0.75 0.80
`

	sections := parseSections(output)

	if len(sections) != 3 {
		t.Errorf("expected 3 sections, got %d", len(sections))
	}

	if _, ok := sections["CPU"]; !ok {
		t.Error("expected CPU section")
	}

	if _, ok := sections["MEMORY"]; !ok {
		t.Error("expected MEMORY section")
	}

	if _, ok := sections["LOAD"]; !ok {
		t.Error("expected LOAD section")
	}
}

func TestParseCPUMetrics(t *testing.T) {
	data := `1000 100 500 8000 200 50 50
8`

	metrics := parseCPUMetrics(data)

	if metrics.CoreCount != 8 {
		t.Errorf("expected 8 cores, got %d", metrics.CoreCount)
	}

	// Total = 1000 + 100 + 500 + 8000 + 200 + 50 + 50 = 9900
	// Idle = 8000
	// Usage = (9900 - 8000) / 9900 * 100 ≈ 19.19%
	if metrics.UsagePercent < 19 || metrics.UsagePercent > 20 {
		t.Errorf("expected usage around 19%%, got %.2f%%", metrics.UsagePercent)
	}

	if metrics.IdlePercent < 80 || metrics.IdlePercent > 81 {
		t.Errorf("expected idle around 80%%, got %.2f%%", metrics.IdlePercent)
	}
}

func TestParseMemoryMetrics(t *testing.T) {
	data := `MemTotal: 16000000
MemFree: 4000000
MemAvailable: 8000000
Buffers: 500000
Cached: 2000000
SwapTotal: 8000000
SwapFree: 6000000`

	metrics := parseMemoryMetrics(data)

	// Values are in KB, converted to bytes
	expectedTotal := uint64(16000000 * 1024)
	if metrics.TotalBytes != expectedTotal {
		t.Errorf("expected total %d, got %d", expectedTotal, metrics.TotalBytes)
	}

	// Used = Total - Free - Buffers - Cached
	// = 16000000 - 4000000 - 500000 - 2000000 = 9500000 KB
	expectedUsed := uint64(9500000 * 1024)
	if metrics.UsedBytes != expectedUsed {
		t.Errorf("expected used %d, got %d", expectedUsed, metrics.UsedBytes)
	}

	// Swap used = 8000000 - 6000000 = 2000000 KB
	expectedSwapUsed := uint64(2000000 * 1024)
	if metrics.SwapUsedBytes != expectedSwapUsed {
		t.Errorf("expected swap used %d, got %d", expectedSwapUsed, metrics.SwapUsedBytes)
	}
}

func TestParseDiskMetrics(t *testing.T) {
	data := `/dev/sda1 100000000000 40000000000 60000000000 40% /
/dev/sdb1 500000000000 200000000000 300000000000 40% /data
tmpfs 1000000000 0 1000000000 0% /dev/shm`

	disks := parseDiskMetrics(data)

	// Should skip tmpfs
	if len(disks) != 2 {
		t.Errorf("expected 2 disks, got %d", len(disks))
	}

	if disks[0].Device != "/dev/sda1" {
		t.Errorf("expected device /dev/sda1, got %s", disks[0].Device)
	}

	if disks[0].MountPoint != "/" {
		t.Errorf("expected mount point /, got %s", disks[0].MountPoint)
	}

	if disks[0].TotalBytes != 100000000000 {
		t.Errorf("expected total 100000000000, got %d", disks[0].TotalBytes)
	}
}

func TestParseNetworkMetrics(t *testing.T) {
	data := `eth0 1000000 10000 5 2 2000000 20000 3 1
lo 500000 5000 0 0 500000 5000 0 0
wlan0 800000 8000 10 5 1600000 16000 8 4`

	networks := parseNetworkMetrics(data)

	// Should skip lo (loopback)
	if len(networks) != 2 {
		t.Errorf("expected 2 networks, got %d", len(networks))
	}

	if networks[0].Interface != "eth0" {
		t.Errorf("expected interface eth0, got %s", networks[0].Interface)
	}

	if networks[0].BytesRecv != 1000000 {
		t.Errorf("expected bytes recv 1000000, got %d", networks[0].BytesRecv)
	}

	if networks[0].BytesSent != 2000000 {
		t.Errorf("expected bytes sent 2000000, got %d", networks[0].BytesSent)
	}
}

func TestParseLoadMetrics(t *testing.T) {
	data := "0.50 0.75 0.90"

	load := parseLoadMetrics(data)

	if load.Load1 != 0.50 {
		t.Errorf("expected load1 0.50, got %f", load.Load1)
	}

	if load.Load5 != 0.75 {
		t.Errorf("expected load5 0.75, got %f", load.Load5)
	}

	if load.Load15 != 0.90 {
		t.Errorf("expected load15 0.90, got %f", load.Load15)
	}
}

func TestParseUptime(t *testing.T) {
	data := "86400"

	uptime := parseUptime(data)

	if uptime != 86400 {
		t.Errorf("expected uptime 86400, got %d", uptime)
	}
}

func TestToMetricBatch(t *testing.T) {
	serverID := uuid.New()
	sm := &models.SystemMetrics{
		ServerID: serverID,
		CPU: models.CPUMetrics{
			UsagePercent: 50.0,
			CoreCount:    4,
		},
		Memory: models.MemoryMetrics{
			UsagePercent: 60.0,
			TotalBytes:   16000000000,
		},
		Disks: []models.DiskMetrics{
			{Device: "/dev/sda1", MountPoint: "/", UsagePercent: 40.0},
		},
		Network: []models.NetworkMetrics{
			{Interface: "eth0", BytesSent: 1000000, BytesRecv: 2000000},
		},
		LoadAverage: models.LoadAverageMetrics{
			Load1: 0.5, Load5: 0.7, Load15: 0.9,
		},
		Uptime: 86400,
	}

	metrics := ToMetricBatch(sm)

	// Should have: 6 CPU + 5 Memory + 3 Disk + 4 Network + 4 System = 22 metrics
	if len(metrics) < 20 {
		t.Errorf("expected at least 20 metrics, got %d", len(metrics))
	}

	// Verify all metrics have the correct server ID
	for _, m := range metrics {
		if m.ServerID != serverID {
			t.Errorf("expected server ID %s, got %s", serverID, m.ServerID)
		}
	}
}

func TestFormatBytes(t *testing.T) {
	tests := []struct {
		bytes    uint64
		expected string
	}{
		{500, "500 B"},
		{1024, "1.0 KB"},
		{1536, "1.5 KB"},
		{1048576, "1.0 MB"},
		{1073741824, "1.0 GB"},
		{1099511627776, "1.0 TB"},
	}

	for _, tt := range tests {
		result := FormatBytes(tt.bytes)
		if result != tt.expected {
			t.Errorf("FormatBytes(%d) = %s, expected %s", tt.bytes, result, tt.expected)
		}
	}
}
