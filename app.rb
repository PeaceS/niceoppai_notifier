require 'functions_framework'

PROJECT_ID = 'niceoppai-notifier'.freeze
CARTOON_LIST_COLLECTION = 'cartoons'.freeze

FunctionsFramework.http :update_cartoon_list do |_request|
  require 'httparty'
  require 'nokogiri'
  require 'google/cloud/firestore'

  response = HTTParty.get('https://www.niceoppai.net')
  raise 'Something wrong with http read' if response.body.nil? || response.body.empty?

  html_object = Nokogiri::HTML(response.body)

  html_object = [
    html_object,
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

  html_objects = loop_by(object: html_object, type: 'class', value: 'row')

  cartoon_data = html_objects.map do |html_object|
    html_object = find_by(object: html_object, type: 'class', value: 'det')

    name_object = find_by(object: html_object, type: 'a')
    name = name_object.children[0].text.strip

    html_object = [
      html_object,
      { 'ul' => nil },
      { 'li' => nil },
      { 'a' => nil },
    ].reduce do |object, node|
      find_by(object: object, type: node.first[0], value: node.first[1])
    end

    [
      name,
      name_object.attributes['href'].value,
      html_object.attributes['href'].value.split('/').last.to_f,
      html_object.attributes['href'].value
    ]
  end

  firestore = Google::Cloud::Firestore.new project_id: PROJECT_ID, credentials: 'keys/niceoppai-notifier-bea93adf3021.json'

  puts "total of #{cartoon_data.size} cartoons in the list"

  latest_chapters = firestore.transaction do |transaction|
    cartoon_data.map do |data|
      doc = firestore.doc format('%<collection>s/%<name>s', collection: CARTOON_LIST_COLLECTION, name: data[0])
      transaction.get(doc).data&.[](:latest_chapter)
    end
  end

  updated_list = cartoon_data.zip(latest_chapters).map do |data, latest_chapter|
    next if latest_chapter && latest_chapter == data[2].to_f

    doc = firestore.doc(format('%<collection>s/%<name>s', collection: CARTOON_LIST_COLLECTION, name: data[0]))
    doc.set({
      link: data[1],
      latest_chapter: data[2],
      latest_link: data[3]
    }, merge: true)
  end.compact

  unless updated_list.empty?
    puts "updated #{updated_list.size} cartoons"
    puts 'updated list:'
    updated_list.each { |cartoon| puts cartoon }
  else
    puts "no updated cartoons"
  end

  'ok'
end

def find_by(object:, type:, value: nil)
  if value
    object.children.find { |data| data.attributes[type]&.value == value }
  else
    object.children.find { |data| data.name == type }
  end
end

def loop_by(object:, type:, value:)
  object.children.select do |data|
    data.attributes[type]&.value == value
  end
end
