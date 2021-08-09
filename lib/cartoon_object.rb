# frozen_string_literal: true

require 'algolia'

APP_ID = 'JPIR0FJMPT'
API_KEY = '4870c5329f430b89b6af375d42bf5cee'
INDEX_NAME = 'niceoppai-cartoons'

class CartoonObject
  def initialize
    client = Algolia::Search::Client.create(APP_ID, API_KEY)
    @index = client.init_index(INDEX_NAME)
  end

  def search(account_id: nil, cartoon_name: nil, page: 0)
    query = account_id || cartoon_name
    objects = @index.search(query, { page: page })

    objects[:hits].map do |object|
      object.values_at(:objectID, :latest_chapter, :thumbnail_link)
    end
  end
end
