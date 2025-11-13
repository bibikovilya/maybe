class PriorAccount < ApplicationRecord
  include Syncable

  has_one :account, dependent: :nullify
  delegate :family, to: :account

  validates :name, presence: true, uniqueness: true
  validates :currency, presence: true
end
