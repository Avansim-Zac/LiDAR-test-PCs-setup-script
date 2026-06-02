# LiDAR-test-PCs-setup-script
Run this script from the terminal to automatically install all required software and dependencies.


-Gemini- 
The Winner: Option 3 (With a Pro-Tip Upgrade)
For a team of developers using Ubuntu PCs, Option 3 (GitHub/Scripts) is the winner. It provides the best balance of ease of implementation, flexibility, and unique user management.

To take this approach to the next level, don't just write a messy Bash script. Look into Ansible.

Ansible is a free, open-source IT automation tool. Instead of writing complex bash commands, you write a simple setup.yml file (called a Playbook) that looks like this:

YAML
- name: Install Development Tools
  hosts: localhost
  tasks:
    - name: Install VS Code and Git
      apt:
        name: 
          - code
          - git
        state: present
You can host your Ansible playbook on GitHub. When a new developer gets a PC, they just run one or two commands to clone the repo and run Ansible. It will configure their machine exactly like the golden PC, but keep their unique username and hostname intact.

To give you the most accurate advice on how to structure this script or playbook, what specific IDEs, tools, or heavy dependencies (like databases or specific SDKs) do your developers need installed?
