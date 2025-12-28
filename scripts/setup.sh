#!/bin/bash
# AI Study Buddy - Initial Setup Script

set -e

echo "🚀 AI Study Buddy - Initial Setup"
echo "=================================="
echo ""

# Check if .env exists
if [ ! -f .env ]; then
    echo "📝 Creating .env file from template..."
    cp .env.example .env
    echo "⚠️  Please edit .env and update with your configuration"
    echo ""
fi

# Check if backend and frontend directories exist
if [ ! -d ../backend ]; then
    echo "❌ Backend directory not found!"
    echo "Please clone the backend repo:"
    echo "git clone https://github.com/akarales/study_buddy_backend.git ../backend"
    exit 1
fi

if [ ! -d ../frontend ]; then
    echo "❌ Frontend directory not found!"
    echo "Please clone the frontend repo:"
    echo "git clone https://github.com/akarales/study_buddy_frontend.git ../frontend"
    exit 1
fi

echo "✅ All repositories found"
echo ""

# Pull Ollama model
echo "📥 Pulling Ollama model (this may take a while)..."
docker compose up -d ollama
sleep 5
docker exec studybuddy_ollama ollama pull llama2

echo ""
echo "✅ Setup complete!"
echo ""
echo "Next steps:"
echo "1. Review and edit .env file"
echo "2. Run: ./scripts/start-dev.sh"
