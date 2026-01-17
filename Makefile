# Pulse Server Monitoring - Makefile
#
# Common commands for development and testing

.PHONY: help build up down logs test test-unit test-integration clean

# Default target
help:
	@echo "Pulse Server Monitoring"
	@echo ""
	@echo "Usage: make <target>"
	@echo ""
	@echo "Targets:"
	@echo "  build            Build all Docker images"
	@echo "  up               Start all services"
	@echo "  down             Stop all services"
	@echo "  logs             Tail all service logs"
	@echo "  test             Run all tests (unit + integration)"
	@echo "  test-unit        Run Go unit tests"
	@echo "  test-integration Run integration tests"
	@echo "  clean            Remove containers and volumes"
	@echo ""

# Build all Docker images
build:
	docker compose build

# Start all services
up:
	docker compose up -d
	@echo ""
	@echo "Services starting..."
	@sleep 5
	@docker compose ps
	@echo ""
	@echo "Web app: http://localhost:$$(docker compose port web 80 | cut -d: -f2)"
	@echo "API:     http://localhost:$$(docker compose port api 8080 | cut -d: -f2)"

# Stop all services
down:
	docker compose down

# Tail logs
logs:
	docker compose logs -f

# Run all tests
test: test-unit test-integration

# Run Go unit tests
test-unit:
	@echo "Running Go unit tests..."
	cd service-node && go test -v ./...

# Run integration tests
test-integration:
	@echo "Running integration tests..."
	@WEB_PORT=$$(docker compose port web 80 2>/dev/null | cut -d: -f2 || echo ""); \
	API_PORT=$$(docker compose port api 8080 2>/dev/null | cut -d: -f2 || echo "8080"); \
	if [ -n "$$WEB_PORT" ]; then \
		python3 tests/integration_test.py --api-url http://localhost:$$API_PORT --web-url http://localhost:$$WEB_PORT; \
	else \
		python3 tests/integration_test.py --api-url http://localhost:$$API_PORT; \
	fi

# Clean up
clean:
	docker compose down -v --remove-orphans
	rm -rf service-node/bin
	rm -rf app/build
