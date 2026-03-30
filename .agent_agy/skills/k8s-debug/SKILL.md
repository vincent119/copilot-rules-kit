---
name: k8s-debug
description: Kubernetes troubleshooting workflow - Pod status, logs, events, exec, and resource monitoring.
keywords:
  - kubernetes
  - k8s
  - kubectl
  - pod
  - crashloopbackoff
  - imagepullbackoff
  - oomkilled
  - troubleshooting
  - debug
  - logs
  - events
  - port-forward
author: Vincent Yu
status: unpublished
updated: '2026-03-30'
version: 1.0.1
tag: skill
type: skill
---

# K8s Debugging Workflow

Systematic approach to diagnose and fix Kubernetes application issues.

## 1. Check Pod Status

Identify pods in error states (CrashLoopBackOff, ImagePullBackOff, etc.):

```bash
kubectl get pods -o wide
kubectl describe pod <POD_NAME>
```

## 2. View Logs

Check container logs for errors and stack traces:

```bash
# Current logs
kubectl logs <POD_NAME> [-c <CONTAINER>]

# Previous crash logs
kubectl logs <POD_NAME> --previous
```

## 3. Check Events

Review cluster events for scheduling/mounting/health check failures:

```bash
kubectl get events --sort-by=.lastTimestamp
```

## 4. Exec into Container

Debug filesystem, environment, or network issues:

```bash
kubectl exec -it <POD_NAME> -- sh

# Inside container:
env                          # Check environment variables
curl localhost:8080          # Test HTTP endpoints
nc -zv <HOST> <PORT>         # Test network connectivity
```

## 5. Port Forward

Forward pod port to local for testing:

```bash
kubectl port-forward <POD_NAME> 8080:8080
```

## 6. Monitor Resources

Check for OOM or CPU throttling:

```bash
kubectl top pod <POD_NAME>
```

## Common Issues

| Issue | Command | Solution |
|-------|---------|----------|
| CrashLoopBackOff | `logs --previous` | Check startup errors |
| ImagePullBackOff | `describe pod` | Verify image name/credentials |
| Pending | `get events` | Check resource limits/node capacity |
| OOMKilled | `top pod` | Increase memory limits |
