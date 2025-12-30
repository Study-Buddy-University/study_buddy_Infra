#!/bin/bash
# AI Study Buddy - Model Download Script (Linux/Ubuntu)
# Downloads all recommended models for the application

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

echo -e "${CYAN}================================================${NC}"
echo -e "${CYAN}  AI Study Buddy - Model Download Script${NC}"
echo -e "${CYAN}================================================${NC}"
echo ""

# Check if Docker containers are running
if ! docker compose ps | grep -q "ollama.*running"; then
    echo -e "${RED}[ERROR] Ollama container is not running!${NC}"
    echo -e "${YELLOW}Please start the application first:${NC}"
    echo -e "${CYAN}  docker compose up -d${NC}"
    exit 1
fi

echo -e "${GREEN}[INFO] Ollama container is running${NC}"
echo ""

# Function to download model
download_model() {
    local model_name=$1
    local description=$2
    local size=$3
    
    echo ""
    echo -e "${YELLOW}================================================${NC}"
    echo -e "${CYAN}Downloading: $model_name${NC}"
    echo -e "${WHITE}Description: $description${NC}"
    echo -e "${WHITE}Size: $size${NC}"
    echo -e "${YELLOW}================================================${NC}"
    
    docker compose exec ollama ollama pull "$model_name"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}[SUCCESS] $model_name downloaded successfully!${NC}"
    else
        echo -e "${RED}[ERROR] Failed to download $model_name${NC}"
    fi
}

# Define models
declare -a fast_models=(
    "qwen2.5:0.5b|Fastest - Best for CPU|~400MB"
    "gemma2:2b|Very Fast - Good balance|~1.6GB"
    "phi3:mini|Fast - Good quality|~2.3GB"
)

declare -a full_models=(
    "llama3-groq-tool-use:8b|Llama 3 Groq with tools|~4.7GB"
    "llama3:8b|Meta Llama 3|~4.7GB"
    "qwen2.5:7b|Qwen 2.5 - Excellent quality|~4.7GB"
    "mistral:7b|Mistral - Fast 7B model|~4.1GB"
)

# Display menu
echo -e "${YELLOW}What would you like to download?${NC}"
echo -e "${WHITE}  1. Fast Models only (CPU-friendly, ~4.3GB total)${NC}"
echo -e "${WHITE}  2. Full Models only (Better quality, ~18GB total)${NC}"
echo -e "${WHITE}  3. All Models (Fast + Full, ~22GB total)${NC}"
echo -e "${WHITE}  4. Custom selection${NC}"
echo ""

read -p "Enter choice (1-4): " choice

case $choice in
    1)
        echo ""
        echo -e "${CYAN}[INFO] Downloading Fast Models...${NC}"
        for model in "${fast_models[@]}"; do
            IFS='|' read -r name desc size <<< "$model"
            download_model "$name" "$desc" "$size"
        done
        ;;
    2)
        echo ""
        echo -e "${CYAN}[INFO] Downloading Full Models...${NC}"
        for model in "${full_models[@]}"; do
            IFS='|' read -r name desc size <<< "$model"
            download_model "$name" "$desc" "$size"
        done
        ;;
    3)
        echo ""
        echo -e "${CYAN}[INFO] Downloading All Models...${NC}"
        echo -e "${YELLOW}[WARNING] This will download ~22GB of data!${NC}"
        read -p "Continue? (y/N): " confirm
        if [[ "$confirm" =~ ^[Yy]$ ]]; then
            for model in "${fast_models[@]}"; do
                IFS='|' read -r name desc size <<< "$model"
                download_model "$name" "$desc" "$size"
            done
            for model in "${full_models[@]}"; do
                IFS='|' read -r name desc size <<< "$model"
                download_model "$name" "$desc" "$size"
            done
        else
            echo -e "${YELLOW}Download cancelled.${NC}"
            exit 0
        fi
        ;;
    4)
        echo ""
        echo -e "${CYAN}Available models:${NC}"
        echo ""
        echo -e "${YELLOW}Fast Models:${NC}"
        idx=1
        for model in "${fast_models[@]}"; do
            IFS='|' read -r name desc size <<< "$model"
            echo -e "${WHITE}  $idx. $name - $desc ($size)${NC}"
            ((idx++))
        done
        echo ""
        echo -e "${YELLOW}Full Models:${NC}"
        for model in "${full_models[@]}"; do
            IFS='|' read -r name desc size <<< "$model"
            echo -e "${WHITE}  $idx. $name - $desc ($size)${NC}"
            ((idx++))
        done
        echo ""
        echo -e "${YELLOW}Enter model numbers to download (comma-separated, e.g., 1,3,5):${NC}"
        read -p "Models: " selection
        
        IFS=',' read -ra numbers <<< "$selection"
        for num in "${numbers[@]}"; do
            num=$(echo "$num" | xargs) # trim whitespace
            idx=1
            found=false
            
            for model in "${fast_models[@]}"; do
                if [ "$num" -eq "$idx" ]; then
                    IFS='|' read -r name desc size <<< "$model"
                    download_model "$name" "$desc" "$size"
                    found=true
                    break
                fi
                ((idx++))
            done
            
            if [ "$found" = false ]; then
                for model in "${full_models[@]}"; do
                    if [ "$num" -eq "$idx" ]; then
                        IFS='|' read -r name desc size <<< "$model"
                        download_model "$name" "$desc" "$size"
                        break
                    fi
                    ((idx++))
                done
            fi
        done
        ;;
    *)
        echo -e "${RED}[ERROR] Invalid choice${NC}"
        exit 1
        ;;
esac

echo ""
echo -e "${GREEN}================================================${NC}"
echo -e "${GREEN}  Model Download Complete!${NC}"
echo -e "${GREEN}================================================${NC}"
echo ""
echo -e "${CYAN}To verify downloaded models:${NC}"
echo -e "${WHITE}  docker compose exec ollama ollama list${NC}"
echo ""
