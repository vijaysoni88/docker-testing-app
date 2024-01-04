class Admin::BarriersController < ApplicationController
  before_action :set_barrier, only: [:show, :edit, :update, :destroy]

  def index
    @barriers = Barrier.all
  end

  def show
  end

  def new
    @barrier = Barrier.new
  end

  def create
    @barrier = Barrier.new(barrier_params)

    respond_to do |format|
      if @barrier.save
        format.js { render 'admin/barriers/create', status: :ok }   # Render create.js.erb for AJAX response with :ok status
      else
        format.js { render 'admin/barriers/error', status: :unprocessable_entity }  # Render error.js.erb for AJAX response with unprocessable_entity status
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
    @barrier.destroy
    redirect_to admin_barriers_path, notice: 'Barrier was successfully destroyed.'
  end

  private

  def set_barrier
    @barrier = Barrier.find(params[:id])
  end

  def barrier_params
    params.require(:barrier).permit(:name, :latitude, :longitude, :size, :enabled)
  end
end
