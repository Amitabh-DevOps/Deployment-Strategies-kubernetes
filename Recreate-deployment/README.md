## Recreate Deployment Strategy

- Recreate deployment strategy involves the process of terminating all existing running pods before creating new ones.


### How it works ?

- <b>Pod Termination:</b> kubernetes terminates all existing pods.
- <b>Pod Creation:</b> It creates new pods with updated configurations.

| Pro's    | Con's |
| -------- | ------- |
| Application state entirely renewed | Downtime that depends on the both shutdown and boot duration of the application     |

> [!Note]
> This deployment strategy is suitable for development environment.

![image](https://github.com/user-attachments/assets/90197afc-a892-47d5-9160-c4543b64defa)

---

### Steps to implement Recreate deployment

- Apply the file present in the current directory with name recreate-deployment.yaml
```bash
kubectl apply -f recreate-deployment.yaml
```

- Open a new tab and run the watch command to monitor the deployment
```bash
watch kubectl get pods
```

- It will deploy nginx web page, now edit the deployment file and change the image from <b>nginx</b> to <b>httpd</b> and apply.

```bash
kubectl apply -f recreate-deployment.yaml
```

- Immediately go to second tab where ran watch command and monitor (It will delete all the pods and then create new ones).
