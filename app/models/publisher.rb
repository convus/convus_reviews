class Publisher < ApplicationRecord
  DEFAULT_REMOVE_QUERY_MATCHES = ["[^.].*substack.com"]
  BASE_WORD_COUNT = 100

  has_many :citations

  validates_uniqueness_of :domain, allow_nil: false
  validates_presence_of :name

  before_validation :set_default_remove_query, on: :create
  before_validation :set_calculated_attributes
  after_commit :remove_citation_queries_if_changed

  scope :remove_query, -> { where(remove_query: true) }
  scope :keep_query, -> { where(remove_query: false) }

  def self.remove_query?(str = nil)
    return false if str.blank?
    remove_query.where(domain: str.downcase).limit(1).present?
  end

  def self.find_or_create_for_domain(domain, name: nil, remove_query: false)
    where(domain: domain).first ||
      create(domain: domain, name: name, remove_query: remove_query)
  end

  def domain_to_name
    domain&.gsub(/\.[^.]*\z/, "")
  end

  def name_assigned?
    name != domain_to_name
  end

  def keep_query?
    !remove_query?
  end

  def set_default_remove_query
    self.remove_query = true if default_remove_query?
  end

  def set_calculated_attributes
    @remove_query_enabled = remove_query_changed? && remove_query
    self.domain = domain&.downcase
    self.name ||= domain_to_name
    self.base_word_count ||= BASE_WORD_COUNT
  end

  def default_remove_query?
    DEFAULT_REMOVE_QUERY_MATCHES.any? { |q| domain.match?(/#{q}/) }
  end

  def remove_citation_queries_if_changed
    return unless @remove_query_enabled
    citations.each { |c| c.remove_query! }
  end
end
