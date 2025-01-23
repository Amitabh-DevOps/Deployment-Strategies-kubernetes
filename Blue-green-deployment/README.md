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

### Steps to implement Blue Green deployment

- Apply the both deployment manifests (nginx-blue-deployment.yaml and apache-green-deployment.yaml) present in the current directory.
```bash
kubectl apply -f nginx-blue-deployment.yaml
kubectl apply -f apache-green-deployment.yaml
```

- Open a new tab and run the watch command to monitor the deployment
```bash
watch kubectl get pods
```

- It will deploy nginx web page (Blue environment) and apache web page (Green environment), now try to access the blue environment (nginx) web page on browser.

```bash
http://<public-ip-nginx>:<nodeport>
```
![image](https://github.com/user-attachments/assets/7c73464a-2e4d-4a6a-9b60-207d72d5b66a)

> Note: Check the URL and port carefully 

- Now, go to the nginx-blue-deployment.yaml manifest file and edit the service's selector field with **apache-green** selector.

![image](https://github.com/user-attachments/assets/5fa85a34-55b1-458b-ac56-c07b3ec91f06)

![image](https://github.com/user-attachments/assets/9c4732e1-db91-417d-b04f-c46a3fb5d13a)

- Apply nginx-blue-deployment.yaml
```bash
kubectl apply -f nginx-blue-deployment.yaml
```

- Go to the same blue environment (nginx) web page and reload the webpage, you will see apache this time. It means you have successfully switched the traffic from blue environment to the green environment.

![image](https://github.com/user-attachments/assets/8b154fbc-dd68-45da-95d9-c6238e831ebe)

