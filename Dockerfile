# Single stage build for vLLM with GLM-4.5 model
FROM vllm/vllm-openai:v0.10.0

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
RUN python3 /app/download_model.py

# Expose the API port
EXPOSE 8000

# Set working directory
WORKDIR /app

# Use the vLLM entrypoint directly
ENTRYPOINT ["python3", "-m", "vllm.entrypoints.openai.api_server"]