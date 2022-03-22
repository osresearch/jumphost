To run the receiving side:
```
echo '*.* /dev/tty' > syslog-sink.conf
./syslogd \
  -a '*:*' \
  -d \
  -b :9999 \
  -p /tmp/syslog2 \
  -f syslog-sink.conf \
  -K 
```
