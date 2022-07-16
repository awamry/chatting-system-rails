class Message < ApplicationRecord
  include Elasticsearch::Model
  include Elasticsearch::Model::Callbacks

  belongs_to :chat

  validates_presence_of :number, :body, :chat_id

  settings index: {
    number_of_shards: 1,
    max_ngram_diff: 7,
    analysis: {
      analyzer: {
        message_body: {
          tokenizer: "message_body_tokenizer",
          filter: ["lowercase"]
        },
        message_body_search: {
          "tokenizer": "keyword",
          filter: ["lowercase"]
        }
      },
      tokenizer: {
        message_body_tokenizer: {
          type: "ngram",
          min_gram: 3,
          max_gram: 10,
          token_chars: %w[letter digit whitespace]
        }
      }
    }
  } do
    mapping dynamic: false do
      indexes :body, analyzer: 'message_body', search_analyzer: 'message_body_search'
      indexes :chat_id, type: :integer
    end
  end

  def self.search_message_body(chat_id, query, from, size)
    search({ from: from, size: size, query: { bool: { must: [{ match: { body: query } }, { match: { chat_id: chat_id } }] } } })
  end
end
