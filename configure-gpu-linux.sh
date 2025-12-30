#!/bin/bash
# AI Study Buddy - Linux GPU Configuration Script
# This script automatically detects your GPU and configures the .env file

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

echo -e "${CYAN}================================================${NC}"
echo -e "${CYAN}  AI Study Buddy - GPU Configuration Script${NC}"
echo -e "${CYAN}  Linux Edition${NC}"
echo -e "${CYAN}================================================${NC}"
echo ""

# Function to detect NVIDIA GPU
detect_nvidia_gpu() {
    if command -v nvidia-smi &> /dev/null; then
        local gpu_info=$(nvidia-smi --query-gpu=name,memory.total --format=csv,noheader 2>/dev/null)
        if [ $? -eq 0 ] && [ -n "$gpu_info" ]; then
            echo "found|$gpu_info"
            return 0
        fi
    fi
    echo "not_found|"
    return 1
}

# Function to detect AMD GPU
detect_amd_gpu() {
    local amd_gpu=$(lspci | grep -i 'vga\|3d\|display' | grep -iE 'amd|radeon' | head -1)
    if [ -n "$amd_gpu" ]; then
        echo "found|$amd_gpu"
        return 0
    fi
    echo "not_found|"
    return 1
}

# Function to update .env file
update_env_file() {
    local gpu_type=$1
    local gpu_count=$2
    
    local env_path=".env"
    local env_example_path=".env.example"
    
    # Check if .env exists, if not create from .env.example
    if [ ! -f "$env_path" ]; then
        if [ -f "$env_example_path" ]; then
            echo -e "${YELLOW}Creating .env file from .env.example...${NC}"
            cp "$env_example_path" "$env_path"
        else
            echo -e "${RED}Error: .env.example not found!${NC}"
            echo -e "${RED}Please ensure you're running this script from the infrastructure/ directory${NC}"
            return 1
        fi
    fi
    
    # Set OLLAMA_IMAGE based on GPU type
    local ollama_image="ollama/ollama:latest"
    if [ "$gpu_type" = "amd" ]; then
        ollama_image="ollama/ollama:rocm"
    fi
    
    # Update or add GPU_TYPE
    if grep -q "^GPU_TYPE=" "$env_path"; then
        sed -i "s/^GPU_TYPE=.*/GPU_TYPE=$gpu_type/" "$env_path"
    else
        echo "GPU_TYPE=$gpu_type" >> "$env_path"
    fi
    
    # Update or add GPU_COUNT
    if grep -q "^GPU_COUNT=" "$env_path"; then
        sed -i "s/^GPU_COUNT=.*/GPU_COUNT=$gpu_count/" "$env_path"
    else
        echo "GPU_COUNT=$gpu_count" >> "$env_path"
    fi
    
    # Update or add OLLAMA_IMAGE
    if grep -q "^OLLAMA_IMAGE=" "$env_path"; then
        sed -i "s|^OLLAMA_IMAGE=.*|OLLAMA_IMAGE=$ollama_image|" "$env_path"
    else
        echo "OLLAMA_IMAGE=$ollama_image" >> "$env_path"
    fi
    
    echo ""
    echo -e "${GREEN}[SUCCESS] Configuration saved to .env file${NC}"
    echo -e "${GREEN}   GPU_TYPE=$gpu_type${NC}"
    echo -e "${GREEN}   GPU_COUNT=$gpu_count${NC}"
    echo -e "${GREEN}   OLLAMA_IMAGE=$ollama_image${NC}"
    
    return 0
}

# Main script execution
echo -e "${YELLOW}[DETECTING] Checking for GPU hardware...${NC}"
echo ""

# Detect NVIDIA GPU
nvidia_result=$(detect_nvidia_gpu)
nvidia_found=$(echo "$nvidia_result" | cut -d'|' -f1)
nvidia_info=$(echo "$nvidia_result" | cut -d'|' -f2-)

if [ "$nvidia_found" = "found" ]; then
    echo -e "${GREEN}[SUCCESS] NVIDIA GPU Detected!${NC}"
    echo -e "${CYAN}   Model: $nvidia_info${NC}"
    echo ""
    
    read -p "Enable GPU acceleration? (Y/n): " response
    response=${response:-Y}
    
    if [[ "$response" =~ ^[Yy]$ ]]; then
        if update_env_file "nvidia" 1; then
            echo ""
            echo -e "${GREEN}================================================${NC}"
            echo -e "${GREEN}  GPU Configuration Complete!${NC}"
            echo -e "${GREEN}================================================${NC}"
            echo ""
            echo -e "${YELLOW}Next steps:${NC}"
            echo -e "${WHITE}  1. Ensure Docker is running${NC}"
            echo -e "${WHITE}  2. Ensure NVIDIA Container Toolkit is installed${NC}"
            echo -e "${WHITE}     (See documentation for instructions)${NC}"
            echo -e "${WHITE}  3. Start the application with NVIDIA GPU override:${NC}"
            echo -e "${CYAN}     docker compose -f docker-compose.yml -f docker-compose.nvidia.yml up -d${NC}"
            echo ""
            echo -e "${GREEN}[GPU] GPU acceleration will be enabled for AI inference!${NC}"
        fi
    else
        echo -e "${YELLOW}GPU acceleration disabled. Using CPU mode.${NC}"
        update_env_file "none" 0
    fi
    exit 0
