class Admin::FacilitiesController < Admin::BaseController
  before_action :set_facility, only: %i[edit update destroy]

  def index
    @facilities = Facility.all
    @room_levels = RoomLevel.all

    if params[:room_level_id].present?
      @selected_level = RoomLevel.find(params[:room_level_id])
      @facilities = @selected_level.facilities
      @facility = Facility.new
    else
      @facilities = []
      @facility = Facility.new
    end
  end

  def new
    @facility = Facility.new
  end

  def create
  @facility = Facility.new(name: params[:facility][:name])

  if @facility.save
    RoomLevelFacility.create!(
      room_level_id: params[:facility][:room_level_id],
      facility_id: @facility.id
    )

    redirect_to admin_facilities_path(
      room_level_id: params[:facility][:room_level_id]
    ), notice: "Fasilitas ditambahkan"
  else
    redirect_to admin_facilities_path(
      room_level_id: params[:facility][:room_level_id]
    ), alert: @facility.errors.full_messages.join(", ")
  end
end




  def edit
  end

  def update
    if @facility.update(facility_params)
      redirect_to admin_facilities_path, notice: "Fasilitas diupdate"
    else
      render :edit
    end
  end

  def destroy
    @facility.destroy
    redirect_to admin_facilities_path, notice: "Fasilitas dihapus"
  end

  private

  def set_facility
    @facility = Facility.find(params[:id])
  end

  def facility_params
  params.require(:facility).permit(:name, :room_level_id)
end
end
