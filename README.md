# Bite Force — Mini SOC Lab

**Spin it up. Make some noise. Catch the activity.**

Bite Force is a small Linux monitoring lab built for the Zetech Forge Alumni × Student Hackathon.

We use AWS, Wazuh, Suricata and Apache to monitor a Linux machine, detect suspicious activity and investigate the evidence from one dashboard.

## What's in the lab?

- **Wazuh Server:** Manager, Indexer and Dashboard.
- **Linux Victim:** The machine we monitor and test.
- **Wazuh Agent:** Sends endpoint events to Wazuh.
- **Suricata:** Provides network visibility.
- **Apache/PHP:** Gives us a web server to monitor.
- **Terraform:** Builds the AWS infrastructure.

## 1. Before you launch

You'll need:

- An AWS account.
- AWS CLI credentials configured.
- Terraform installed.
- Access to the Wazuh Marketplace AMI.
- An EC2 key pair named `debkey` in the `eu-north-1` region (Stockholm).

Make sure you've accepted the Wazuh Marketplace terms before deploying.

## 2. Deploy the infrastructure

Clone the repository:

```bash
git clone https://github.com/jameskipngetich/BiteForce-minisoc-lab.git
cd BiteForce-minisoc-lab
```

Initialise Terraform:

```bash
terraform init
```

Validate the configuration:

```bash
terraform validate
terraform plan
```

If everything looks good, deploy:

```bash
terraform apply
```

Type `yes` when prompted.

Terraform creates the Wazuh server, Linux victim, VPC, subnet, internet gateway and security group.

**Heads-up:** The current security group allows SSH (22) and dashboard access (443) from anywhere. Restrict these to trusted IP addresses before using the lab beyond a short demonstration.

## 3. Get your instance details

Once deployment finishes:

```bash
terraform output
```

You'll get several outputs:

| Output | Purpose |
|---|---|
| `wazuh-server-pub-ip` | Wazuh dashboard address |
| `wazuh-server-priv-dns` | Wazuh server private DNS |
| `wazuh-server-instance-id` | Initial dashboard password |
| `linux-victim-public-ip` | Victim SSH address |

Need a specific value?

```bash
terraform output -raw wazuh-server-pub-ip
terraform output -raw wazuh-server-instance-id
terraform output -raw linux-victim-public-ip
```

### Access the Wazuh Dashboard

Open:

```text
https://<WAZUH_SERVER_PUBLIC_IP>
```

Login:

- **Username:** `admin`
- **Password:** Your Wazuh instance ID, with the first letter capitalised.

For example:

```text
Instance ID: i-07f25f6afe4789342
Password:    I-07f25f6afe4789342
```

That's a capital **I**, not a lowercase **i**.

Give the instance a few minutes to complete its first-boot setup. Your browser may show a certificate warning because the lab uses a self-signed certificate.

### SSH access

Wazuh server:

```bash
ssh -i [your_priv_key].pem wazuh-user@<WAZUH_SERVER_PUBLIC_IP>
```

Linux victim:

```bash
ssh -i [your_priv_key].pem ubuntu@<VICTIM_PUBLIC_IP>
```

Use the actual path to your private key if necessary. Never upload your `.pem` file to GitHub.

## 4. Connect the victim to Wazuh

Get the Wazuh server's **private IP** from the EC2 console.

On the victim, install and enrol the Wazuh agent using the official Wazuh instructions for Ubuntu.

Set the manager address to:

```text
<WAZUH_SERVER_PRIVATE_IP>
```

The agent communicates with the manager over TCP port `1514`. Port `1515` is used for enrolment when using the enrolment service.

Check the agent:

```bash
sudo systemctl status wazuh-agent
```

Then open the Wazuh Dashboard and check **Agents**. Your victim should appear as active.

## 5. Configure the detections

Extract the configuration bundle into a `configs/` directory in this repository.

It should look like this:

```text
configs/
├── manager/
│   └── local_rules.xml
├── agent/
│   └── ossec.conf.fragment.xml
└── suricata/
    └── suricata.yaml.fragment
```

