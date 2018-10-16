require 'serverspec'

# Required by serverspec
set :backend, :exec

describe file('/var/log/osquery_syslog-prog.log') do
  it { should be_file }
#  its(:content) { should match /osqueryd: osqueryd started \[version=/ }
  its(:content) { should match /Executing scheduled query system_info:/ }
  its(:content) { should_not match /Rocksdb open failed \(5:0\) IO error:/ }
  its(:content) { should_not match /osqueryd initialize failed: Could not initialize database/ }
end
describe file('/var/log/osquery_syslog-results.log') do
  it { should be_file }
  its(:content) { should match /hostIdentifier/ }
#  its(:content) { should match /pack/ }
  its(:content) { should match /message=Executing scheduled query system_info:/ }
  its(:content) { should_not match /kernel: Cannot access \/dev\/osquery/ }
  let(:sudo_options) { '-u root -H' }
end

describe command('journalctl -l') do
  its(:stdout) { should match /osqueryd/ }
  its(:stdout) { should match /Executing scheduled query system_info:/ }
  its(:stdout) { should match /hostIdentifier/ }
  its(:exit_status) { should eq 0 }
end
