# AI Study Buddy - Infrastructure

Docker Compose orchestration for the AI Study Buddy application.

## Overview

This repository contains the infrastructure configuration to run the complete AI Study Buddy stack locally using Docker Compose.

**Architecture Pattern:** Service-Oriented Monolith with distributed infrastructure - monolithic application (frontend + backend) with isolated external services (database, vector store, LLM, search) for optimal scaling and resource utilization.

## Architecture

```
┌─────────────┐     ┌─────────────┐
│  Frontend   │────▶│   Backend   │
│  (React)    │     │  (FastAPI)  │
│  Port 3000  │     │  Port 8001  │
└─────────────┘     └──────┬──────┘
                           │
                ┌──────────┼──────────┬──────────┐
                │          │          │          │
           ┌────▼───┐ ┌───▼────┐ ┌──▼─────┐ ┌──▼──────┐
           │Postgres│ │ChromaDB│ │ Ollama │ │ SearXNG │
           │  5432  │ │  8000  │ │ 11434  │ │  8080   │
           └────────┘ └────────┘ └────────┘ └─────────┘
                                                  │
                                             Web Search
```

## Related Repositories

- **Frontend**: https://github.com/akarales/study_buddy_frontend
- **Backend**: https://github.com/akarales/study_buddy_backend
- **Infrastructure**: https://github.com/akarales/study_buddy_Infra (this repo)

## Quick Start

### Prerequisites

- Docker & Docker Compose
- Git

### Setup

```bash
# 1. Clone all repositories
mkdir AI_Study_Buddy && cd AI_Study_Buddy

git clone https://github.com/akarales/study_buddy_Infra.git infrastructure
git clone https://github.com/akarales/study_buddy_backend.git backend
git clone https://github.com/akarales/study_buddy_frontend.git frontend

# 2. Run setup
cd infrastructure
./scripts/setup.sh

# 3. Edit .env file with your configuration
nano .env

# 4. Start the application
./scripts/start-dev.sh
```

### Access

- **Frontend**: http://localhost:3000
- **Backend API**: http://localhost:8001
- **API Documentation**: http://localhost:8001/docs
- **ChromaDB**: http://localhost:8000
- **SearXNG (Search)**: http://localhost:8080
- **PostgreSQL**: localhost:5432

## Services

### Frontend (React + Vite)
- Modern React 19 application
- TailwindCSS + shadcn/ui components
- Nginx for production serving

### Backend (FastAPI)
- RESTful API
- RAG with document upload
- Voice transcription (Whisper)
- AI chat with conversation history

### PostgreSQL
- Relational database for application data
- Persistent storage

### ChromaDB
- Vector database for RAG
- Document embeddings

### Ollama
- Local LLM inference
- Default model: llama3-groq-tool-use:8b
- Supports multiple models (see Available AI Models section)

### SearXNG
- Privacy-respecting metasearch engine
- Aggregates results from multiple search engines
- No tracking or profiling
- Used by backend for web search capabilities
- Port: 8080

## Commands

```bash
# Start all services
docker compose up -d

# View logs
docker compose logs -f

# View specific service logs
docker compose logs -f backend

# Stop all services
docker compose down

# Rebuild services
docker compose up -d --build

# Stop and remove volumes (fresh start)
docker compose down -v
```

## Environment Variables

See `.env.example` for all configuration options.

Key variables:
- `POSTGRES_PASSWORD`: Database password
- `OLLAMA_MODEL`: LLM model to use (default: llama2)
- `API_BASE_URL`: Backend URL for frontend

## Development Workflow

### Backend Development
```bash
cd backend
git checkout develop
git pull origin develop
git checkout -b feature/my-feature

# Make changes...
git add .
git commit -m "feat: add new feature"
git push origin feature/my-feature

# Rebuild backend container
cd ../infrastructure
docker compose up -d --build backend
```

