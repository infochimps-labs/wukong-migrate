require 'spec_helper'

describe 'EsHttpOperation' do
  
  subject{ EsHttpOperation.receive(index: 'foo') }

  before(:each) do
    subject.configure_with(host: 'localhost', port: 9200)
  end
    
  context '#execute' do
    it 'calls its own http method' do
      subject.should_receive(:call_own_http_method).and_return 'a response'
      subject.execute.should eq('a response')
    end
  end

  context EsHttpOperation::CreateIndex do
    subject{ described_class.receive(index: 'foo', settings: { foo: 'bar' }) }

    its(:path) { should eq('/foo/')                     }
    its(:body) { should eq({ settings: { foo: 'bar' }}) }
    its(:verb) { should eq(:put)                        }
    its(:info) { should eq('Creating index foo')        }
    its(:raw_curl_string) do
      should eq("curl -X PUT 'http://localhost:9200/foo/' -d '{\"settings\":{\"foo\":\"bar\"}}'")
    end
  end

  context EsHttpOperation::DeleteIndex do
    subject{ described_class.receive(index: 'foo') }

    its(:path) { should eq('/foo/')              }
    its(:body) { should eq(nil)                  }
    its(:verb) { should eq(:delete)              }
    its(:info) { should eq('Deleting index foo') }
    its(:raw_curl_string) do
      should eq("curl -X DELETE 'http://localhost:9200/foo/'")
    end
  end

  context EsHttpOperation::UpdateIndexSettings do
    subject{ described_class.receive(index: 'foo', settings: { foo: 'bar'}) }

    its(:path) { should eq('/foo/_settings?')                 }
    its(:body) { should eq({ index: { foo: 'bar' }})          }
    its(:verb) { should eq(:put)                              }
    its(:info) { should eq('Updating settings for index foo') }
    its(:raw_curl_string) do
      should eq("curl -X PUT 'http://localhost:9200/foo/_settings?' -d '{\"index\":{\"foo\":\"bar\"}}'")
    end
  end

  context EsHttpOperation::AliasIndex do
    subject{ described_class.receive(index: 'foo', alias_name: 'bar', action: 'add', filter: { term: { foo: 'bar' }}) }

    its(:path) { should eq('/_aliases?')                                          }
    its(:body) { should eq({ actions: [{ add: { index: 'foo', alias: 'bar', filter: { term: { foo: 'bar' } } } }]}) }
    its(:verb) { should eq(:post)                                                 }
    its(:info) { should eq('Add alias :bar for index foo')                        }
    its(:raw_curl_string) do
      should eq("curl -X POST 'http://localhost:9200/_aliases?' -d '{\"actions\":[{\"add\":{\"index\":\"foo\",\"alias\":\"bar\",\"filter\":{\"term\":{\"foo\":\"bar\"}}}}]}'")
    end
  end

  context EsHttpOperation::UpdateIndexMapping do
    subject{ described_class.receive(index: 'foo', obj_type: 'bar', mapping: { dynamic: true }) }

    its(:path) { should eq('/foo/bar/_mapping?')                 }
    its(:body) { should eq({ 'bar' => { dynamic: true }  })      }
    its(:verb) { should eq(:put)                                 }
    its(:info) { should eq('Updating bar mapping for index foo') }
    its(:raw_curl_string) do
      should eq("curl -X PUT 'http://localhost:9200/foo/bar/_mapping?' -d '{\"bar\":{\"dynamic\":true}}'")
    end
  end
end
