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

### Prerequisites to try this:

1. EC2 Instance with Ubuntu OS

2. Docker installed & Configured

3. Kind Installed

4. Kubectl Installed

5. Kind Cluster running(Use `kind-config.yml` file present in this directory.)

>   [!NOTE]
> 
>   You have to go inside root dir of this repo and create Kind Cluster using command: `kind create cluster --config kind-config.yml --name dep-strg`

---

### Steps to implement Canary deployment

- Apply the both deployment manifests (`onlineshop-canary-deployment.yaml` and `onlineshop-without-footer-canary-deployment.yaml`) and all manifest files present in the current directory.

    ```bash
    kubectl apply -f .
    ```

- Open a new tab of terminal and run the watch command to monitor the deployment

    ```bash
    watch kubectl get pods -n canary-ns
    ```

- It will deploy `online shop web page` and `online shop without footer web page`, now try to access the web page on browser.

- Run this command to get all resources created in `canary-ns` namespace.

    ```bash
    kubectl get all -n canary-ns
    ```

- Forward the svc port to the EC2 instance port 3000

    ```bash
    kubectl port-forward --address 0.0.0.0 svc/canary-deployment-service 3000:3000 -n canary-ns &
    ```

- Open the inbound rule for port 3000 in that EC2 Instance and check the application at URL:

    ```bash
    http://<Your_Instance_Public_Ip>:3000
    ```

- Now, go to `onlineshop-canary-deployment.yaml` and edit replicas field with 3 replicas, so now total we have 4 replicas (`3 with footer` and `1 without footer`)

- Now, apply the manifest file

    ```bash
    kubectl apply -f onlineshop-canary-deployment.yaml
    ```

- You can check the terminal for exactly what happening, Where you have ran `watch kubectl get pods -n canary-ns`
 
- Now try to access the web page on browser and refresh repeatedly untill you see online shop without footer web page.

    ```bash
    http://<Your_Instance_Public_Ip>:3000
    ```

---

> [!Note]
>
> If you cannot access the web app after the update, check your terminal — you probably encountered an error like:
>
>   ```bash
>   error: lost connection to pod
>   ```
>
> Don’t worry! This happens because we’re running the cluster locally (e.g., with **Kind**), and the `kubectl port-forward` session breaks when the underlying pod is replaced during deployment (especially with `Recreate` strategy).
>
> 🔁 Just run the `kubectl port-forward` command again to re-establish the connection and access the app in your browser.
>
> ✅ This issue won't occur when deploying on managed Kubernetes services like **AWS EKS**, **GKE**, or **AKS**, because in those environments you usually expose services using `NodePort`, `LoadBalancer`, or Ingress — not `kubectl port-forward`.