### Frontend Development
```bash
cd frontend
git checkout develop
git pull origin develop
git checkout -b feature/my-feature

# Make changes...
git add .
git commit -m "feat: add new UI component"
git push origin feature/my-feature

# Rebuild frontend container
cd ../infrastructure
docker compose up -d --build frontend
```

## Documentation

See `/docs` folder for additional documentation:
- `FRONTEND_REBUILD_SPEC.md` - Complete frontend specification

## Troubleshooting

### Services not starting
```bash
# Check service health
docker compose ps

# View logs
docker compose logs

# Restart services
docker compose restart
```

### Database connection issues
```bash
# Recreate database
docker compose down -v
docker compose up -d postgres
```

### Ollama model issues
```bash
# Pull models manually
docker compose exec ollama ollama pull llama3:8b
docker compose exec ollama ollama pull qwen2.5:0.5b

# List installed models
docker compose exec ollama ollama list

# Remove unused models
docker compose exec ollama ollama rm model-name
```

### GPU not detected
```bash
# For NVIDIA GPUs on Linux/WSL 2
# Install NVIDIA Container Toolkit
# See: https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html

# Verify GPU is accessible
docker run --rm --gpus all nvidia/cuda:11.8.0-base-ubuntu22.04 nvidia-smi

# For Windows 11 + WSL 2, see docs/WINDOWS_SETUP_GUIDE.md
```

## 🚀 Scripts & Automation

### Setup Scripts
- `configure-gpu-windows.ps1` - Windows GPU auto-configuration
- `detect-gpu.sh` - Linux/Mac GPU detection

### Usage

**Windows (PowerShell):**
```powershell
# Auto-configure GPU settings
powershell -ExecutionPolicy Bypass -File .\configure-gpu-windows.ps1
```

**Linux/Mac:**
```bash
# Detect GPU and configure
./detect-gpu.sh
```

## 📚 Documentation

Additional guides in `docs/` folder:
- `WINDOWS_SETUP_GUIDE.md` - Complete Windows 11 setup (75 pages)
- `WINDOWS_QUICK_START.md` - Fast 15-minute setup
- `PWA_IMPLEMENTATION_GUIDE.md` - Progressive Web App guide
- `API_AUDIT_REPORT.md` - API documentation
- `FUTURE_UPGRADES_ROADMAP.md` - Feature roadmap

## 🌐 Available AI Models

**Fast CPU Models** (< 2GB):
- `qwen2.5:0.5b` - 397MB - Fastest
- `gemma2:2b` - 1.6GB - Very fast  
- `phi3:mini` - 2.2GB - Fast

**Quality GPU Models** (> 4GB):
- `llama3-groq-tool-use:8b` - Tool calling (default)
- `llama3:8b` - General purpose
- `qwen2.5:7b` - Multilingual
- `mistral:7b` - Strong reasoning

Download models:
```bash
# Download default model
docker compose exec ollama ollama pull llama3-groq-tool-use:8b

# Download fast CPU model
docker compose exec ollama ollama pull qwen2.5:0.5b

# Download multiple models
docker compose exec ollama ollama pull llama3:8b
docker compose exec ollama ollama pull qwen2.5:7b
```

## Production Deployment

For production deployment, each service should be deployed independently:
- **Frontend**: Static hosting (Vercel, Netlify) or containerized with Nginx
- **Backend**: Container orchestration (Kubernetes, ECS, Docker Swarm)
- **Databases**: Managed services (AWS RDS, Google Cloud SQL, DigitalOcean)
- **Vector Store**: Managed ChromaDB or self-hosted with persistent volumes
- **LLM**: Dedicated GPU instances or API services (OpenAI, Anthropic)

## License

MIT License - Copyright © 2025 Alexandros Karales

## 👨‍💻 Author

**Alexandros Karales**
- Website: [karales.com](https://karales.com)
- Email: karales@gmail.com
- GitHub: [@akarales](https://github.com/akarales)
