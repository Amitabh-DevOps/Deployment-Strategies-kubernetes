## Canary Deployment Strategy

- A Canary Deployment in Kubernetes is a strategy where a new version of an app is released to a small group of users first. If it works well, it’s gradually rolled out to everyone. This helps reduce the risk of issues affecting all users.


### How it works ?

- <b>Deploy New Version (Canary Release):</b>
  - The new version of the application is first deployed to a small subset of users or a specific group of pods, called the canary.
  - This is typically a small fraction of the total traffic, so the new version gets tested by a limited audience while the majority of users continue to use the stable, old version.
- <b>Traffic Splitting:</b>
  - The traffic is split between the old version (the stable version) and the new version (the canary version).
  - Initially, a small percentage (e.g., 5–10%) of the traffic is routed to the new canary version, and the rest continues to go to the old version. 
- <b>Monitor and Analyze:</b>
  - While the canary version is live, you monitor it for any errors or issues (like crashes, performance problems, etc.).
- <b>Gradual Rollout:</b>
  - If the canary version performs well, the percentage of traffic routed to the canary version is gradually increased.
  - This can be done in stages, such as 10%, 25%, 50%, and then 100%, depending on how confident you are with the new release.
  - The gradual increase reduces the risk of impacting all users if something goes wrong with the new version. 

| Pro's    | Con's |
| -------- | ------- |
| Version released for subset of users | Slow rollout    |
| Convenient for error rate and performance monitoring | Fine tune traffic distribution can be expensive |

> [!Note]
> This deployment strategy is suitable for Production environment.

![image](https://github.com/user-attachments/assets/5d08039b-e06b-4c08-aaff-b68dc435d570)

---

### Steps to implement Blue Green deployment

- Apply the both deployment manifests (nginx-blue-deployment.yaml and apache-green-deployment.yaml) present in the current directory.
```bash
kubectl apply -f nginx-canary-deployment.yaml
```

- Open a new tab and run the watch command to monitor the deployment
```bash
watch kubectl get pods
```

- It will deploy nginx web page and apache web page, now try to access the web page on browser.

```bash
http://<public-ip-nginx>:<nodeport>
``` 

- Now, apply apache-canary-deployment.yaml with one replica.

```bash
kubectl apply -f apache-canary-deployment.yaml
```

- Now, go to nginx-canary-deployment.yaml and edit replicas field with 3 replicas, so now total we have 4 replicas (3 nginx and 1 apache)
 
- Now try to access the web page on browser.

```bash
http://<public-ip-nginx>:<nodeport>
```

