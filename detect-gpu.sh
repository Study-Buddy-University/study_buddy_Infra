#!/bin/bash
# Auto-detect GPU type and configure docker-compose environment
# Usage: source ./detect-gpu.sh  OR  ./detect-gpu.sh

set -e

echo "🔍 Detecting GPU type..."

# Check for NVIDIA GPU
if command -v nvidia-smi &> /dev/null; then
    if nvidia-smi &> /dev/null; then
        echo "✅ NVIDIA GPU detected"
        export GPU_TYPE=nvidia
        export GPU_COUNT=all
        
        # Get GPU info
        GPU_NAME=$(nvidia-smi --query-gpu=name --format=csv,noheader | head -n1)
        GPU_VRAM=$(nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits | head -n1)
        
        echo "   GPU: $GPU_NAME"
        echo "   VRAM: ${GPU_VRAM}MB"
        
        # Save to .env file
        if [ -f .env ]; then
            sed -i '/^GPU_TYPE=/d' .env
            sed -i '/^GPU_COUNT=/d' .env
        fi
        echo "GPU_TYPE=nvidia" >> .env
        echo "GPU_COUNT=all" >> .env
        
        echo "✅ Configuration saved to .env"
        exit 0
    fi
fi

# Check for AMD GPU
if command -v rocm-smi &> /dev/null; then
    if rocm-smi &> /dev/null; then
        echo "✅ AMD GPU detected"
        
        echo "⚠️  AMD GPU requires manual docker-compose.yml configuration"
        echo "   Please edit docker-compose.yml and:"
        echo "   1. Comment out the 'deploy' section under ollama"
        echo "   2. Add the following under ollama:"
        echo ""
        echo "    devices:"
        echo "      - /dev/kfd"
        echo "      - /dev/dri"
        echo "    group_add:"
        echo "      - video"
        echo ""
        echo "   Then run: docker compose up -d ollama"
        
        exit 0
    fi
fi

# No GPU found
echo "ℹ️  No GPU detected (checked NVIDIA and AMD)"
echo "   Ollama will run on CPU"
echo ""
echo "   CPU-only is fine for small models:"
echo "   - qwen2.5:0.5b (Fastest)"
echo "   - gemma2:2b (Very Fast)"
echo "   - phi3:mini (Fast)"

# Clear GPU settings
if [ -f .env ]; then
    sed -i '/^GPU_TYPE=/d' .env
    sed -i '/^GPU_COUNT=/d' .env
fi

exit 0
