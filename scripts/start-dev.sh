#!/bin/bash
# AI Study Buddy - Start Development Environment

set -e

echo "🚀 Starting AI Study Buddy Development Environment"
echo "=================================================="
echo ""

# Check if .env exists
if [ ! -f .env ]; then
    echo "❌ .env file not found!"
    echo "Run ./scripts/setup.sh first"
    exit 1
fi

# Start all services
echo "🐳 Starting Docker containers..."
docker compose up -d

echo ""
echo "⏳ Waiting for services to be healthy..."
sleep 10

echo ""
echo "✅ AI Study Buddy is running!"
echo ""
echo "Services:"
echo "- Frontend:  http://localhost:3000"
echo "- Backend:   http://localhost:8001"
echo "- API Docs:  http://localhost:8001/docs"
echo "- ChromaDB:  http://localhost:8000"
echo "- Postgres:  localhost:5432"
echo ""
echo "To view logs: docker compose logs -f"
echo "To stop:      docker compose down"
