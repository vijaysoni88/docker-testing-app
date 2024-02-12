class Kmz < ApplicationRecord
  has_one_attached :kmz_attachment

  def self.save_uploaded_kmz(file)
    kmz_file = Kmz.new

    kmz_file.kmz_attachment.attach(io: file, filename: 'uploaded_kmz_file.kmz', content_type: 'application/vnd.google-earth.kmz')
    kmz_file.save
    kmz_file
  end
end
