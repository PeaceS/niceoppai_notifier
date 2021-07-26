# frozen_string_literal: true

require './test/test_helper'
require './lib/html_object'

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
        'data' =>
          Base64.encode64(
            '{"source": "https://www.niceoppai.net", ' \
              '"structure": [{"lang": "en-US"}, {"body": null}, ' \
              '{"class": "wrap"}, {"id": "sct_col_l"}, ' \
              '{"id": "sct_wid_bot"}, {"ul": null}, {"li": null}, ' \
              '{"class": "con"}, {"class": "textwidget"}, ' \
              '{"class": "wpm_pag mng_lts_chp grp"}, {"class": "row", ' \
              '"loop": [{"class": "det"}, {"ul": null, "name_and_link": "a"}, ' \
              '{"li": null}, {"a": null}], "loop_thumbnail": [{"class": "cvr"}, ' \
              '{"class": "img_wrp"}, {"a": null}, {"img": null}]}]}'
          )
      }
    }
    make_cloud_event(payload, source: source, type: type)
  end

  it 'handle cannot reach error' do
    load_temporary 'app.rb' do
      WebMock
        .stub_request(:get, 'https://www.niceoppai.net')
        .to_return(status: 500)
      err =
        assert_raises RuntimeError do
          call_event :cartoons_list_update, event
        end
      assert_match 'Something wrong with http read', err.message
    end
  end

  it 'send arg to HtmlObject correctly' do
    load_temporary 'app.rb' do
      object = mock
      object.stubs(:cartoon_data).returns([])
      HtmlObject
        .expects(:new)
        .with(
          source: 'https://www.niceoppai.net',
          structure: [
            { 'lang' => 'en-US' },
            { 'body' => nil },
            { 'class' => 'wrap' },
            { 'id' => 'sct_col_l' },
            { 'id' => 'sct_wid_bot' },
            { 'ul' => nil },
            { 'li' => nil },
            { 'class' => 'con' },
            { 'class' => 'textwidget' },
            { 'class' => 'wpm_pag mng_lts_chp grp' },
            {
              'class' => 'row',
              'loop' => [
                { 'class' => 'det' },
                { 'ul' => nil, 'name_and_link' => 'a' },
                { 'li' => nil },
                { 'a' => nil }
              ],
              'loop_thumbnail' => [
                { 'class' => 'cvr' },
                { 'class' => 'img_wrp' },
                { 'a' => nil },
                { 'img' => nil }
              ]
            }
          ]
        )
        .returns(object)
        .once
      call_event :cartoons_list_update, event
    end
  end
end
