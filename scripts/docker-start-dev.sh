#!/bin/bash
# Development setup script

set -e

echo "🚀 Starting Full-Stack Development Environment"

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker and try again."
    exit 1
fi

# Create network if it doesn't exist
if ! docker network ls | grep -q "app-network"; then
    echo "📡 Creating Docker network..."
    docker network create app-network
fi

# Build and start services
echo "🏗️  Building and starting services..."
docker-compose -f docker-compose.yml -f docker-compose.dev.yml up --build -d

echo "⏳ Waiting for services to be healthy..."

# Wait for PostgreSQL
echo "📊 Waiting for PostgreSQL..."
until docker-compose exec postgres pg_isready -U postgres > /dev/null 2>&1; do
    sleep 2
done

# Wait for backend
echo "🌱 Waiting for Spring Boot backend..."
until curl -f http://localhost:8080/actuator/health > /dev/null 2>&1; do
    sleep 5
done

# Wait for frontend
echo "⚛️  Waiting for React frontend..."
until curl -f http://localhost:3000 > /dev/null 2>&1; do
    sleep 3
done

echo "✅ All services are running!"
echo ""
echo "🌐 Application URLs:"
echo "   Frontend: http://localhost:3000"
echo "   Backend API: http://localhost:8080"
echo "   Nginx Proxy: http://localhost:80"
echo "   PgAdmin: http://localhost:5050 (admin@example.com / admin)"
echo "   PostgreSQL: localhost:5432 (postgres / postgres)"
echo ""
echo "📊 Useful commands:"
echo "   docker-compose logs -f                    # View all logs"
echo "   docker-compose logs -f backend           # View backend logs"
echo "   docker-compose logs -f frontend          # View frontend logs"
echo "   docker-compose ps                        # View service status"
echo "   ./scripts/docker-stop-dev.sh            # Stop all services"
echo ""