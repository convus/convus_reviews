class Event < ApplicationRecord
  KIND_ENUM = {
    review_created: 0,
    user_enabled_public_view: 1,
    user_added_about: 2
  }.freeze

  self.implicit_order_column = :id

  belongs_to :user
  belongs_to :target, polymorphic: true

  enum kind: KIND_ENUM

  before_validation :set_calculated_attributes

  def set_calculated_attributes
    self.created_date = if defined?(target.created_date)
      target.created_date
    else
      created_at.to_date
    end
  end
end
