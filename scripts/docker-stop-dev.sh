#!/bin/bash
# Stop development environment

set -e

echo "🛑 Stopping Full-Stack Development Environment"

# Stop and remove containers
docker-compose -f docker-compose.yml -f docker-compose.dev.yml down

echo "✅ Development environment stopped"
echo ""
echo "💡 To remove all data (including database):"
echo "   docker-compose -f docker-compose.yml -f docker-compose.dev.yml down -v"
echo ""
echo "🧹 To clean up everything (containers, images, volumes):"
echo "   docker system prune -a --volumes"