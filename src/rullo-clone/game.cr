require "./grid.cr"

def centre_text(text : SF::Text, position : SF::Vector2f | Tuple)
  local_bounds = text.local_bounds
  position = {position[0] - local_bounds.width / 2, position[1] - local_bounds.height / 2}
  text.position = position
end

class Game
  def initialize
    # Initialise window
    @window = SF::RenderWindow.new(
      SF::VideoMode.new(500, 550), "Game Sample",
      settings: SF::ContextSettings.new(depth: 24, antialiasing: 8)
    )
    @width = 8
    @height = 8
    @game_board = Board.new(@width, @height, {2, 5})
    @locked = [] of Tuple(Int32, Int32)

    @font = SF::Font.from_file("./resources/FiraCode-Regular.ttf")
    @seconds = 0
  end

  private def clear_window
    rect = SF::RectangleShape.new({500, 550})
    rect.fill_color = SF::Color.new(0x000000ff)
    rect.position = {0, 0}
    @window.draw(rect)
  end

  # Display the board
  private def display_board
    clear_window

    text = SF::Text.new("Time taken: #{@seconds}", @font, 25)
    centre_text(text, {250, 25})

    @window.draw(text)
    # Draw squares on the top
    (0...@width).each do |a|
      top_square = SF::RectangleShape.new({40, 40})
      top_square.position = {100 + (50 * a), 60}
      top_square.fill_color = SF::Color.new(@game_board.row_sums[a] == @game_board.orig_row_sums[a] ? 0xffdd00ff : 0x999999ff)
      top_text = SF::Text.new(@game_board.row_sums[a].to_s, @font, 25)
      centre_text(top_text, {120 + (50 * a), 70})

      bottom_square = SF::RectangleShape.new({40, 40})
      bottom_square.position = {100 + (50 * a), 100}
      bottom_square.fill_color = SF::Color.new(0x555555ff)
      bottom_text = SF::Text.new(@game_board.orig_row_sums[a].to_s, @font, 25)
      centre_text(bottom_text, {120 + (50 * a), 110})

      @window.draw(top_square)
      @window.draw(top_text)
      @window.draw(bottom_square)
      @window.draw(bottom_text)
    end

    # Draw squares on the left
    (0...@height).each do |a|
      top_square = SF::RectangleShape.new({40, 40})
      top_square.position = {10, 150 + (50 * a)}
      top_square.fill_color = SF::Color.new(@game_board.col_sums[a] == @game_board.orig_col_sums[a] ? 0xffdd00ff : 0x999999ff)
      top_text = SF::Text.new(@game_board.col_sums[a].to_s, @font, 25)
      centre_text(top_text, {30, 160 + (50 * a)})

      bottom_square = SF::RectangleShape.new({40, 40})
      bottom_square.position = {50, 150 + (50 * a)}
      bottom_square.fill_color = SF::Color.new(0x555555ff)
      bottom_text = SF::Text.new(@game_board.orig_col_sums[a].to_s, @font, 25)
      centre_text(bottom_text, {70, 160 + (50 * a)})

      @window.draw(top_square)
      @window.draw(top_text)
      @window.draw(bottom_square)
      @window.draw(bottom_text)
    end

    (0...@width).each do |a|
      (0...@height).each do |b|
        shape = SF::CircleShape.new(20)
        shape.position = {100 + (50 * a), 150 + (50 * b)}
        shape.fill_color = SF::Color.new(@game_board.board[a][b].zero? ? 0x999999ff : 0x990000ff)
        shape.outline_thickness = 2_f32
        
        if @locked.includes?({a, b})
          shape.outline_color = SF::Color.new(0xffdd00ff)
        else
          shape.outline_color = SF::Color.new(0x000000ff)
        end

        text = SF::Text.new(@game_board.orig_board[a][b].to_s, @font)
        centre_text(text, {120 + (50 * a), 160 + (50 * b)})

        @window.draw(shape)
        @window.draw(text)
      end
    end

    @window.display
  end

  private def toggle(vec : SF::Vector2i)
    tile_x = (vec[0] - 100) / 50
    tile_y = (vec[1] - 150) / 50

    return if @locked.includes?({tile_x, tile_y})

    @game_board.toggle(tile_x, tile_y)
  end

  private def toggle_lock(vec : SF::Vector2i)
    tile_x = (vec[0] - 100) / 50
    tile_y = (vec[1] - 150) / 50

    if @locked.includes?({tile_x, tile_y})
      @locked.reject! { |a| a == {tile_x, tile_y} }
    else
      @locked.push({tile_x, tile_y})
    end
  end

  private def toggle_row_lock(vec : SF::Vector2i)
    tile_x = (vec[0] - 100) / 50

    return if @game_board.row_sums[tile_x] != @game_board.orig_row_sums[tile_x]

    all_locked? = (0...@width).map { |a| @locked.includes?({tile_x, a}) }.reduce { |a, b| a && b }
    if all_locked?
      @locked.reject! { |a| a[0] == tile_x }
    else
      (0...@width).each do |a|
        @locked.push({tile_x, a}) unless @locked.includes?({tile_x, a})
      end
    end
  end

  private def toggle_col_lock(vec : SF::Vector2i)
    tile_y = (vec[1] - 150) / 50

    return if @game_board.col_sums[tile_y] != @game_board.orig_col_sums[tile_y]

    all_locked? = (0...@height).map { |a| @locked.includes?({a, tile_y}) }.reduce { |a, b| a && b }
    if all_locked?
      @locked.reject! { |a| a[1] == tile_y }
    else
      (0...@height).each do |a|
        @locked.push({a, tile_y}) unless @locked.includes?({a, tile_y})
      end
    end
  end

  private def check_win
    (0...@width).each do |a|
      return if @game_board.row_sums[a] != @game_board.orig_row_sums[a]
    end

    (0...@height).each do |b|
      return if @game_board.col_sums[b] != @game_board.orig_col_sums[b]
    end

    win_text = SF::Text.new("You won!", @font, 50)
    centre_text(win_text, {250, 275})

    score_text = SF::Text.new("You took #{@seconds} seconds.", @font, 20)
    centre_text(score_text, {300, 275})

    play_text = SF::Text.new("Press ENTER to play another game.", @font, 20)
    centre_text(play_text, {330, 275})

    @window.draw(win_text)
    @window.draw(score_text)
    @window.draw(play_text)
    @window.display

    while true
      while event = @window.poll_event
        if event.is_a? SF::Event::Closed
          @window.close
        end
      end

      if SF::Keyboard.key_pressed?(SF::Keyboard::Return)
        @game_board = Board.new(@width, @height, {2, 5})
        @locked = [] of Tuple(Int32, Int32)
        @seconds = 0

        display_board
        return
      end
    end
  end

  def main_loop
    l_click = [false, false]
    r_click = [false, false]
    start_time = SF::Clock.new

    display_board

    # While the window is open
    while @window.open?
      # Check for event
      while event = @window.poll_event
        if event.is_a? SF::Event::Closed
          @window.close
        end
      end

      # Timer stuff
      if start_time.elapsed_time.as_milliseconds > 1000
        start_time.restart
        @seconds += 1
        display_board
      end

      # Clicking checks
      l_click[0] = l_click[1].dup
      l_click[1] = SF::Mouse.button_pressed?(SF::Mouse::Left)

      r_click[0] = r_click[1].dup
      r_click[1] = SF::Mouse.button_pressed?(SF::Mouse::Right)

      if l_click[0] == true && l_click[1] == false
        position = SF::Mouse.get_position(@window)

        if 100 < position[0] < 500 && 150 < position[1] < 550
          toggle(position)
          display_board
        end
      elsif r_click[0] == true && r_click[1] == false
        position = SF::Mouse.get_position(@window)

        if 100 < position[0] < 500 && 150 < position[1] < 550
          toggle_lock(position)
          display_board
        elsif 100 < position[0] < 500 && 60 < position[1] < 140
          toggle_row_lock(position)
          display_board
        elsif 10 < position[0] < 90 && 150 < position[1] < 550
          toggle_col_lock(position)
          display_board
        end
      end

      # Check if the board is won
      check_win
    end
  end
end
