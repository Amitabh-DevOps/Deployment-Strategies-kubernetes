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

### Steps to implement Recreate deployment

- Apply all the manifest files present in the current directory.

    ```bash
    kubectl apply -f .
    ```

- Run this command to get all resources created in `recreate-ns` namespace.

    ```bash
    kubectl get all -n recreate-ns
    ```

- Forward the svc port to the EC2 instance port 3000

    ```bash
    kubectl port-forward --address 0.0.0.0 svc/recreate-service 3000:3000 -n recreate-ns &
    ```

- Open the inbound rule for port 3000 in that EC2 Instance and check the application at URL:

    ```bash
    http://<Your_Instance_Public_Ip>:3000
    ```

- Open a new tab of terminal and connect your EC2 instance and run the watch command to monitor the deployment

    ```bash
    watch kubectl get pods
    ```

- You have successfully accessed the online_shop webpage. Now edit the deployment file and change the image from <b>online_shop</b> to <b>online_shop_without_footer</b> and apply.

    ```bash
    kubectl apply -f . 
    ```

- or, You can only apply deployment file

    ```bash
    kubectl apply -f recreate-deployment.yml
    ```

- Immediately go to second tab where ran watch command and monitor (It will delete all the pods and then create new ones).
