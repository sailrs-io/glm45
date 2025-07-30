# Self-Hosted Runner Setup Guide

This guide will help you set up a GitHub self-hosted runner to build your Docker images for the GLM-4.5-FP8 model.

## Prerequisites

Your self-hosted runner machine needs:
- **OS**: Ubuntu 20.04+ (recommended) or any Linux distribution
- **CPU**: 4+ cores recommended
- **RAM**: 8GB+ minimum, 16GB+ recommended
- **Storage**: 50GB+ free space (models can be large)
- **Docker**: Installed and configured
- **NVIDIA GPU**: Optional but recommended for model testing
- **Network**: Stable internet connection

## Step 1: Set Up the Runner Machine

### 1.1 Install Docker
```bash
# Update package list
sudo apt update

# Install prerequisites
sudo apt install -y apt-transport-https ca-certificates curl gnupg lsb-release

# Add Docker's official GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Add Docker repository
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io

# Add your user to docker group
sudo usermod -aG docker $USER

# Start and enable Docker
sudo systemctl start docker
sudo systemctl enable docker

# Log out and back in for group changes to take effect
```

### 1.2 Install NVIDIA Docker (Optional but Recommended)
```bash
# Install NVIDIA Container Toolkit
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | sudo tee /etc/apt/sources.list.d/nvidia-docker.list

sudo apt update
sudo apt install -y nvidia-docker2

# Restart Docker
sudo systemctl restart docker

# Test NVIDIA Docker
sudo docker run --rm --gpus all nvidia/cuda:11.8-base-ubuntu20.04 nvidia-smi
```

### 1.3 Install Docker Buildx
```bash
# Docker Buildx is usually included with Docker, but you can ensure it's available
docker buildx version
```

## Step 2: Set Up GitHub Self-Hosted Runner

### 2.1 Create Runner Token
1. Go to your GitHub repository
2. Navigate to **Settings** → **Actions** → **Runners**
3. Click **New self-hosted runner**
4. Choose your operating system (Linux)
5. Copy the setup commands

### 2.2 Install and Configure Runner
```bash
# Create a directory for the runner
mkdir actions-runner && cd actions-runner

# Download the runner (replace with your specific URL)
curl -o actions-runner-linux-x64-2.311.0.tar.gz -L https://github.com/actions/runner/releases/download/v2.311.0/actions-runner-linux-x64-2.311.0.tar.gz

# Extract the installer
tar xzf ./actions-runner-linux-x64-2.311.0.tar.gz

# Configure the runner (replace with your specific token and URL)
./config.sh --url https://github.com/YOUR_USERNAME/YOUR_REPO --token YOUR_TOKEN

# Install the runner as a service
sudo ./svc.sh install

# Start the service
sudo ./svc.sh start

# Check status
sudo ./svc.sh status
```

### 2.3 Configure Runner Labels (Optional)
You can add custom labels to your runner for more specific targeting:

```bash
# Stop the service first
sudo ./svc.sh stop

# Reconfigure with labels
./config.sh --url https://github.com/YOUR_USERNAME/YOUR_REPO --token YOUR_TOKEN --labels docker,linux,x64,gpu

# Restart the service
sudo ./svc.sh start
```

## Step 3: Configure Runner Environment

### 3.1 Set Up Cache Directory
```bash
# Create cache directory for Docker builds
sudo mkdir -p /tmp/.buildx-cache
sudo chown -R $USER:$USER /tmp/.buildx-cache
```

### 3.2 Configure Docker for Buildx
```bash
# Create Docker config directory
mkdir -p ~/.docker

# Create or edit Docker config
cat > ~/.docker/config.json << EOF
{
  "experimental": "enabled",
  "features": {
    "buildkit": true
  }
}
EOF
```

### 3.3 Set Up Buildx Builder
```bash
# Create a new builder instance
docker buildx create --name self-hosted-builder --use

# Inspect the builder
docker buildx inspect --bootstrap
```

## Step 4: Test Your Setup

### 4.1 Test Docker Build
```bash
# Test a simple Docker build
docker buildx build --platform linux/amd64 -t test-image .
```

### 4.2 Test GitHub Actions
1. Go to your repository
2. Navigate to **Actions**
3. Select the "Build and Push Model Container" workflow
4. Click **Run workflow**
5. Fill in the model name and optional tag
6. Click **Run workflow**

## Step 5: Monitor and Maintain

### 5.1 Check Runner Status
```bash
# Check if runner is online
cd actions-runner
./svc.sh status

# View logs
sudo journalctl -u actions.runner.* -f
```

### 5.2 Update Runner
```bash
# Stop the service
sudo ./svc.sh stop

# Download latest runner
curl -o actions-runner-linux-x64-latest.tar.gz -L https://github.com/actions/runner/releases/latest/download/actions-runner-linux-x64-2.311.0.tar.gz

# Extract and update
tar xzf ./actions-runner-linux-x64-latest.tar.gz --strip-components=1

# Restart the service
sudo ./svc.sh start
```

### 5.3 Clean Up Cache
```bash
# Clean Docker cache periodically
docker system prune -f

# Clean build cache
rm -rf /tmp/.buildx-cache
mkdir -p /tmp/.buildx-cache
```

## Troubleshooting

### Common Issues

1. **Runner not connecting**
   - Check network connectivity
   - Verify token is correct
   - Check firewall settings

2. **Docker permission issues**
   - Ensure user is in docker group
   - Restart Docker service
   - Log out and back in

3. **Build failures**
   - Check available disk space
   - Verify Docker is running
   - Check build logs for specific errors

4. **Cache issues**
   - Clear build cache: `rm -rf /tmp/.buildx-cache`
   - Restart Docker service

### Useful Commands

```bash
# Check runner status
cd actions-runner && ./svc.sh status

# View runner logs
sudo journalctl -u actions.runner.* -f

# Check Docker status
sudo systemctl status docker

# Check available disk space
df -h

# Check memory usage
free -h

# Check GPU status (if NVIDIA)
nvidia-smi
```

## Security Considerations

1. **Network Security**
   - Use firewall rules to restrict access
   - Consider VPN for secure communication

2. **Runner Security**
   - Keep runner updated
   - Use dedicated user for runner
   - Regular security updates

3. **Docker Security**
   - Use non-root user when possible
   - Scan images for vulnerabilities
   - Keep base images updated

## Performance Optimization

1. **Storage**
   - Use SSD for better I/O performance
   - Separate storage for cache and builds

2. **Memory**
   - Ensure sufficient RAM for model downloads
   - Monitor memory usage during builds

3. **Network**
   - Use fast, stable internet connection
   - Consider local Docker registry for faster pulls

## Next Steps

Once your self-hosted runner is set up:

1. Test the workflow manually
2. Monitor build times and resource usage
3. Set up monitoring and alerting
4. Configure backup strategies
5. Document any custom configurations

Your self-hosted runner is now ready to build Docker images for your GLM-4.5-FP8 model! 