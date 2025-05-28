## Blue-Green Deployment Strategy

- Blue-Green deployment is a strategy used in Kubernetes (and other environments) to reduce downtime and risk when deploying new versions of an application.
- It involves maintaining two separate environments, which are referred to as Blue and Green.


### How it works ?

- <b>Blue Environment:</b> This is the live environment, where the current version of your application is running..
- <b>Green Environment:</b> The new version of the application is deployed to the Green environment. During this phase, there is no impact on the users accessing the Blue environment.
- <b>Test the Green Environment:</b> Once the Green environment is up, it is fully tested to ensure the new version works as expected.
- <b>Switch traffic:</b> After validating that the Green environment is stable, the routing of user traffic is switched from Blue to Green. Now, the Green environment becomes the live production environment, and users interact with the new version.

| Pro's    | Con's |
| -------- | ------- |
| Instant rollout/rollback | Requires double the resources    |
| Avoid versioning issue, change entire cluster state in one go | Proper test of entire platform should be done before releasing to the production environment. |

> [!Note]
> This deployment strategy is suitable for Production environment.

![image](https://github.com/user-attachments/assets/ad967289-f554-473b-ba67-4953e57270c2)

---

### Prerequisites to try this:

1. EC2 Instance with Ubuntu OS

2. Docker installed & Configured

3. Kind Installed

4. Kubectl Installed

5. Kind Cluster running(Use `kind-config.yml` file present in this root directory.)

>   [!NOTE]
> 
>   You have to go inside root dir of this repo and create Kind Cluster using command: `kind create cluster --config kind-config.yml --name dep-strg`

---

### Steps to implement Blue Green deployment

- Create a namespace first by using:

    ```bash
    kubectl apply -f blue-green-ns.yml
    ```

- Apply the both deployment manifests (`online-shop-without-footer-blue-deployment.yaml` and `online-shop-green-deployment.yaml`) present in the current directory.

    ```bash
    kubectl apply -f online-shop-without-footer-blue-deployment.yaml
    kubectl apply -f online-shop-green-deployment.yaml
    ```

- Open a new tab of terminal and run the watch command to monitor the deployment

    ```bash
    watch kubectl get pods -n blue-green-ns
    ```

- It will deploy `online shop web page without footer` (Blue environment) and `online shop web page with footer` as a new feature (Green environment), now try to access the blue environment web page on browser.

- Run this command to get all resources created in `blue-green-ns` namespace.

    ```bash
    kubectl get all -n blue-green-ns
    ```

- Forward the `online-shop-blue-deployment-service` svc Nodeport with the EC2 instance port 3001

    ```bash
    kubectl port-forward --address 0.0.0.0 svc/online-shop-blue-deployment-service 30001:3001 -n blue-green-ns &
    ```

- Open the inbound rule for port 30001 in that EC2 Instance and check the application(without footer online shop) at URL:

    ```bash
    http://<Your_Instance_Public_Ip>:30001
    ```

---

- Forward the `online-shop-green-deployment-service` svc Nodeport with the EC2 instance port 3000

    ```bash
    kubectl port-forward --address 0.0.0.0 svc/online-shop-green-deployment-service 30000:3000 -n blue-green-ns &
    ```

- Open the inbound rule for port 30000 in that EC2 Instance and check the application(With footer online shop) at URL:

    ```bash
    http://<Your_Instance_Public_Ip>:30000
    ```


![image](https://github.com/user-attachments/assets/7c73464a-2e4d-4a6a-9b60-207d72d5b66a)

> Note: Check the URL and port carefully 

- Now, go to the `online-shop-without-footer-blue-deployment.yaml` manifest file and edit the service's selector field with **`online-shop-green`** selector.

![image](https://github.com/user-attachments/assets/5fa85a34-55b1-458b-ac56-c07b3ec91f06)

![image](https://github.com/user-attachments/assets/9c4732e1-db91-417d-b04f-c46a3fb5d13a)

- Apply `online-shop-without-footer-blue-deployment.yaml`

    ```bash
    kubectl apply -f online-shop-without-footer-blue-deployment.yaml
    ```
- Kill all the port-forward using command:
    
    ```bash
    pkill -f "kubectl port-forward"
    ```

- Now again, Forward the `online-shop-blue-deployment-service` svc Nodeport with the EC2 instance port 3001

    ```bash
    kubectl port-forward --address 0.0.0.0 svc/online-shop-blue-deployment-service 30001:3001 -n blue-green-ns &
    ```

- Check now, the application is now added a new feature as `with footer online shop`, as it is previously does not have footer but it is now added as a feature, check at URL:

    ```bash
    http://<Your_Instance_Public_Ip>:30001
    ```

- Reload the webpage, you will see `with footer online web page` this time. It means you have successfully switched the traffic from blue environment to the green environment.

![image](https://github.com/user-attachments/assets/8b154fbc-dd68-45da-95d9-c6238e831ebe)

