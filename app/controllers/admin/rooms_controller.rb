class Admin::RoomsController < Admin::BaseController
  def index
  @rooms = Room.includes(:room_level)
  @room = Room.new
  @room_levels = RoomLevel.all
end


  def new
    @room = Room.new
    @room_levels = RoomLevel.all
  end

  def create
    @room = Room.new(room_params)
    if @room.save
      redirect_to admin_rooms_path, notice: "Kamar berhasil ditambahkan"
    else
      @room_levels = RoomLevel.all
      render :new
    end
  end

  def edit
    @room = Room.find(params[:id])
    @room_levels = RoomLevel.all
  end

  def update
    @room = Room.find(params[:id])
    if @room.update(room_params)
      redirect_to admin_rooms_path, notice: "Kamar berhasil diupdate"
    else
      @room_levels = RoomLevel.all
      render :edit
    end
  end

  def destroy
    @room = Room.find(params[:id])
    @room.destroy
    redirect_to admin_rooms_path, notice: "Kamar berhasil dihapus"
  end

  private

  def room_params
    params.require(:room).permit(:room_number, :room_level_id)
  end
end