These configurations reconstruct the behaviour documented during the hackathon. They are not backups of the original server files, so validate them on your deployed versions.

### A. Wazuh Manager rules

On the Wazuh server, the custom rules belong in:

```text
/var/ossec/etc/rules/local_rules.xml
```

Back up the existing file first:

```bash
sudo cp /var/ossec/etc/rules/local_rules.xml \
  /var/ossec/etc/rules/local_rules.xml.bak
```

Merge the Bite Force rules into the existing file. Preserve any other custom rules.

Our custom rules:

| Rule ID | Detection |
|---|---|
| `100101` | Repeated SSH authentication failures |
| `100401` | Suricata TLS events to destination port 443 |

Test the rules:

```bash
sudo /var/ossec/bin/wazuh-logtest
```

Then restart the manager:

```bash
sudo systemctl restart wazuh-manager
```

### B. Wazuh Agent configuration

On the Linux victim, edit:

```bash
sudo nano /var/ossec/etc/ossec.conf
```

Merge the relevant settings from:

```text
configs/agent/ossec.conf.fragment.xml
```

These settings cover:

- Monitoring `/etc/passwd` and `/etc/shadow`.
- Realtime File Integrity Monitoring.
- Protecting `/etc/shadow` with `nodiff`.
- Authentication logs.
- Apache access and error logs.
- Suricata EVE JSON.

Don't replace the entire agent configuration. Keep its existing manager connection settings and merge the new entries into the existing sections.

Restart the agent:

```bash
sudo systemctl restart wazuh-agent
```

### C. Suricata

Use this file as a configuration guide:

```text
configs/suricata/suricata.yaml.fragment
```

Merge the relevant settings into:

```bash
sudo nano /etc/suricata/suricata.yaml
```

Our original lab monitored interface `ens5`.

Check the actual interface:

```bash
ip -br link
```

Make sure Suricata writes EVE JSON to:

```text
/var/log/suricata/eve.json
```

The EVE output should include TLS and flow events. The Wazuh agent must also be able to read this file.

Restart Suricata after configuring it:

```bash
sudo systemctl restart suricata
```

### D. Apache/PHP

Install Apache and PHP on the victim and create the monitored upload directory:

```bash
sudo mkdir -p /var/www/html/uploads
```

This is where we'll create harmless test files to demonstrate file detection.

## 6. What are we detecting?

These are the detections demonstrated by Bite Force:

| Challenge | Rule ID | What happens |
|---|---:|---|
| SSH brute force | `100101` | Repeated failed SSH logins |
| Account-file integrity | `550` | Changes to `/etc/passwd` and `/etc/shadow` |
| PHP upload | `554` | A new file appears in the monitored upload directory |
| Outbound TLS telemetry | `100401` | Suricata observes TLS activity on port 443 |

Rules `550` and `554` are built-in Wazuh rules. You don't need to add them to `local_rules.xml`.

### Finding alerts

In the Wazuh Dashboard, navigate to:

**Threat Hunting → Events**

Example search:

```text
rule.id:100101 AND agent.id:001
```

Other searches:

```text
rule.id:550 AND agent.id:001
rule.id:554 AND agent.id:001
rule.id:100401 AND agent.id:001
```

Replace the agent ID if your victim receives a different one.

**A quick note on our results:** The Apache HTTP request was documented using access logs and Wazuh decoder evidence, not a verified custom alert. Full L4 attribution was left as follow-up work. We report what we actually observed, not what we wish we had detected.

## 7. Stay safe

- Only test systems you own or have permission to monitor.
- Never commit AWS credentials, private keys or passwords.
- Never publish `/etc/shadow` contents or password hashes.
- Restrict SSH and dashboard access to trusted IP addresses.
- Change the initial dashboard password after logging in.

---

## That's Bite Force!

Build the lab. Generate controlled activity. Follow the evidence. See what your detections catch.

**Happy hunting.**