fi

# Detect AMD GPU
amd_result=$(detect_amd_gpu)
amd_found=$(echo "$amd_result" | cut -d'|' -f1)
amd_info=$(echo "$amd_result" | cut -d'|' -f2-)

if [ "$amd_found" = "found" ]; then
    echo -e "${YELLOW}[WARNING] AMD GPU Detected!${NC}"
    echo -e "${CYAN}   Model: $amd_info${NC}"
    echo ""
    echo -e "${YELLOW}================================================${NC}"
    echo -e "${YELLOW}  AMD GPU Docker Configuration${NC}"
    echo -e "${YELLOW}================================================${NC}"
    echo ""
    echo -e "${WHITE}AMD GPU support in Docker on Linux requires:${NC}"
    echo -e "${WHITE}  - ROCm drivers installed${NC}"
    echo -e "${WHITE}  - Docker with device access to /dev/kfd and /dev/dri${NC}"
    echo -e "${WHITE}  - ROCm Docker image (ollama/ollama:rocm)${NC}"
    echo ""
    echo -e "${YELLOW}[WARNING] AMD GPU support is better on Linux than Windows!${NC}"
    echo -e "${YELLOW}   However, not all AMD GPUs are supported by ROCm.${NC}"
    echo ""
    
    read -p "Configure for AMD GPU Docker? (y/N): " response
    
    if [[ "$response" =~ ^[Yy]$ ]]; then
        if update_env_file "amd" 1; then
            echo ""
            echo -e "${GREEN}================================================${NC}"
            echo -e "${GREEN}  AMD GPU Docker Configuration Complete!${NC}"
            echo -e "${GREEN}================================================${NC}"
            echo ""
            echo -e "${YELLOW}Next steps:${NC}"
            echo -e "${WHITE}  1. Start Docker with AMD GPU override:${NC}"
            echo -e "${CYAN}     docker compose -f docker-compose.yml -f docker-compose.amd.yml up -d${NC}"
            echo ""
            echo -e "${WHITE}  2. Verify GPU detection:${NC}"
            echo -e "${CYAN}     docker compose exec ollama rocm-smi${NC}"
            echo ""
            echo -e "${YELLOW}[WARNING] If Ollama doesn't detect GPU:${NC}"
            echo -e "${WHITE}  - Check: docker compose logs ollama${NC}"
            echo -e "${WHITE}  - Verify ROCm drivers: rocm-smi${NC}"
            echo -e "${WHITE}  - Check supported GPUs: https://rocm.docs.amd.com/en/latest/release/gpu_os_support.html${NC}"
            echo -e "${WHITE}  - Fallback to CPU mode (restart with GPU_TYPE=none)${NC}"
        fi
    else
        echo ""
        echo -e "${YELLOW}Using CPU mode instead (recommended if ROCm not installed).${NC}"
        update_env_file "none" 0
        echo ""
        echo -e "${GREEN}CPU mode configured. Start application with:${NC}"
        echo -e "${CYAN}  docker compose up -d${NC}"
    fi
    exit 0
fi

# No GPU detected
echo -e "${YELLOW}[INFO] No GPU detected${NC}"
echo ""
echo -e "${WHITE}The application will run in CPU-only mode.${NC}"
echo -e "${WHITE}This is still functional but will be slower for AI inference.${NC}"
echo ""
echo -e "${YELLOW}Recommendations:${NC}"
echo -e "${WHITE}  - Use smaller models (qwen2.5:0.5b, gemma2:2b)${NC}"
echo -e "${WHITE}  - Consider upgrading to a system with NVIDIA GPU${NC}"
echo ""

read -p "Continue with CPU-only mode? (Y/n): " response
response=${response:-Y}

if [[ "$response" =~ ^[Yy]$ ]]; then
    if update_env_file "none" 0; then
        echo ""
        echo -e "${GREEN}================================================${NC}"
        echo -e "${GREEN}  CPU Configuration Complete!${NC}"
        echo -e "${GREEN}================================================${NC}"
        echo ""
        echo -e "${YELLOW}Next steps:${NC}"
        echo -e "${WHITE}  1. Start the application:${NC}"
        echo -e "${CYAN}     docker compose up -d${NC}"
        echo ""
        echo -e "${CYAN}[CPU] Application will run in CPU mode${NC}"
    fi
else
    echo -e "${YELLOW}Configuration cancelled.${NC}"
    exit 1
fi

echo ""
echo -e "${CYAN}For more information, see:${NC}"
echo -e "${WHITE}  - LINUX_SETUP_GUIDE.md${NC}"
echo -e "${WHITE}  - GPU_DOCKER_CONFIGURATION.md${NC}"
echo ""
