# frozen_string_literal: true

require 'httparty'
require 'nokogiri'

class HtmlObject
  def initialize(source:, structure:)
    @body_object = body(source)
    @structure = structure
    @loop_structure = structure.find { |data| data['loop'] }['loop']
  end

  def cartoon_data
    html_objects =
      @structure
        .unshift(@body_object)
        .reduce do |object, node|
          if node['loop']
            loop_by(object: object, type: node.first[0], value: node.first[1])
          else
            find_by(object: object, type: node.first[0], value: node.first[1])
          end
        end

    html_objects.map do |html_object|
      name, link = nil
      latest_link =
        ([html_object] + @loop_structure).reduce do |object, node|
          if node['name_and_link']
            name_object =
              find_by(object: object, type: node['name_and_link'][0])
            name, link = name_and_link(name_object)
          end

          find_by(object: object, type: node.first[0], value: node.first[1])
        end.attributes[
          'href'
        ].value

      chapter, lang = chapter_and_lang(latest_link.split('/').last)

      [name, link, chapter, latest_link, lang]
    end
  end

  private

  def find_by(object:, type:, value: nil)
    object.children.find do |data|
      if value
        data.attributes[type]&.value == value
      else
        data.name == type
      end
    end
  end

  def loop_by(object:, type:, value:)
    object.children.select { |data| data.attributes[type]&.value == value }
  end

  def body(source)
    response_body = HTTParty.get(source).body
    response_body&.empty? && raise('Something wrong with http read')

    Nokogiri.HTML(response_body)
  end

  def name_and_link(object)
    [object.children[0].text.strip, object.attributes['href'].value]
  end

  def chapter_and_lang(text)
    Float text
  rescue _
    text.split('-')
  end
end
