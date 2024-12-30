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
