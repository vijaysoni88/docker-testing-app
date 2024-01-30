class User::HomeController < ApplicationController
  before_action :authenticate_user!

  def index
    @locations = []

    render 'index'
  end

  def geocode
    result = Geocoder.search(params[:address]).first
    coordinates = { latitude: result.latitude, longitude: result.longitude }

    render json: coordinates
  end

  def get_directions
    start_location =  params[:start_location]
    end_location = params[:end_location]

    barrier_coordinates = []
 
    response = HTTParty.get('https://maps.googleapis.com/maps/api/directions/json', {
      query: {
        origin: start_location,
        destination: end_location,
        key: Rails.application.credentials.staging[:google_maps_api_key],
        alternatives: true
      }
    })

    all_routes = response['routes']

    # Tesing code for Google api
    # directions_response = File.read('/home/bacancy/rails_work/AB-CRANE-HIRE/test/directions_response.json')

    # directions_data = JSON.parse(directions_response)
    # all_routes = directions_data['routes']

    render json: { status: 'OK', routes: all_routes, barriers: barrier_coordinates }
  end

  def job_sheet
    @directions = params[:start_location]
    render 'shared/job_sheet'
  end
end
