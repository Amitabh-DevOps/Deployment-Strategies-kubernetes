## Rolling Update Deployment Strategy

- A rolling update in Kubernetes is a deployment strategy used to gradually replace the existing set of Pods with a new set of Pods one by one.
- This ensures that there is no downtime during the update process as the application continues to serve requests while the update is in progress.


### How it works ?

- <b>Pod Creation:</b> kubernetes creates one new pod of newer version.
- <b>Pod Termination:</b> It terminates existing pods.

| Pro's    | Con's |
| -------- | ------- |
| Version is slowly released across instances | Rollout/Rollback can take time    |
| Convenient for stateful applications | No control over traffic |

> [!Note]
> This deployment strategy is suitable for UAT,QA environment.
> For stateful applications suitable on production environment

![image](https://github.com/user-attachments/assets/ef9a9088-0f0b-4645-9c66-505481c7eb6f)

---

### Steps to implement Recreate deployment

- Apply the file present in the current directory with name rolling-update-deployment.yaml
```bash
kubectl apply -f rolling-update-deployment.yaml
```

- Open a new tab and run the watch command to monitor the deployment
```bash
watch kubectl get pods
```

- It will deploy nginx web page, now edit the deployment file and change the image from <b>nginx</b> to <b>httpd</b> and apply.

```bash
kubectl apply -f rolling-update-deployment.yaml
```

- Immediately go to second tab where ran watch command and monitor (It will delete all the pods and then create new ones).
