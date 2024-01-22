class Admin::BarriersController < ApplicationController
  before_action :set_barrier, only: [:show, :edit, :update]

  def index
    @barriers = Barrier.all
  end

  def show
  end

  def new
    @barrier = Barrier.new
  end

  def create
    @barrier = Barrier.find_or_initialize_by(barrier_params)
  
    respond_to do |format|
      if @barrier.persisted?
        format.html { redirect_to admin_home_index_path(create_barrier: true), notice: 'Barrier already exists.' }
        format.js { render js: "window.location = '#{admin_home_index_path(create_barrier: true)}';" }
      elsif @barrier.save
        format.html { redirect_to admin_home_index_path(create_barrier: true), notice: 'Barrier created successfully.' }
        format.js { render js: "window.location = '#{admin_home_index_path(create_barrier: true)}';" }
      else
        format.js { render 'admin/barriers/error', status: :unprocessable_entity }
      end
    end
  end

  def edit
  end

  def update
    if @barrier.update(barrier_params)
      redirect_to admin_barrier_path(@barrier), notice: 'Barrier was successfully updated.'
    else
      render :edit
    end
  end

  def destroy
    selected_ids = params[:selected_ids]

    Barrier.destroy_by(id: selected_ids) if selected_ids.present?
    redirect_to admin_home_index_path(create_barrier: true), notice: 'Selected barriers deleted successfully.'
  end

  private

  def set_barrier
    @barrier = Barrier.find(params[:id])
  end

  def barrier_params
    params.require(:barrier).permit(:name, :latitude, :longitude, :size, :enabled)
  end
end
