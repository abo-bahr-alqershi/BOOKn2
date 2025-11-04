#!/bin/bash

# Script to run YemenBooking Indexing Tests
# Usage: ./run-tests.sh [option]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 YemenBooking Indexing Tests Runner${NC}"
echo "======================================"

# Function to check prerequisites
check_prerequisites() {
    echo -e "${YELLOW}Checking prerequisites...${NC}"
    
    # Check .NET SDK
    if ! command -v dotnet &> /dev/null; then
        echo -e "${RED}❌ .NET SDK is not installed${NC}"
        exit 1
    fi
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}❌ Docker is not installed${NC}"
        exit 1
    fi
    
    # Check if Docker is running
    if ! docker info &> /dev/null; then
        echo -e "${RED}❌ Docker is not running${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ All prerequisites met${NC}"
}

# Function to start test containers
start_containers() {
    echo -e "${YELLOW}Starting test containers...${NC}"
    
    # Start PostgreSQL
    docker run -d \
        --name test-postgres \
        -e POSTGRES_USER=testuser \
        -e POSTGRES_PASSWORD=testpass \
        -e POSTGRES_DB=testdb \
        -p 5433:5432 \
        postgres:15-alpine \
        2>/dev/null || echo "PostgreSQL container already running"
    
    # Start Redis
    docker run -d \
        --name test-redis \
        -p 6380:6379 \
        redis:7-alpine \
        2>/dev/null || echo "Redis container already running"
    
    # Wait for containers to be ready
    echo "Waiting for containers to be ready..."
    sleep 5
    
    echo -e "${GREEN}✅ Containers started${NC}"
}

# Function to stop test containers
stop_containers() {
    echo -e "${YELLOW}Stopping test containers...${NC}"
    docker stop test-postgres test-redis 2>/dev/null || true
    docker rm test-postgres test-redis 2>/dev/null || true
    echo -e "${GREEN}✅ Containers stopped${NC}"
}

# Function to run all tests
run_all_tests() {
    echo -e "${YELLOW}Running all tests...${NC}"
    dotnet test --logger "console;verbosity=normal"
}

# Function to run unit tests
run_unit_tests() {
    echo -e "${YELLOW}Running unit tests...${NC}"
    dotnet test --filter "FullyQualifiedName~Unit" --logger "console;verbosity=normal"
}

# Function to run integration tests
run_integration_tests() {
    echo -e "${YELLOW}Running integration tests...${NC}"
    start_containers
    dotnet test --filter "FullyQualifiedName~Integration" --logger "console;verbosity=normal"
}

# Function to run performance tests
run_performance_tests() {
    echo -e "${YELLOW}Running performance benchmarks...${NC}"
    dotnet run -c Release --project . --filter "*Benchmark*"
}

# Function to run stress tests
run_stress_tests() {
    echo -e "${YELLOW}Running stress tests...${NC}"
    start_containers
    dotnet test --filter "FullyQualifiedName~Stress" --logger "console;verbosity=normal"
}

# Function to run with coverage
run_with_coverage() {
    echo -e "${YELLOW}Running tests with coverage...${NC}"
    dotnet test /p:CollectCoverage=true \
                /p:CoverletOutputFormat=opencover \
                /p:CoverletOutput=./coverage/ \
                --logger "console;verbosity=normal"
    
    echo -e "${GREEN}✅ Coverage report generated in ./coverage/${NC}"
}

# Function to clean up
cleanup() {
    echo -e "${YELLOW}Cleaning up...${NC}"
    dotnet clean
    rm -rf bin obj TestResults coverage
    stop_containers
    echo -e "${GREEN}✅ Cleanup completed${NC}"
}

# Main menu
show_menu() {
    echo ""
    echo "Select an option:"
    echo "1) Run all tests"
    echo "2) Run unit tests only"
    echo "3) Run integration tests only"
    echo "4) Run performance benchmarks"
    echo "5) Run stress tests"
    echo "6) Run with coverage"
    echo "7) Start containers only"
    echo "8) Stop containers"
    echo "9) Clean up everything"
    echo "0) Exit"
    echo ""
}

# Main execution
check_prerequisites

if [ $# -eq 0 ]; then
    # Interactive mode
    while true; do
        show_menu
        read -p "Enter your choice: " choice
        
        case $choice in
            1) run_all_tests ;;
            2) run_unit_tests ;;
            3) run_integration_tests ;;
            4) run_performance_tests ;;
            5) run_stress_tests ;;
            6) run_with_coverage ;;
            7) start_containers ;;
            8) stop_containers ;;
            9) cleanup ;;
            0) echo "Goodbye!"; exit 0 ;;
            *) echo -e "${RED}Invalid option${NC}" ;;
        esac
        
        echo ""
        read -p "Press Enter to continue..."
    done
else
    # Command line mode
    case $1 in
        all) run_all_tests ;;
        unit) run_unit_tests ;;
        integration) run_integration_tests ;;
        performance) run_performance_tests ;;
        stress) run_stress_tests ;;
        coverage) run_with_coverage ;;
        start) start_containers ;;
        stop) stop_containers ;;
        clean) cleanup ;;
        *)
            echo "Usage: $0 [all|unit|integration|performance|stress|coverage|start|stop|clean]"
            exit 1
            ;;
    esac
fi

echo -e "${GREEN}✅ Done!${NC}"
