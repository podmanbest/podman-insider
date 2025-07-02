cat <<EOF | tee /etc/containers/containers.conf
[containers]
pids_limit=0
EOF

cat <<EOF | tee /etc/containers/registries.conf
#/etc/containers/registries.conf
unqualified-search-registries = [
  "docker.io",
  "registry.access.redhat.com",
  "registry.redhat.io",
]

[[registry]]
insecure = true
prefix = "localhost"
location = "localhost"
short-name-mode = "enforcing"
EOF