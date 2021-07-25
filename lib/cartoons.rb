# frozen_string_literal: true

require 'httparty'
require 'nokogiri'
require_relative 'lib/html_object'

def cartoon_data(source:, structure:)
  body = body(source)
end

private

def body(source)
  response = HTTParty.get('https://www.niceoppai.net', follow_redirects: false)
  (response.body.nil? || response.body.empty?) &&
    raise('Something wrong with http read')

  Nokogiri.HTML(response.body)
end

response = HTTParty.get('https://www.niceoppai.net', follow_redirects: false)
  (response.body.nil? || response.body.empty?) &&
    raise('Something wrong with http read')

  html_objects = Nokogiri.HTML(response.body)

  html_objects =
    [
      html_objects,
      { 'lang' => 'en-US' },
      { 'body' => nil },
      { 'class' => 'wrap' },
      { 'id' => 'sct_col_l' },
      { 'id' => 'sct_wid_bot' },
      { 'ul' => nil },
      { 'li' => nil },
      { 'class' => 'con' },
      { 'class' => 'textwidget' },
      { 'class' => 'wpm_pag mng_lts_chp grp' }
    ].reduce do |object, node|
      find_by(object: object, type: node.first[0], value: node.first[1])
    end

  html_objects = loop_by(object: html_objects, type: 'class', value: 'row')

  cartoon_data =
    html_objects.map do |html_object|
      html_object = find_by(object: html_object, type: 'class', value: 'det')

      name_object = find_by(object: html_object, type: 'a')
      name = name_object.children[0].text.strip

      html_object =
        [
          html_object,
          { 'ul' => nil },
          { 'li' => nil },
          { 'a' => nil }
        ].reduce do |object, node|
          find_by(object: object, type: node.first[0], value: node.first[1])
        end

      chapter = html_object.attributes['href'].value.split('/').last
      chapter, lang =
        begin
          Float chapter
        rescue _
          chapter.split('-')
        end

      [
        name,
        name_object.attributes['href'].value,
        chapter,
        html_object.attributes['href'].value,
        lang
      ]
    end

  