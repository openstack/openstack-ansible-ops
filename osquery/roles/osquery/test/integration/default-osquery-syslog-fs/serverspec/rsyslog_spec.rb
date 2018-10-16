require 'serverspec'

# Required by serverspec
set :backend, :exec

describe service('rsyslog'), :if => (os[:family] == 'ubuntu' && os[:release] != '16.04') || (os[:family] == 'redhat' && os[:release] != '7') do
  it { should be_enabled }
end
describe service('rsyslog') do
  it { should be_running }
end

describe file('/usr/sbin/rsyslogd') do
  it { should be_executable }
end

describe process("rsyslogd"), :if => os[:family] == 'ubuntu' do
  its(:user) { should eq "syslog" }
end
describe process("rsyslogd"), :if => os[:family] == 'redhat' do
  its(:user) { should eq "root" }
end

describe file('/var/log'), :if => os[:family] == 'ubuntu' do
  it { should be_directory }
  it { should be_mode 775 }
  it { should be_owned_by 'root' }
  it { should be_grouped_into 'syslog' }
#  it { should be_writable.by('group') }
  it { should be_writable.by_user('syslog') }
end
describe file('/var/log'), :if => os[:family] == 'redhat' do
  it { should be_directory }
  it { should be_mode 755 }
  it { should be_owned_by 'root' }
  it { should be_grouped_into 'root' }
#  it { should be_writable.by('group') }
end

describe file('/var/log/syslog'), :if => os[:family] == 'ubuntu' do
  it { should be_file }
end

describe file('/var/log/messages'), :if => os[:family] == 'redhat' do
  it { should be_file }
end

