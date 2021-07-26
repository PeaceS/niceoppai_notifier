# frozen_string_literal: true

require './lib/html_object'
require './test/test_helper'
require 'httparty'

describe :html_object do
  it 'handle error from niceoppai.net' do
    WebMock
      .stub_request(:get, 'https://www.niceoppai.net')
      .to_return(status: 500)
    err =
      assert_raises RuntimeError do
        HtmlObject.new(source: 'https://www.niceoppai.net', structure: [{}])
          .cartoon_data
      end
    assert_match 'Something wrong with http read', err.message
  end

  describe 'real connect' do
    WebMock.allow_net_connect!

    it 'call success' do
      result =
        HtmlObject.new(
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
        ).cartoon_data

      assert_kind_of(Array, result)
      refute_empty(result)

      (0..4).each { |index| refute_nil(result.sample[index]) }

      (2..4).each { |index| assert(HTTParty.get(result.sample[index]).ok?) }

      sample_result = result.sample
      assert_kind_of(Float, sample_result[1]) if sample_result[5].nil?
    end
  end
end
