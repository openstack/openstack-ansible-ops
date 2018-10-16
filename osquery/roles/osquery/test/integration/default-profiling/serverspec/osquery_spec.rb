require 'serverspec'

# Required by serverspec
set :backend, :exec

describe service('osqueryd'), :if => (os[:family] == 'ubuntu' && os[:release] != '16.04') && (os[:family] != 'redhat') do
## mostly exclude for docker/systemd distributions
  it { should be_enabled }
end
describe service('osqueryd') do
  it { should be_running }
end

describe file('/usr/bin/osqueryd') do
  it { should be_executable }
end
describe file('/usr/bin/osqueryi') do
  it { should be_executable }
end

describe file('/etc/osquery/osquery.conf') do
  it { should contain '"config_plugin":' }
  it { should contain '"packs": {' }
  it { should contain '"filesystem"' }
end

describe process("osqueryd") do
  its(:user) { should eq "root" }
  its(:args) { should match /--config_path[= ]\/etc\/osquery\/osquery.conf/ }
  its(:args) { should match /--flagfile[= ]\/etc\/osquery\/osquery.flags/ }
end

describe file('/var/log/osquery/osqueryd.INFO') do
  it { should be_symlink }
  its(:content) { should match /Log line format:/ }
end
describe file('/var/log/osquery/osqueryd.WARNING') do
  it { should be_symlink }
  its(:content) { should match /Log line format:/ }
  its(:content) { should_not match /kernel: Cannot access \/dev\/osquery/ }
end
describe file('/var/log/osquery/osqueryd.results.log') do
  it { should be_file }
#  its(:content) { should match /hostIdentifier/ }
  let(:sudo_options) { '-u root -H' }
end

describe command('systemctl status osqueryd'), :if => (os[:family] == 'ubuntu' && os[:release] == '14.04') do
  its(:stdout) { should match /osqueryd is already running/ }
  its(:exit_status) { should eq 0 }
end
describe command('systemctl status osqueryd'), :if => os[:family] == 'ubuntu' && (os[:release] == '16.04' || os[:release] == '18.04') do
  its(:stdout) { should match /active \(running\)/ }
  its(:exit_status) { should eq 0 }
end
describe command('systemctl status osqueryd'), :if => os[:family] == 'redhat' do
  its(:stdout) { should match /active \(running\)/ }
  its(:exit_status) { should eq 0 }
end
