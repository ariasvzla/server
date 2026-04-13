---
all:
  children:
    control_plane:
      hosts:
%{ for cp in control_planes ~}
        ${cp.name}:
          ansible_host: ${cp.ip}
%{ endfor ~}
    workers:
      hosts:
%{ for worker in workers ~}
        ${worker.name}:
          ansible_host: ${worker.ip}
%{ endfor ~}
  vars:
    ansible_user: ${ansible_user}
    ansible_ssh_private_key_file: ~/.ssh/id_rsa
    ansible_python_interpreter: /usr/bin/python3
