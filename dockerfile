# --- 1. Start from GPU-ready PyTorch base image ---
FROM pytorch/pytorch:2.3.0-cuda12.1-cudnn8-runtime

# Install basic system utilities
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        git curl wget unzip nano vim openssh-server && \
    rm -rf /var/lib/apt/lists/*

# --- 2. Copy in application code from local folder (from your good pre-NVIDIA-install version) ---
WORKDIR /app
COPY . /app

# --- 3. Install Python dependencies ---
# Replace with your actual requirements file from the working image
RUN pip install --upgrade pip && \
    pip install -r /app/requirements.txt

# --- 4. Make sure entrypoint is executable ---
RUN chmod +x /app/scripts/entrypoint.sh

# --- 5. Ports ---
EXPOSE 22 8888 6006

# --- 6. Default entrypoint ---
ENTRYPOINT ["/app/scripts/entrypoint.sh"]
