#!/usr/bin/env python
import libvirt
import socket

return_data = dict()
conn = libvirt.openReadOnly()
try:
    domains = conn.listDomainsID()
    return_data['kvm_vms'] = len(domains)
    return_data['kvm_total_vcpus'] = conn.getCPUMap()[0]
    return_data['kvm_scheduled_vcpus'] = 0
    for domain in domains:
        return_data['kvm_scheduled_vcpus'] += conn.lookupByID(
            domain
        ).maxVcpus()
    return_data['kvm_host_id'] = abs(hash(socket.getfqdn()))
except Exception as exp:
    raise SystemExit('Plugin failure -- Reason: "%s"' % exp)
else:
    line_data = 'kvm '
    for key, value in return_data.items():
        line_data += '%s=%s,' % (key.replace(' ', '_'), value)
    else:
        line_data = line_data.rstrip(',')
    print(line_data)
finally:
    conn.close()
