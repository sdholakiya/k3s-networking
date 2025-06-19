#!/bin/bash

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo "Options:"
    echo "  --all             Delete all resources and Docker images"
    echo "  --k8s-only        Delete only Kubernetes resources (default)"
    echo "  --images-only     Delete only Docker images"
    echo "  --help            Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                # Delete k8s resources only"
    echo "  $0 --all          # Delete k8s resources and Docker images"
    echo "  $0 --images-only  # Delete Docker images only"
}

# Parse command line arguments
DELETE_ALL=false
DELETE_K8S=true
DELETE_IMAGES=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --all)
            DELETE_ALL=true
            DELETE_K8S=true
            DELETE_IMAGES=true
            shift
            ;;
        --k8s-only)
            DELETE_K8S=true
            DELETE_IMAGES=false
            shift
            ;;
        --images-only)
            DELETE_K8S=false
            DELETE_IMAGES=true
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

# Delete Kubernetes resources
if [ "$DELETE_K8S" = true ]; then
    echo "Deleting Kubernetes resources..."
    
    # Delete the pod
    echo "Deleting pod 'cfs-communication-pod'..."
    kubectl delete pod cfs-communication-pod --ignore-not-found=true
    
    # Delete the service
    echo "Deleting service 'cfs-service'..."
    kubectl delete service cfs-service --ignore-not-found=true
    
    # Clean up any temporary files that might have been created
    if [ -f "cfs-pod-temp.yaml" ]; then
        echo "Removing temporary YAML file..."
        rm cfs-pod-temp.yaml
    fi
    
    echo "Kubernetes resources cleanup completed."
fi

# Delete Docker images
if [ "$DELETE_IMAGES" = true ]; then
    echo "Deleting Docker images..."
    
    # Remove from k3s containerd
    echo "Removing images from k3s containerd..."
    k3s ctr images rm docker.io/library/cfs:latest 2>/dev/null || true
    k3s ctr images rm docker.io/library/dummy:latest 2>/dev/null || true
    
    # Remove from Docker
    echo "Removing Docker images..."
    docker rmi cfs:latest 2>/dev/null || true
    docker rmi dummy:latest 2>/dev/null || true
    
    echo "Docker images cleanup completed."
fi

# Show final status
echo ""
echo "Cleanup completed. Current status:"
if [ "$DELETE_K8S" = true ]; then
    echo "Kubernetes pods:"
    kubectl get pods 2>/dev/null | grep cfs-communication-pod || echo "  No cfs-communication-pod found"
    echo "Kubernetes services:"
    kubectl get services 2>/dev/null | grep cfs-service || echo "  No cfs-service found"
fi

if [ "$DELETE_IMAGES" = true ]; then
    echo "Docker images:"
    docker images | grep -E "(cfs|dummy)" || echo "  No cfs/dummy images found"
    echo "K3s images:"
    k3s ctr images ls | grep -E "(cfs|dummy)" || echo "  No cfs/dummy images found in k3s"
fi