#!/bin/bash

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo "Options:"
    echo "  --dummy-ip IP     Set dummy container IP address"
    echo "  --cfs-ip IP       Set cFS container IP address"
    echo "  --localhost       Use localhost for both containers (same pod)"
    echo "  --help            Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 --localhost                                    # Deploy in same pod"
    echo "  $0 --dummy-ip 192.168.1.100 --cfs-ip 192.168.1.101   # Deploy with specific IPs"
}

# Parse command line arguments
DUMMY_IP=""
CFS_IP=""
USE_LOCALHOST=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --dummy-ip)
            DUMMY_IP="$2"
            shift 2
            ;;
        --cfs-ip)
            CFS_IP="$2"
            shift 2
            ;;
        --localhost)
            USE_LOCALHOST=true
            shift
            ;;
        --help)
            show_usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Build cFS container
echo "Building cFS container..."
docker build -f Dockerfile.cfs -t cfs:latest .

# Build dummy container
echo "Building dummy container..."
docker build -f Dockerfile.dummy -t dummy:latest .

# Import images to k3s (if using k3s)
echo "Importing images to k3s..."
k3s ctr images import <(docker save cfs:latest)
k3s ctr images import <(docker save dummy:latest)

# Choose deployment configuration
if [ "$USE_LOCALHOST" = true ]; then
    echo "Deploying with localhost configuration..."
    kubectl apply -f cfs-pod-localhost.yaml
elif [ -n "$DUMMY_IP" ] && [ -n "$CFS_IP" ]; then
    echo "Deploying with custom IP addresses..."
    echo "Dummy IP: $DUMMY_IP"
    echo "cFS IP: $CFS_IP"
    
    # Create temporary YAML with IP addresses
    sed -e "s/DUMMY_IP_PLACEHOLDER/$DUMMY_IP/g" \
        -e "s/CFS_IP_PLACEHOLDER/$CFS_IP/g" \
        cfs-pod-with-ips.yaml > cfs-pod-temp.yaml
    
    kubectl apply -f cfs-pod-temp.yaml
    rm cfs-pod-temp.yaml
else
    echo "Error: Please specify either --localhost or both --dummy-ip and --cfs-ip"
    show_usage
    exit 1
fi

# Check pod status
echo "Checking pod status..."
kubectl get pods

echo ""
echo "To view logs:"
echo "kubectl logs cfs-communication-pod -c cfs-container -f"
echo "kubectl logs cfs-communication-pod -c dummy-container -f"
echo ""
echo "To delete the pod:"
echo "kubectl delete pod cfs-communication-pod"