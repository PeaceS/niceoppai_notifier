# frozen_string_literal: true

require './lib/html_object'
require './test/test_helper'

describe :html_object do
  it 'handle error from niceoppai.net' do
    WebMock
      .stub_request(:get, 'https://www.niceoppai.net')
      .to_return(status: 500)
    err =
      assert_raises RuntimeError do
        cartoon_data(source: 'https://www.niceoppai.net', structure: [{}])
      end
    assert_match 'Something wrong with http read', err.message
  end

  describe 'real connect' do
    WebMock.allow_net_connect!

    it 'call success' do
      result = cartoon_data(source: 'https://www.niceoppai.net', structure: [
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
        { 'class' => 'row', 'loop' => [
          { 'class' => 'det' },
          { 'ul' => nil, 'save' => 'a' },
          { 'li' => nil },
          { 'a' => nil }
        ]}
      ])

      assert_kind_of(Array, result)
      refute_empty(result)

      refute_nil(result.sample[0])
      refute_nil(result.sample[1])
      refute_nil(result.sample[3])

      sample_result = result.sample
      assert_kind_of(Float, sample_result[2]) if sample_result[4].nil?
    end
  end
end
