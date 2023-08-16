require 'pry-byebug'

class Board
  MARKERS = %w(X O)
  WINNING_CONDITION = 3
  WINNING_LINES = [[1, 2, 3], [4, 5, 6], [7, 8, 9]] + # rows
                  [[1, 4, 7], [2, 5, 8], [3, 6, 9]] + # cols
                  [[1, 5, 9], [3, 5, 7]]              # diagonals

  def initialize
    @squares = {}
    reset
  end

  def []=(num, marker)
    @squares[num].marker = marker
  end

  def unmarked_keys
    @squares.keys.select { |key| @squares[key].unmarked? }
  end

  def full?
    unmarked_keys.empty?
  end

  def someone_won?
    winning?(MARKERS.first) || winning?(MARKERS.last)
  end

  def winning?(marker)
    WINNING_LINES.each do |line|
      squares = @squares.values_at(*line)
      if identical_markers?(squares, marker, WINNING_CONDITION)
        return true
      end
    end
    false
  end

  def imminent_win_square(marker)
    WINNING_LINES.each do |line|
      squares = @squares.values_at(*line)

      if squares.map(&:marker).count(marker) == WINNING_CONDITION - 1
        winning_square_num = line.select do |num|
          @squares[num].marker != marker
        end.first

        return winning_square_num if !@squares[winning_square_num].marked?
      end
    end

    nil
  end

  def reset
    (1..9).each { |key| @squares[key] = Square.new }
  end

  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/MethodLength
  def draw
    puts "     |     |"
    puts "  #{@squares[1]}  |  #{@squares[2]}  |  #{@squares[3]}"
    puts "     |     |"
    puts "-----+-----+-----"
    puts "     |     |"
    puts "  #{@squares[4]}  |  #{@squares[5]}  |  #{@squares[6]}"
    puts "     |     |"
    puts "-----+-----+-----"
    puts "     |     |"
    puts "  #{@squares[7]}  |  #{@squares[8]}  |  #{@squares[9]}"
    puts "     |     |"
  end
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Metrics/MethodLength

  private

  def identical_markers?(squares, identical_marker, identical_count)
    markers = squares.select do |square|
      square.marker == identical_marker
    end

    markers.size == identical_count
  end
end

class Square
  INITIAL_MARKER = " "

  attr_accessor :marker

  def initialize(marker=INITIAL_MARKER)
    @marker = marker
  end

  def to_s
    @marker
  end

  def unmarked?
    marker == INITIAL_MARKER
  end

  def marked?
    marker != INITIAL_MARKER
  end
end

class Player
  attr_reader :marker
  attr_reader :score
  attr_reader :name

  def initialize(marker, name)
    @marker = marker
    @name = name
    reset
  end

  def update_score
    @score += 1
  end

  def reset
    @score = 0
  end
end

class TTTGame
  WIN_CONDITION = 3
  COMPUTER_NAMES = ["WALL-E", "HAL9000", "C-3PO", "Deep Thought", "Skynet", "Glados"]

  attr_reader :board, :human, :computer

  def initialize
    @board = Board.new

    @human = Player.new(human_marker, human_name)
    @computer = Player.new(computer_marker, computer_name)

    @current_marker = @human.marker
  end

  def human_name
    puts "What's your name?"
    name = nil

    loop do
      name = gets.chomp
      break unless name.empty?
      puts "Sorry, your name can't be blank!"
    end

    name
  end

  def computer_name
    COMPUTER_NAMES.sample
  end

  def human_marker
    puts "Choose a marker #{joinor(Board::MARKERS)}"
    marker = nil

    loop do
      marker = gets.chomp.upcase
      break if Board::MARKERS.include?(marker)
      puts "Sorry, must be #{joinor(Board::MARKERS)}"
    end

    marker
  end

  def computer_marker
    Board::MARKERS.filter do |marker|
      marker != @human.marker
    end.first
  end

  def play
    clear
    display_welcome_message
    main_game
    display_goodbye_message
  end

  private

  def display_winner(winner)
    if human == winner
      puts "#{human.name} won the game!"
    elsif computer == winner
      puts "#{computer.name} won the game!"
    end
  end

  def winner
    if human.score == WIN_CONDITION
      human
    elsif computer.score == WIN_CONDITION
      computer
    end
  end

  # rubocop:disable Metrics/MethodLength
  def main_game
    loop do
      loop do
        display_board
        player_move

        clear
        display_board
        display_result

        break if winner
        wait_user
        reset_board
      end

      display_winner(winner)
      break unless play_again?

      display_play_again_message
      reset_scores
      reset_board
    end
  end
  # rubocop:enable Metrics/MethodLength

  def player_move
    loop do
      current_player_moves
      break if board.someone_won? || board.full?

      if human_turn?
        clear
        display_board
      end
    end
  end

  def display_welcome_message
    puts "Welcome to Tic Tac Toe!"
    puts ""
  end

  def display_goodbye_message
    puts "Thanks for playing Tic Tac Toe! Goodbye!"
  end

  def human_turn?
    @current_marker == @human.marker
  end

  def display_board
    puts "#{human.name} is #{human.marker}. #{computer.name} is #{computer.marker}."
    puts ""
    board.draw
    puts ""
  end

  def joinor(arr, delim = ', ', last = 'or')
    case arr.size
    when 0 then return ''
    when 1 then return arr.first.to_s
    when 2 then delim = ' '
    end

    arr[0..-2].each_with_object("") { |ele, str| str << ele.to_s + delim } +
      last + ' ' + arr[-1].to_s
  end

  def human_moves
    puts "Choose a square (#{joinor(board.unmarked_keys, ', ', 'or')}): "

    square = nil

    loop do
      square = gets.chomp.to_i
      break if board.unmarked_keys.include?(square)
      puts "Sorry, that's not a valid choice."
    end

    board[square] = human.marker
  end

  # rubocop:disable Metrics/AbcSize
  def computer_moves
    computer_winning_square = board.imminent_win_square(computer.marker)
    human_winning_square = board.imminent_win_square(human.marker)

    if !computer_winning_square.nil?
      board[computer_winning_square] = computer.marker
    elsif !human_winning_square.nil?
      board[human_winning_square] = computer.marker
    else
      board[board.unmarked_keys.sample] = computer.marker
    end
  end
  # rubocop:enable Metrics/AbcSize

  def current_player_moves
    if human_turn?
      human_moves
      @current_marker = @computer.marker
    else
      computer_moves
      @current_marker = @human.marker
    end
  end

  def display_score
    puts "#{human.name} score: #{human.score}"
    puts "#{computer.name} score: #{computer.score}"
  end

  def display_result
    if board.winning?(human.marker)
      puts "#{human.name} won the match!"
      human.update_score
    elsif board.winning?(computer.marker)
      puts "#{computer.name} won the match!"
      computer.update_score
    else
      puts "It's a tie!"
    end

    display_score
  end

  def play_again?
    answer = nil
    loop do
      puts "Would you like to play again? (y/n)"
      answer = gets.chomp.downcase
      break if %w(y n).include? answer
      puts "Sorry, must be y or n"
    end

    answer == 'y'
  end

  def clear
    system "clear"
  end

  def reset_board
    board.reset
    @current_marker = @human.marker
    clear
  end

  def reset_scores
    human.reset
    computer.reset
  end

  def display_play_again_message
    puts "Let's play again!"
    puts ""
  end

  def wait_user
    user_input = ''
    until user_input =~ /./
      puts "Enter anything to continue..."
      user_input = gets.chomp
    end
  end
end

game = TTTGame.new
game.play
