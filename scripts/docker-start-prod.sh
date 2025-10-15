#!/bin/bash
# Production deployment script

set -e

echo "🚀 Starting Production Deployment"

# Check if .env file exists
if [ ! -f .env ]; then
    echo "⚠️  No .env file found. Creating template..."
    cat > .env << EOF
# Production Environment Variables
DB_NAME=demoapp
DB_USER=postgres
DB_PASSWORD=change_me_in_production
REACT_APP_API_URL=http://your-domain.com
EOF
    echo "📝 Please edit .env file with production values and run this script again."
    exit 1
fi

# Load environment variables
source .env

# Validate required variables
if [ -z "$DB_PASSWORD" ] || [ "$DB_PASSWORD" = "change_me_in_production" ]; then
    echo "❌ Please set DB_PASSWORD in .env file"
    exit 1
fi

# Build images
echo "🏗️  Building production images..."
docker-compose -f docker-compose.yml -f docker-compose.prod.yml build --no-cache

# Start services
echo "🌟 Starting production services..."
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d

echo "⏳ Waiting for services to be ready..."

# Wait for database
until docker-compose exec postgres pg_isready -U $DB_USER > /dev/null 2>&1; do
    sleep 2
done

# Wait for backend
until curl -f http://localhost:8080/actuator/health > /dev/null 2>&1; do
    sleep 5
done

echo "✅ Production deployment complete!"
echo ""
echo "🌐 Application is available at:"
echo "   Main URL: http://localhost"
echo "   API Health: http://localhost/actuator/health"
echo ""