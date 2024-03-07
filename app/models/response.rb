class Response < ApplicationRecord
  has_one_attached :json_file
  validates :response_type, presence: true
end
