class ElasticSearchMessageSerializer < ActiveModel::Serializer
  type 'messages'
  [:number, :body].map{|a| attribute(a) {object[:_source][a]}}
end