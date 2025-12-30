# AI Study Buddy - Model Download Script
# Downloads all recommended models for the application

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "  AI Study Buddy - Model Download Script" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

# Check if Docker containers are running
$ollamaRunning = docker compose ps | Select-String "ollama" | Select-String "running"
if (-not $ollamaRunning) {
    Write-Host "[ERROR] Ollama container is not running!" -ForegroundColor Red
    Write-Host "Please start the application first:" -ForegroundColor Yellow
    Write-Host "  docker compose up -d" -ForegroundColor Cyan
    exit 1
}

Write-Host "[INFO] Ollama container is running" -ForegroundColor Green
Write-Host ""

# Define models
$fastModels = @(
    @{Name="qwen2.5:0.5b"; Size="~400MB"; Description="Fastest - Best for CPU"},
    @{Name="gemma2:2b"; Size="~1.6GB"; Description="Very Fast - Good balance"},
    @{Name="phi3:mini"; Size="~2.3GB"; Description="Fast - Good quality"}
)

$fullModels = @(
    @{Name="llama3-groq-tool-use:8b"; Size="~4.7GB"; Description="Llama 3 Groq with tools"},
    @{Name="llama3:8b"; Size="~4.7GB"; Description="Meta Llama 3"},
    @{Name="qwen2.5:7b"; Size="~4.7GB"; Description="Qwen 2.5 - Excellent quality"},
    @{Name="mistral:7b"; Size="~4.1GB"; Description="Mistral - Fast 7B model"}
)

# Function to download model
function Download-Model {
    param (
        [string]$ModelName,
        [string]$Description,
        [string]$Size
    )
    
    Write-Host ""
    Write-Host "================================================" -ForegroundColor Yellow
    Write-Host "Downloading: $ModelName" -ForegroundColor Cyan
    Write-Host "Description: $Description" -ForegroundColor White
    Write-Host "Size: $Size" -ForegroundColor White
    Write-Host "================================================" -ForegroundColor Yellow
    
    docker compose exec ollama ollama pull $ModelName
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[SUCCESS] $ModelName downloaded successfully!" -ForegroundColor Green
    }
    else {
        Write-Host "[ERROR] Failed to download $ModelName" -ForegroundColor Red
    }
}

# Ask what to download
Write-Host "What would you like to download?" -ForegroundColor Yellow
Write-Host "  1. Fast Models only (CPU-friendly, ~4.3GB total)" -ForegroundColor White
Write-Host "  2. Full Models only (Better quality, ~18GB total)" -ForegroundColor White
Write-Host "  3. All Models (Fast + Full, ~22GB total)" -ForegroundColor White
Write-Host "  4. Custom selection" -ForegroundColor White
Write-Host ""

$choice = Read-Host "Enter choice (1-4)"

switch ($choice) {
    "1" {
        Write-Host ""
        Write-Host "[INFO] Downloading Fast Models..." -ForegroundColor Cyan
        foreach ($model in $fastModels) {
            Download-Model -ModelName $model.Name -Description $model.Description -Size $model.Size
        }
    }
    "2" {
        Write-Host ""
        Write-Host "[INFO] Downloading Full Models..." -ForegroundColor Cyan
        foreach ($model in $fullModels) {
            Download-Model -ModelName $model.Name -Description $model.Description -Size $model.Size
        }
    }
    "3" {
        Write-Host ""
        Write-Host "[INFO] Downloading All Models..." -ForegroundColor Cyan
        Write-Host "[WARNING] This will download ~22GB of data!" -ForegroundColor Yellow
        $confirm = Read-Host "Continue? (y/N)"
        if ($confirm -eq "y" -or $confirm -eq "Y") {
            foreach ($model in $fastModels) {
                Download-Model -ModelName $model.Name -Description $model.Description -Size $model.Size
            }
            foreach ($model in $fullModels) {
                Download-Model -ModelName $model.Name -Description $model.Description -Size $model.Size
            }
        }
        else {
            Write-Host "Download cancelled." -ForegroundColor Yellow
            exit 0
        }
    }
    "4" {
        Write-Host ""
        Write-Host "Available models:" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Fast Models:" -ForegroundColor Yellow
        for ($i = 0; $i -lt $fastModels.Count; $i++) {
            Write-Host "  $($i+1). $($fastModels[$i].Name) - $($fastModels[$i].Description) ($($fastModels[$i].Size))" -ForegroundColor White
        }
        Write-Host ""
        Write-Host "Full Models:" -ForegroundColor Yellow
        for ($i = 0; $i -lt $fullModels.Count; $i++) {
            $num = $i + $fastModels.Count + 1
            Write-Host "  $num. $($fullModels[$i].Name) - $($fullModels[$i].Description) ($($fullModels[$i].Size))" -ForegroundColor White
        }
        Write-Host ""
        Write-Host "Enter model numbers to download (comma-separated, e.g., 1,3,5):" -ForegroundColor Yellow
        $selection = Read-Host "Models"
        $numbers = $selection -split "," | ForEach-Object { $_.Trim() }
        
        foreach ($num in $numbers) {
            $index = [int]$num - 1
            if ($index -lt $fastModels.Count) {
                $model = $fastModels[$index]
                Download-Model -ModelName $model.Name -Description $model.Description -Size $model.Size
            }
            else {
                $fullIndex = $index - $fastModels.Count
                if ($fullIndex -lt $fullModels.Count) {
                    $model = $fullModels[$fullIndex]
                    Download-Model -ModelName $model.Name -Description $model.Description -Size $model.Size
                }
            }
        }
    }
    default {
        Write-Host "[ERROR] Invalid choice" -ForegroundColor Red
        exit 1
    }
}

Write-Host ""
Write-Host "================================================" -ForegroundColor Green
Write-Host "  Model Download Complete!" -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Green
Write-Host ""
Write-Host "To verify downloaded models:" -ForegroundColor Cyan
Write-Host "  docker compose exec ollama ollama list" -ForegroundColor White
Write-Host ""
