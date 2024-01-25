class Barrier < ApplicationRecord
  validates :name, presence: true
  validates :latitude, presence: true
  validates :longitude, presence: true
  before_validation :set_default_enabled_value

  private

  def set_default_enabled_value
    self.enabled ||= false
  end
end
