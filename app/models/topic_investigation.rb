class TopicInvestigation < ApplicationRecord
  STATUS_ENUM = {pending: 0, active: 1, ended: 2}.freeze

  belongs_to :topic
  has_many :topic_investigation_votes

  enum status: STATUS_ENUM

  validates_presence_of :topic_name

  before_validation :set_calculated_attributes

  scope :name_ordered, -> { order(arel_table["topic_name"].lower) }

  attr_accessor :timezone

  def start_at_in_zone=(val)
    self.start_at = TranzitoUtils::TimeParser.parse(val, timezone)
  end

  def end_at_in_zone=(val)
    self.end_at = TranzitoUtils::TimeParser.parse(val, timezone)
  end

  def start_at_in_zone
    start_at
  end

  def end_at_in_zone
    end_at
  end

  def set_calculated_attributes
    if topic_name_changed?
      self.topic = Topic.find_or_create_for_name(topic_name)
    end
    self.topic_name = topic&.name if topic.present?
    # Reverse the times if they should be reversed
    if start_at.present? && end_at.present? && end_at < start_at
      new_start = end_at
      self.end_at = start_at
      self.start_at = new_start
    end
    self.status = calculated_status
  end

  def calculated_status
    if end_at.blank? || start_at.blank? || start_at > Time.current
      "pending"
    elsif end_at > Time.current
      "active"
    else
      "ended"
    end
  end
end
