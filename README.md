# 🌐 AWS Path-Based Routing with Terraform

This project provisions a complete **path-based routing infrastructure** on **AWS** using **Terraform**.  
It deploys two EC2 instances (`Red` and `Blue`), hosts static web pages from **S3**, and configures an **Application Load Balancer (ALB)** that routes traffic based on URL paths:

- `http://<alb-dns>/red` → routes to Red EC2 instance  
- `http://<alb-dns>/blue` → routes to Blue EC2 instance  

---

## 🏗️ Project Architecture

**Resources Created:**
- **VPC** → Uses AWS default VPC and subnets  
- **S3 Bucket** → Stores static website files (`index.html`, images, CSS)  
- **IAM Role + Policy** → Grants EC2 read access to S3  
- **Security Group** → Allows HTTP (80) and SSH (22)  
- **EC2 Instances** → Red and Blue servers (Amazon Linux 2 AMI)  
- **Application Load Balancer** → Routes requests based on URL paths  
- **Target Groups & Listener Rules** → `/red*` and `/blue*` forwarding rules  

---

## 📁 Project Structure

```
terraform-path-based-routing/
│
├── main.tf                 # Main Terraform configuration
├── user-data-red.sh        # EC2 bootstrap script for Red instance
├── user-data-blue.sh       # EC2 bootstrap script for Blue instance
├── README.md               # Project documentation
```

---

## ⚙️ Prerequisites

Before you begin, make sure you have:

- [Terraform](https://developer.hashicorp.com/terraform/downloads) installed  
- An [AWS account](https://aws.amazon.com/free)  
- Configured AWS CLI credentials:
  ```bash
  aws configure
  ```
- The following files uploaded to your S3 bucket:
  - `red-index.html`
  - `blue-index.html`
  - Any CSS or image files referenced in the scripts

---

## 🚀 Deployment Steps

1. **Clone this repository**
   ```bash
   git clone https://github.com/<your-username>/terraform-path-based-routing.git
   cd terraform-path-based-routing
   ```

2. **Initialize Terraform**
   ```bash
   terraform init
   ```

3. **Review the plan**
   ```bash
   terraform plan
   ```

4. **Apply configuration**
   ```bash
   terraform apply -auto-approve
   ```

5. **View Outputs**
   ```bash
   terraform output
   ```
   Copy the `alb_dns_name` value.

6. **Test**
   Visit the URLs below in your browser:
   - `http://<alb_dns>/red`
   - `http://<alb_dns>/blue`

---

## 🧹 Cleanup

To destroy all resources and avoid AWS charges:
```bash
terraform destroy -auto-approve
```

---

## 🧠 Notes

- EC2 instances use an **IAM Instance Profile** to read from S3.  
- The **ALB listener rules** use path-based routing (`/red*`, `/blue*`).  
- All resources are deployed into the **default VPC**.  
- The `force_destroy = true` option in the S3 bucket automatically deletes all objects when the stack is destroyed.

---

## 📸 Example Output

After `terraform apply`, you’ll see something like:

```
Outputs:

alb_dns_name = "LabLoadBalancer-1234567890.us-east-1.elb.amazonaws.com"
red_instance_public_ip = "3.84.125.10"
blue_intance_public_ip = "54.210.43.12"
```

Access:
- http://LabLoadBalancer-1234567890.us-east-1.elb.amazonaws.com/red  
- http://LabLoadBalancer-1234567890.us-east-1.elb.amazonaws.com/blue  

---

## 👤 Author

**Your Name**  
📧 your.email@example.com  
💼 [LinkedIn](https://linkedin.com/in/yourprofile) | 🌍 [Portfolio](https://yourwebsite.com)
