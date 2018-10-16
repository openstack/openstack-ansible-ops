require 'serverspec'

# Required by serverspec
set :backend, :exec

describe file('/var/log/osquery/osqueryd.results.log') do
  it { should contain '"system_info",' }
  it { should contain '"physical_memory":' }
  it { should contain '"target_path":"\/etc\/testing-big-file"' }
  it { should contain '"target_path":"\/etc\/testing-aa"' }
  it { should contain '"target_path":"\/etc\/testing-zz' }
  it { should contain '"action":"CREATED"' }
  it { should contain '"action":"UPDATED"' }
  it { should contain '"action":"DELETED"' }
  it { should_not contain '"target_path":"\/tmp\/' }
  it { should_not contain '"target_path":"\/var\/' }
end
