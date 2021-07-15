require 'functions_framework'

PROJECT_ID = 'niceoppai-notifier'.freeze
CARTOON_LIST_COLLECTION = 'cartoons'.freeze

FunctionsFramework.http :update_cartoon_list do |_request|
  require 'httparty'
  require 'nokogiri'
  require 'google/cloud/firestore'

  response = HTTParty.get('https://www.niceoppai.net')
  raise 'Something wrong with http read' if response.body.nil? || response.body.empty?

  html = Nokogiri::HTML(response.body)

  object = find_by(object: html, type: 'lang', value: 'en-US')
  object = find_by_name(object: object, name: 'body')
  object = find_by(object: object, type: 'class', value: 'wrap')
  object = find_by(object: object, type: 'id', value: 'sct_col_l')
  object = find_by(object: object, type: 'id', value: 'sct_wid_bot')
  object = find_by_name(object: object, name: 'ul')
  object = find_by_name(object: object, name: 'li')
  object = find_by(object: object, type: 'class', value: 'con')
  object = find_by(object: object, type: 'class', value: 'textwidget')
  object = find_by(object: object, type: 'class', value: 'wpm_pag mng_lts_chp grp')
  objects = loop_by(object: object, type: 'class', value: 'row')

  data = objects.map do |obj|
    object = find_by(object: obj, type: 'class', value: 'det')
    name_object = find_by_name(object: object, name: 'a')
    name = name_object.children[0].text.strip
    object = find_by_name(object: object, name: 'ul')
    object = find_by_name(object: object, name: 'li')
    object = find_by_name(object: object, name: 'a')
    [name, name_object.attributes['href'].value, object.attributes['href'].value.split('/').last.to_f, object.attributes['href'].value]
  end

  firestore = Google::Cloud::Firestore.new project_id: PROJECT_ID, credentials: 'keys/niceoppai-notifier-bea93adf3021.json'

  puts "total of #{data.size} cartoons in the list"
  data.each do |d|
    doc = firestore.doc format('%<collection>s/%<name>s', collection: CARTOON_LIST_COLLECTION, name: d[0])

    dd = {
      link: d[1],
      latest_chapter: d[2],
      latest_link: d[3]
    }

    doc.set(dd, merge: true)
  end

  'created / updated'
end

def find_by(object:, type:, value:)
  object.children.find do |data|
    data.attributes[type]&.value == value
  end
end

def find_by_name(object:, name:)
  object.children.find { |data| data.name == name }
end

def loop_by(object:, type:, value:)
  object.children.select do |data|
    data.attributes[type]&.value == value
  end
end

# FunctionsFramework.cloud_event :create_next_week_training_run do |event|
#   require 'json'
#   require 'active_support'
#   require 'google/cloud/firestore'
#   require 'active_support/core_ext/numeric/time.rb'
#   require_relative 'model/google/calendar'
#   require_relative 'lib/training_time'
#   require_relative 'lib/next_counter'

#   data = Base64.decode64 event.data['message']['data'] rescue '-'
#   puts "data from pub: #{data}"
#   check = JSON.parse(data)['training_run']['activate'] rescue false
#   return 'Not running' unless check

#   start_on_week = JSON.parse(data)['training_run']['start_on_week'].to_i rescue 1

#   running_calendar = Google::Calendar.new(name: RUNNING_CALENDAR_NAME)
#   latest_date, counter = running_calendar.latest_event(RUNNING_EVENT_NAME)
#   counter = next_counter(counter, start_on_week)

#   puts "Next tranning: week-#{counter} on #{latest_date.next_occurring(:tuesday)}"

#   firestore = Google::Cloud::Firestore.new project_id: PROJECT_ID

#   collection = format('training/week-%<counter>d', counter: counter)
#   training_ref = firestore.doc collection
#   training_schedule = training_ref.get

#   training_schedule.data.each do |day, data|
#     start_time = Time.parse(data[:start_time] || '18:00')
#     next_training_date = latest_date.next_occurring(day)
#     next_training_date = DateTime.new(next_training_date.year, next_training_date.month, next_training_date.day, start_time.hour, start_time.min, 0, '+07:00')
#     running_calendar.create(
#       title: format('%<distance>.1f km %<event_name>s', distance: data[:distance], event_name: RUNNING_EVENT_NAME),
#       start_time: next_training_date,
#       end_time: next_training_date + training_time(data[:distance].to_f),
#       note: format('%<event_name>s Week%<counter>d', event_name: RUNNING_EVENT_NAME, counter: counter)
#     )
#   end

#   format('Created %<event>s schedule for week %<counter>d', event: RUNNING_EVENT_NAME, counter: counter)
# end


