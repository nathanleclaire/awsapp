from ubuntu:14.04

# Install Haproxy.
run \
  apt-get update && \
  apt-get install -y haproxy && \
  rm -rf /var/lib/apt/lists/*

add haproxy.cfg /etc/haproxy/haproxy.cfg
run echo 'EXTRAOPTS="-db"' >>/etc/default/haproxy

# Define default command.
cmd ["haproxy", "-f", "/etc/haproxy/haproxy.cfg", "-p", "-/var/run/haproxy.pid"]

# Expose ports.
expose 80
expose 443
