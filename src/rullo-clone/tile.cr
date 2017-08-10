class Tile(T)
  property :x, :y, :value
  @value : T?
  @x : Int32
  @y : Int32

  def initialize(@x, @y, @value)
  end

  def initialize(@x, @y)
    @value = nil
  end
end