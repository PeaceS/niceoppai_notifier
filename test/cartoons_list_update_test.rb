# frozen_string_literal: true

require './test/test_helper'

describe :cartoons_list_update do
  include FunctionsFramework::Testing

  let(:resource_type) { 'type.googleapis.com/google.pubsub.v1.PubsubMessage' }
  let(:source) { '//pubsub.googleapis.com/projects/niceoppai-notifier/topics/update_cartoon_list' }
  let(:type) { 'google.cloud.pubsub.topic.v1.messagePublished' }

  it 'handle error from niceoppai.net' do
    load_temporary 'app.rb' do
      WebMock.stub_request(:get, 'https://www.niceoppai.net').to_return(status: 500)
      payload = { '@type' => resource_type, 'message' => { 'data' => Base64.encode64('Ruby') } }
      event = make_cloud_event payload, source: source, type: type
      err = assert_raises RuntimeError do
        call_event :cartoons_list_update, event
      end
      assert_match 'Something wrong with http read', err.message
    end
  end

  it 'prints a name' do
    skip 'will come back to this'
    load_temporary 'app.rb' do
      payload = { '@type' => resource_type, 'message' => { 'data' => Base64.encode64('Ruby') } }
      event = make_cloud_event payload, source: source, type: type
      _out, err = capture_subprocess_io do
        # Call tested function
        call_event :cartoons_list_update, event
      end
      assert_match(/Hello, Ruby!/, err)
    end
  end
end
