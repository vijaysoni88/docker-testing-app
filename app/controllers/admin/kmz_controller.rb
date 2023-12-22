require 'zip'

class Admin::KmzController < ApplicationController
  def upload
    # Handle KMZ file upload
    kmz_file = params[:kmz_file]
  
    # Ensure a KMZ file is selected
    if kmz_file.present? && kmz_file.respond_to?(:tempfile)
      begin
        kmz_file_model = Kmz.create(kmz_attachment: kmz_file)
        # Process the KMZ file model as needed
  
        @upload_result = { success: true, entries: [{ name: 'KMZ File', data: kmz_file_model.id }] }
      rescue StandardError => e
        @upload_result = { success: false, error: e.message }
      end
    else
      @upload_result = { success: false, error: 'No KMZ file selected' }
    end
    flash[:upload_result] = @upload_result
    redirect_to admin_home_index_path
  end
end
