# Multi-stage build for optimized final image
FROM vllm/vllm-openai:v0.10.0 AS base

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

# Copy the model download script
COPY download_model.py /app/download_model.py

# Download the model during build time
RUN python /app/download_model.py

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
FROM vllm/vllm-openai:v0.10.0 AS production

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