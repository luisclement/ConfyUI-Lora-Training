# syntax=docker/dockerfile:1.7-labs
FROM nvidia/cuda:12.8.0-devel-ubuntu22.04

ARG DEBIAN_FRONTEND=noninteractive
SHELL ["/bin/bash", "-lc"]

# --- OS deps ---
RUN apt-get update && apt-get install -y --no-install-recommends         wget curl git git-lfs ca-certificates build-essential pkg-config         ffmpeg libgl1 libglib2.0-0 tini aria2         && rm -rf /var/lib/apt/lists/* && git lfs install

# --- Micromamba (no ToS), Python 3.12 ---
ARG MAMBA_ROOT_PREFIX=/opt/micromamba
ENV MAMBA_ROOT_PREFIX=/opt/micromamba
RUN curl -L https://micro.mamba.pm/api/micromamba/linux-64/latest         | tar -xvj -C /usr/local/bin --strip-components=1 bin/micromamba

COPY requirements.txt /tmp/requirements.txt
COPY environment.yml /tmp/environment.yml
RUN micromamba env create -f /tmp/environment.yml && micromamba clean -y -a

# --- PyTorch 2.7.0 cu128 trio (author-compatible) ---
RUN pip install torch==2.7.0 torchvision==0.22.0 torchaudio==2.7.0 --index-url https://download.pytorch.org/whl/cu128
ENV CONDA_DEFAULT_ENV=diffpipe
ENV PATH=/opt/micromamba/envs/diffpipe/bin:/opt/micromamba/bin:${PATH}

# Helpful runtime envs
ENV NCCL_P2P_DISABLE=0         NCCL_IB_DISABLE=1         PYTHONDONTWRITEBYTECODE=1         HF_HUB_ENABLE_HF_TRANSFER=1         TORCH_CUDA_ARCH_LIST="8.9"         NVIDIA_VISIBLE_DEVICES=all         NVIDIA_DRIVER_CAPABILITIES=compute,utility

# Work dirs
RUN mkdir -p /app /workspace/diffusion-pipe/toml /workspace/diffusion-pipe/dataset         /workspace/modelsext /workspace/output /workspace/cache

# Entrypoint & helper scripts
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
COPY scripts/ /usr/local/bin/
COPY toml/ /workspace/diffusion-pipe/toml/
RUN chmod +x /usr/local/bin/*.sh || true

EXPOSE 8888 6006
ENTRYPOINT ["/usr/bin/tini","--","/usr/local/bin/entrypoint.sh"]
CMD ["bash"]
