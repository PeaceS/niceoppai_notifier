# frozen_string_literal: true

require './test/test_helper'

describe :cartoons_list_update do
  include FunctionsFramework::Testing

  let(:resource_type) { 'type.googleapis.com/google.pubsub.v1.PubsubMessage' }
  let(:source) do
    '//pubsub.googleapis.com/projects/niceoppai-notifier/topics/update_cartoon_list'
  end
  let(:type) { 'google.cloud.pubsub.topic.v1.messagePublished' }
  let(:event) do
    payload = {
      '@type' => resource_type,
      'message' => {
        'data' => Base64.encode64('Ruby')
      }
    }
    make_cloud_event(payload, source: source, type: type)
  end

  it 'handle error from niceoppai.net' do
    skip 'this remove to lib test'
    WebMock
      .stub_request(:get, 'https://www.niceoppai.net')
      .to_return(status: 500)
    load_temporary 'app.rb' do
      err =
        assert_raises RuntimeError do
          call_event :cartoons_list_update, event
        end
      assert_match 'Something wrong with http read', err.message
    end
  end
end
