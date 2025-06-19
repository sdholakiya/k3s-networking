# cFS Container Deployment Guide

This setup provides containerized NASA cFS with UDP communication capabilities.

## Files Created

- `Dockerfile.cfs` - NASA cFS container (listens on UDP port 1234)
- `Dockerfile.dummy` - Dummy container (listens on UDP port 9002)
- `cfs-pod-localhost.yaml` - Kubernetes deployment for same-pod communication
- `cfs-pod-with-ips.yaml` - Template for custom IP configuration
- `build-and-deploy.sh` - Automated build and deployment script

## Environment Variables

### cFS Container
- `DUMMY_CONTAINER_IP` - IP address of dummy container (default: "dummy-container")

### Dummy Container  
- `CFS_CONTAINER_IP` - IP address of cFS container (default: "cfs-container")

## Deployment Options

### Option 1: Same Pod (localhost communication)
```bash
./build-and-deploy.sh --localhost
```

### Option 2: Custom IP Addresses
```bash
./build-and-deploy.sh --dummy-ip 192.168.1.100 --cfs-ip 192.168.1.101
```

## Manual Docker Build
```bash
# Build images
docker build -f Dockerfile.cfs -t cfs:latest .
docker build -f Dockerfile.dummy -t dummy:latest .

# Run with custom IPs
docker run -e DUMMY_CONTAINER_IP=192.168.1.100 cfs:latest
docker run -e CFS_CONTAINER_IP=192.168.1.101 dummy:latest
```

## Monitoring
```bash
# View logs
kubectl logs cfs-communication-pod -c cfs-container -f
kubectl logs cfs-communication-pod -c dummy-container -f

# Check pod status
kubectl get pods

# Delete deployment
kubectl delete pod cfs-communication-pod
```

## Communication Flow
- cFS container listens on UDP port 1234
- Dummy container listens on UDP port 9002  
- Both containers send periodic messages to each other
- Messages include timestamps and response acknowledgments