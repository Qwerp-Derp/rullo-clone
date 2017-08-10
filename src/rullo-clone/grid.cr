require "./tile.cr"

class Array
  def sum
    self.reduce { |a, b| a + b }
  end
end

class Board
  getter :orig_board, :board, :orig_row_sums, :orig_col_sums, :row_sums, :col_sums

  @width : Int32
  @height : Int32
  @range : Tuple(Int32, Int32)

  @orig_board : Array(Array(Int32))
  @board : Array(Array(Int32))
  
  @orig_row_sums = [] of Int32
  @orig_col_sums = [] of Int32  
  @row_sums = [] of Int32
  @col_sums = [] of Int32

  private def place_item
    empty_items = [] of Array(Int32)
    
    (0...@width).each { |x|
      (0...@height).each { |y|
        empty_items.push([x, y]) if @orig_board[x][y].zero? }}

    rand_item = empty_items[rand(empty_items.size)]
    rand_number = @range[0] + rand(@range[1] - @range[0])

    @orig_board[rand_item[0]][rand_item[1]] = rand_number
  end

  private def set_sums
    @row_sums = @board.map { |row| row.sum }
    @col_sums = (0...@height).map { |col| @board.map { |row| row[col] }.sum }
  end

  private def init_board
    items = (@width * @height / 2) + rand(@width * @height / 4)
    items.times { place_item }

    @orig_row_sums = @orig_board.map { |row| row.sum }
    @orig_col_sums = (0...@height).map { |col| @orig_board.map { |row| row[col] }.sum }

    (@width * @height - items).times { place_item }
  end

  private def empty_board : Array(Array(Int32))
    return (0...@width).map { |_| (0...@height).map { |_| 0 }}
  end

  def initialize(@width, @height, @range)
    @orig_board = empty_board
    init_board

    @board = (0...@width).map { |x| (0...@height).map { |y| @orig_board[x][y].dup}}
    set_sums
  end

  def toggle(x : Int32, y : Int32)
    @board[x][y] = @board[x][y].zero? ? @orig_board[x][y] : 0
    set_sums
  end
end
