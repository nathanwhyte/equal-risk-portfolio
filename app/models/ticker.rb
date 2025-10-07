class Ticker
  include ActiveModel::API

  attr_accessor :symbol, :name
  validates :symbol, :name, presence: true
end
