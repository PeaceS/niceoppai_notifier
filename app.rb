# frozen_string_literal: true

# This file contains Google Cloud Functions
# - cartoons_list_update:
#   Fetch list of cartoon update, and check that each need to update to db or not
#   Trigger by Google Cloud Scheduler, cron job on every hour
# - cartoon_update
#   Check on every cartoon update that it needs to notify to any subscriber or not
#   Trigger by Google Firestore update

require 'functions_framework'

PROJECT_ID = 'niceoppai-notifier'
CARTOON_LIST_COLLECTION = 'cartoons'
ACCOUNT_LIST_COLLECTION = 'accounts'

FunctionsFramework.cloud_event :cartoons_list_update do |_event|
  require 'httparty'
  require 'nokogiri'
  require 'google/cloud/firestore'

  response = HTTParty.get('https://www.niceoppai.net')
  if response.body.nil? || response.body.empty?
    raise 'Something wrong with http read'
  end

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

  firestore =
    Google::Cloud::Firestore.new project_id: PROJECT_ID,
                                 credentials: 'keys/firestore.json'

  logger.info "total of #{cartoon_data.size} cartoons in the list"

  latest_chapters =
    firestore.transaction do |transaction|
      cartoon_data.map do |data|
        doc =
          firestore.doc format(
                          '%<collection>s/%<name>s',
                          collection: CARTOON_LIST_COLLECTION,
                          name: data[0]
                        )
        transaction.get(doc).data&.[](:latest_chapter)
      end
    end

  updated_list =
    cartoon_data
      .zip(latest_chapters)
      .map do |data, latest_chapter|
        if latest_chapter &&
             (latest_chapter.to_f - data[2].to_f).abs < Float::EPSILON
          next
        end

        doc =
          firestore.doc(
            format(
              '%<collection>s/%<name>s',
              collection: CARTOON_LIST_COLLECTION,
              name: data[0]
            )
          )
        doc.set(
          {
            link: data[1],
            latest_chapter: data[2],
            latest_link: data[3],
            language: data[4] || 'TH'
          },
          merge: true
        )

        data[0]
      end
      .compact

  if !updated_list.empty?
    logger.info "updated #{updated_list.size} cartoons"
    logger.info 'updated list:'
    updated_list.each { |cartoon| logger.info cartoon }
  else
    logger.info 'no updated cartoons'
  end
end

FunctionsFramework.cloud_event :cartoon_update do |event|
  require 'line-notify-client'
  require 'google/cloud/firestore'

  payload = event.data

  updated = payload['value']['fields']
  new_chapter = updated['latest_chapter'].first.last
  old_chapter = payload['oldValue']['fields']['latest_chapter'].first.last

  break unless old_chapter != new_chapter

  cartoon_name = payload['value']['name'].split('/').last
  message = "[#{cartoon_name}] #{old_chapter} -> #{new_chapter}"
  logger.info message

  firestore =
    Google::Cloud::Firestore.new project_id: PROJECT_ID,
                                 credentials: 'keys/firestore.json'

  subscribers =
    updated['subscribers']['arrayValue']['values'].map(&:values).flatten

  subscriber_tokens =
    firestore.transaction do |transaction|
      subscribers.map do |subscriber|
        doc =
          firestore.doc(
            format(
              '%<collection>s/%<id>s',
              collection: ACCOUNT_LIST_COLLECTION,
              id: subscriber
            )
          )
        transaction.get(doc).data&.[](:token)
      end
    end

  message += ", link: #{updated['latest_link'].first.last}"
  subscriber_tokens.each do |token|
    Line::Notify::Client.message(token: token, message: message)
  end
rescue NoMethodError => _e
  logger.info 'No subscribers list'
end

def find_by(object:, type:, value: nil)
  if value
    object.children.find { |data| data.attributes[type]&.value == value }
  else
    object.children.find { |data| data.name == type }
  end
end

def loop_by(object:, type:, value:)
  object.children.select { |data| data.attributes[type]&.value == value }
end
