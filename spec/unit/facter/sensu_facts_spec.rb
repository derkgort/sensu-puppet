require "spec_helper"
require 'facter/sensugo_facts'

describe "SensuGoFacts" do
  context 'sensugo_agent fact' do
    it 'returns version information' do
      allow(SensuGoFacts).to receive(:which).with('sensu-agent').and_return('/bin/sensu-agent')
      allow(Facter::Core::Execution).to receive(:exec).with('/bin/sensu-agent version 2>&1').and_return("sensu-agent version 5.1.0#b2ea9fc, build b2ea9fcdb21e236e6e9a7de12225a6d90c786c57, built '2018-12-18T21:31:11+0000'")
      SensuGoFacts.add_agent_facts
      expect(Facter.fact(:sensugo_agent).value).to eq({'version' => '5.1.0', 'build' => 'b2ea9fcdb21e236e6e9a7de12225a6d90c786c57', 'built' => '2018-12-18T21:31:11+0000'})
    end

    it 'returns version information for 5.2.0' do
      allow(SensuGoFacts).to receive(:which).with('sensu-agent').and_return('/bin/sensu-agent')
      allow(Facter::Core::Execution).to receive(:exec).with('/bin/sensu-agent version 2>&1').and_return("sensu-agent version 5.2.0#21a24d9, build 21a24d9cf073863d6c2b02c0b7acaae673e4f597, built 2019-02-06T22:08:44Z")
      SensuGoFacts.add_agent_facts
      expect(Facter.fact(:sensugo_agent).value).to eq({'version' => '5.2.0', 'build' => '21a24d9cf073863d6c2b02c0b7acaae673e4f597', 'built' => '2019-02-06T22:08:44Z'})
    end

    it 'returns nil' do
      allow(SensuGoFacts).to receive(:which).with('sensu-agent').and_return(nil)
      SensuGoFacts.add_agent_facts
      expect(Facter.fact(:sensugo_agent).value).to be_nil
    end
  end

  context 'sensugo_backend fact' do
    it 'returns version information' do
      allow(SensuGoFacts).to receive(:which).with('sensu-backend').and_return('/bin/sensu-backend')
      allow(Facter::Core::Execution).to receive(:exec).with('/bin/sensu-backend version 2>&1').and_return("sensu-backend version 5.1.0#b2ea9fc, build b2ea9fcdb21e236e6e9a7de12225a6d90c786c57, built '2018-12-18T21:31:11+0000'")
      SensuGoFacts.add_backend_facts
      expect(Facter.fact(:sensugo_backend).value).to eq({'version' => '5.1.0', 'build' => 'b2ea9fcdb21e236e6e9a7de12225a6d90c786c57', 'built' => '2018-12-18T21:31:11+0000'})
    end

    it 'returns nil' do
      allow(Facter::Core::Execution).to receive(:which).with('sensu-backend').and_return(nil)
      SensuGoFacts.add_backend_facts
      expect(Facter.fact(:sensugo_backend).value).to be_nil
    end
  end

  context 'sensuctl fact' do
    it 'returns version information' do
      allow(SensuGoFacts).to receive(:which).with('sensuctl').and_return('/bin/sensuctl')
      allow(Facter::Core::Execution).to receive(:exec).with('/bin/sensuctl version 2>&1').and_return("sensuctl version 5.1.0#b2ea9fc, build b2ea9fcdb21e236e6e9a7de12225a6d90c786c57, built '2018-12-18T21:31:11+0000'")
      SensuGoFacts.add_sensuctl_facts
      expect(Facter.fact(:sensuctl).value).to eq({'version' => '5.1.0', 'build' => 'b2ea9fcdb21e236e6e9a7de12225a6d90c786c57', 'built' => '2018-12-18T21:31:11+0000'})
    end

    it 'returns nil' do
      allow(SensuGoFacts).to receive(:which).with('sensuctl').and_return(nil)
      SensuGoFacts.add_sensuctl_facts
      expect(Facter.fact(:sensuctl).value).to be_nil
    end
  end
end
