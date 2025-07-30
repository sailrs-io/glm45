# vLLM GLM-4.5 Model Server

A containerized solution for serving the GLM-4.5-FP8 model using vLLM with OpenAI-compatible API endpoints.

## Features

- 🚀 **Pre-built Model**: Model is downloaded during Docker build time for faster startup
- 🔧 **Configurable**: Support for different models via environment variables
- 🐳 **Optimized Container**: Multi-stage build for minimal final image size
- 🏗️ **CI/CD Ready**: GitHub Actions workflow for automated builds
- 📊 **Health Checks**: Built-in health monitoring
- 🔄 **OpenAI Compatible**: Drop-in replacement for OpenAI API

## Quick Start

### Using Docker Compose (Recommended)

1. Clone the repository:
```bash
git clone <repository-url>
cd glm45
```

2. Copy and configure environment variables:
```bash
cp env.example .env
# Edit .env to customize MODEL_NAME and ports if needed
```

3. Start the service:
```bash
docker-compose up -d
```

4. Test the API:
```bash
# Health check
curl http://localhost:8000/health

# List available models
curl http://localhost:8000/v1/models

# Chat completion
curl -X POST http://localhost:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "zai-org/GLM-4.5-FP8",
    "messages": [{"role": "user", "content": "Hello, how are you?"}],
    "max_tokens": 100
  }'
```

### Using Docker Run

```bash
docker run -d \
  --name vllm-glm45 \
  -p 8000:8000 \
  --gpus all \
  -e MODEL_NAME=zai-org/GLM-4.5-FP8 \
  ghcr.io/yourusername/glm45/vllm-model-zai-org-glm-4.5-fp8:latest
```

### Building from Source

```bash
# Build with default model
docker build -t vllm-glm45 .

# Build with custom model
docker build -t vllm-custom \
  --build-arg MODEL_NAME=your-org/your-model .
```

## Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `MODEL_NAME` | `zai-org/GLM-4.5-FP8` | Hugging Face model identifier |
| `API_PORT` | `8000` | Port for the API server |
| `HF_HOME` | `/app/models` | Model cache directory |
| `HF_TOKEN` | - | Hugging Face token for private models |

### Model Cache

The container uses `/app/models` as the model cache directory. You can:

1. **Persistent Storage**: Mount a volume to persist models across container restarts
2. **Custom Cache**: Set `HF_HOME` environment variable to change cache location

## GitHub Actions CI/CD

### Automated Builds

The repository includes a GitHub Actions workflow that automatically builds and pushes container images to GitHub Container Registry.

#### Triggering Builds

1. **Manual Trigger**: Use GitHub's workflow dispatch feature
   - Go to Actions tab in your repository
   - Select "Build and Push Model Container"
   - Enter the model name (e.g., `zai-org/GLM-4.5-FP8`)
   - Click "Run workflow"

2. **Automatic Trigger**: Push changes to main branch affecting:
   - `Dockerfile`
   - `.github/workflows/build-model-image.yml`

#### Image Naming Convention

Images are automatically named based on the model:
- Model: `zai-org/GLM-4.5-FP8`
- Image: `ghcr.io/yourusername/glm45/vllm-model-zai-org-glm-4.5-fp8:latest`

### Using Pre-built Images

```bash
# Pull the latest image
docker pull ghcr.io/yourusername/glm45/vllm-model-zai-org-glm-4.5-fp8:latest

# Run the container
docker run -d \
  --name vllm-server \
  -p 8000:8000 \
  --gpus all \
  ghcr.io/yourusername/glm45/vllm-model-zai-org-glm-4.5-fp8:latest
```

## API Usage

The server provides OpenAI-compatible endpoints:

### Chat Completions

```bash
curl -X POST http://localhost:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "zai-org/GLM-4.5-FP8",
    "messages": [
      {"role": "system", "content": "You are a helpful assistant."},
      {"role": "user", "content": "Explain quantum computing"}
    ],
    "max_tokens": 150,
    "temperature": 0.7
  }'
```

### Completions

```bash
curl -X POST http://localhost:8000/v1/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "zai-org/GLM-4.5-FP8",
    "prompt": "The future of artificial intelligence is",
    "max_tokens": 100
  }'
```

### List Models

```bash
curl http://localhost:8000/v1/models
```

## System Requirements

### Hardware
- **GPU**: NVIDIA GPU with CUDA support (recommended)
- **RAM**: 8GB+ system RAM
- **VRAM**: 4GB+ GPU memory (depends on model size)
- **Storage**: 10GB+ free space for model files

### Software
- Docker 20.10+
- Docker Compose 2.0+
- NVIDIA Container Toolkit (for GPU support)

## Troubleshooting

### Common Issues

1. **Out of Memory**: Reduce batch size or use smaller model variant
2. **GPU Not Detected**: Ensure NVIDIA Container Toolkit is installed
3. **Model Download Fails**: Check internet connection and HF_TOKEN if needed
4. **Port Conflicts**: Change API_PORT in .env file

### Logs

```bash
# View container logs
docker-compose logs -f vllm-glm45

# Or with docker run
docker logs -f vllm-glm45
```

### Health Check

The container includes health checks accessible at:
```bash
curl http://localhost:8000/health
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test with different models
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Supported Models

This setup supports any Hugging Face model compatible with vLLM. Popular choices include:

- `zai-org/GLM-4.5-FP8` (default)
- `microsoft/DialoGPT-medium`
- `meta-llama/Llama-2-7b-chat-hf`
- `mistralai/Mistral-7B-Instruct-v0.1`

Configure via the `MODEL_NAME` environment variable.