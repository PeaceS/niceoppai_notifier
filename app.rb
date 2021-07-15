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

  objects = objects.map do |obj|
    object = find_by(object: obj, type: 'class', value: 'det')
    name_object = find_by_name(object: object, name: 'a')
    name = name_object.children[0].text.strip
    object = find_by_name(object: object, name: 'ul')
    object = find_by_name(object: object, name: 'li')
    object = find_by_name(object: object, name: 'a')
    [name, name_object.attributes['href'].value, object.attributes['href'].value.split('/').last.to_f, object.attributes['href'].value]
  end

  firestore = Google::Cloud::Firestore.new project_id: PROJECT_ID, credentials: 'keys/niceoppai-notifier-bea93adf3021.json'

  puts "total of #{objects.size} cartoons in the list"
  created_list = []

  latest_chapters = firestore.transaction do |transaction|
    objects.map do |data|
      doc = firestore.doc format('%<collection>s/%<name>s', collection: CARTOON_LIST_COLLECTION, name: data[0])
      transaction.get(doc).data&.[](:latest_chapter)
    end
  end

  updated_list = objects.zip(latest_chapters).map do |data, latest_chapter|
    next if latest_chapter && latest_chapter == data[2].to_f

    doc = firestore.doc(format('%<collection>s/%<name>s', collection: CARTOON_LIST_COLLECTION, name: data[0]))
    doc.set({
      link: data[1],
      latest_chapter: data[2],
      latest_link: data[3]
    }, merge: true)

    unless latest_chapter
      created_list << data[0]
      nil
    else
      data[0]
    end
  end.compact

  puts "created new #{created_list.size} cartoons, updated #{updated_list.size} cartoons"

  unless updated_list.empty?
    puts 'updated list:'
    updated_list.each { |cartoon| puts cartoon }
  end

  unless created_list.empty?
    puts 'created list:'
    created_list.each { |cartoon| puts cartoon }
  end

  'ok'
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
