class Admin::RoomLevelsController < Admin::BaseController
  before_action :set_room_level, only: [:edit, :update, :destroy]

  def index
    @room_levels = RoomLevel.all
    @room_levels = RoomLevel.includes(:facilities)
    @room_level = RoomLevel.new

  end

  def new
    @room_level = RoomLevel.new
    @room_level.room_level_facilities.build
  end

  def create
    @room_level = RoomLevel.new(room_level_params)
    if @room_level.save
      redirect_to admin_room_levels_path, notice: "Tingkatan kamar berhasil ditambahkan"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @room_level = RoomLevel.find(params[:id])
  @room_level.room_level_facilities.build
end


  def update
    if @room_level.update(room_level_params)
      redirect_to admin_room_levels_path, notice: "Tingkatan kamar berhasil diupdate"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @room_level.destroy
    redirect_to admin_room_levels_path, notice: "Tingkatan kamar dihapus"
  end

  private

  def set_room_level
    @room_level = RoomLevel.find(params[:id])
  end

  # app/controllers/admin/room_levels_controller.rb
def room_level_params
  params.require(:room_level).permit(
    :name,
    :price,
    facility_ids: []
  )
end

end
