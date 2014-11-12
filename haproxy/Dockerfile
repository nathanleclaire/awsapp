from ubuntu:14.04

run \
  apt-get update && \
  apt-get install -y haproxy && \
  rm -rf /var/lib/apt/lists/*

add haproxy.cfg /etc/haproxy/haproxy.cfg
run echo 'EXTRAOPTS="-db"' >>/etc/default/haproxy

cmd ["haproxy", "-f", "/etc/haproxy/haproxy.cfg", "-p", "-/var/run/haproxy.pid"]

expose 80
expose 443
