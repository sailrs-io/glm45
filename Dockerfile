# Multi-stage build for optimized final image
FROM vllm/vllm-openai:v0.10.0 as base

# Set environment variables for model configuration
ARG MODEL_NAME=zai-org/GLM-4.5-FP8
ENV MODEL_NAME=${MODEL_NAME}
ENV HF_HOME=/app/models
ENV TRANSFORMERS_CACHE=/app/models
ENV HF_DATASETS_CACHE=/app/models

# Create model cache directory
RUN mkdir -p /app/models

# Install Python dependencies for model downloading
RUN pip install --no-cache-dir huggingface-hub transformers

# Download the model during build time
RUN python -c "
import os
from huggingface_hub import snapshot_download
from transformers import AutoTokenizer, AutoModelForCausalLM

model_name = os.environ['MODEL_NAME']
cache_dir = os.environ['HF_HOME']

print(f'Downloading model: {model_name}')
print(f'Cache directory: {cache_dir}')

# Download model files
snapshot_download(
    repo_id=model_name,
    cache_dir=cache_dir,
    local_dir=f'{cache_dir}/{model_name}',
    local_dir_use_symlinks=False
)

# Verify model can be loaded
try:
    tokenizer = AutoTokenizer.from_pretrained(
        model_name,
        cache_dir=cache_dir,
        trust_remote_code=True
    )
    print(f'Successfully downloaded and verified model: {model_name}')
except Exception as e:
    print(f'Warning: Could not verify model loading: {e}')
"

# Create startup script
RUN echo '#!/bin/bash\n\
set -e\n\
\n\
echo "Starting vLLM OpenAI API server with model: $MODEL_NAME"\n\
echo "Model cache directory: $HF_HOME"\n\
\n\
# Start vLLM server\n\
exec python -m vllm.entrypoints.openai.api_server \\\n\
    --model "$MODEL_NAME" \\\n\
    --host 0.0.0.0 \\\n\
    --port 8000 \\\n\
    --trust-remote-code \\\n\
    --served-model-name "$MODEL_NAME" \\\n\
    "$@"' > /app/start.sh && chmod +x /app/start.sh

# Production stage - copy only necessary files
FROM vllm/vllm-openai:v0.10.0 as production

# Set environment variables
ARG MODEL_NAME=zai-org/GLM-4.5-FP8
ENV MODEL_NAME=${MODEL_NAME}
ENV HF_HOME=/app/models
ENV TRANSFORMERS_CACHE=/app/models
ENV HF_DATASETS_CACHE=/app/models

# Create model directory
RUN mkdir -p /app/models

# Copy downloaded models from base stage
COPY --from=base /app/models /app/models

# Copy startup script
COPY --from=base /app/start.sh /app/start.sh

# Expose the API port
EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8000/health || exit 1

# Set working directory
WORKDIR /app

# Start the server
CMD ["/app/start.sh"]