eval $(ssh-agent -s)
ssh-add rke
rke --debug up --ssh-agent-auth