=begin
Tic Tac Toe game with variable grid size and multiple human/AI plyrs.

For example:
  3 x 3 board with (row, col) 2d coordinates and 1d coordinates.
  (0,0)|(0,1)|(0,2)
    0  |  1  |  2
  _____|_____|_____
  (1,0)|(1,1)|(1,2)
    3  |  4  |  5
  _____|_____|_____
  (2,0)|(2,1)|(2,2)
    6  |  7  |  8
       |     |
=end

require 'yaml'

MESSAGES = YAML.load_file('tic_tac_toe.yml')
SCREEN_LENGTH = 80
WIN_CONDITION = 5
MIN_GRID_WIDTH = 2
MIN_PLAYERS = 2
PIECES_CHOICE = %w(X O ~ ! @ # $ % ^ & * - + = : ?)
SQ_WIDTH = 5
PAD_CHAR = ' '
GRID_VERT_CHAR = '|'
GRID_HORZ_CHAR = '_'

def clean_screen
  system 'clear'
end

# Returns a user input restricted to an integer between low and high limits
# (inclusive).
def req_num_and_scrub_inc_limits(msg, low, high)
  prompt(msg)
  num = 0

  loop do
    input = gets.chomp
    num = input.to_i

    break if input == num.to_s && num.to_i >= low && num.to_i <= high
    prompt(MESSAGES['invalid_choice'])
  end

  num
end

def req_grid_size
  msg = "#{MESSAGES['enter_grid_size']} "\
        "(#{MIN_GRID_WIDTH} <= "\
        "#{MESSAGES['grid_size']} <= "\
        "#{PIECES_CHOICE.length})"

  req_num_and_scrub_inc_limits(msg, MIN_GRID_WIDTH, PIECES_CHOICE.length)
end

# Returns the number of human or AI players from the user.
def req_plyr_count(min_plyrs, max_plyrs, human = true)
  human_or_ai = human ? MESSAGES['human'] : MESSAGES['ai']

  msg = "#{MESSAGES['enter_num_plyrs']} "\
        "#{human_or_ai} "\
        "#{MESSAGES['plyrs']} "\
        "(#{min_plyrs} <= #{MESSAGES['plyrs']} <= #{max_plyrs})"

  req_num_and_scrub_inc_limits(msg, min_plyrs, max_plyrs)
end

# Returns the number of AI players from the user.
# Note that the sum of human and AI players must be >= 2 and <= grid size.
# We don't ask for the number of AI players if there can be no more AI players.
# We don't ask for the number of AI players if there's only one possible
# option.
# For example:
#   In a 3 x 3 grid, the max number of players is 3.
#   Therefore, there must be 0 AI if there are 3 humans.
# For example:
#   In a 2 x 2 grid, the max number of players is 2
#   Therefore, there must be 1 AI if there is 1 human.
#   Therefore, there must be 2 AI if there are 0 humans.
def req_ai_count(grid_size, human_count)
  min_ai_count = human_count <= MIN_PLAYERS ? MIN_PLAYERS - human_count : 0
  max_ai_count = grid_size - human_count

  if max_ai_count <= 0 then 0
  elsif min_ai_count == max_ai_count then min_ai_count
  else req_plyr_count(min_ai_count, max_ai_count, false)
  end
end

def init_plyr(num, pc, human = 'true')
  {
    num: num,
    score: 0,
    pc: pc,
    human?: human
  }
end

def init_brd(grid_size)
  {
    grid: [' '] * (grid_size**2),
    grid_size: grid_size
  }
end

# Returns a hash that keeps keeps track of each pieces' count in each
# row, column and diagonal.
# For example:
#   rows: Contains an array of rows.
#   Each row contains a hash where keys are pieces, and values are
#   the count of pieces in the respective row.
# Note that diag1 is the top-left to bottom-right diagonal.
# Note that diag2 is the top-right to bottom-left diagonal.
def init_brd_state(grid_size)
  {
    rows: Array.new(grid_size) { Hash.new(0) },
    cols: Array.new(grid_size) { Hash.new(0) },
    diag1: Hash.new(0),
    diag2: Hash.new(0)
  }
end

# rubocop: disable Metrics/AbcSize
def update_brd_state!(brd, brd_state, coord_1d, curr_plyr)
  col, row = to_2d(brd, coord_1d)

  brd_state[:rows][row][curr_plyr[:pc].to_sym] += 1
  brd_state[:cols][col][curr_plyr[:pc].to_sym] += 1

  # Updates piece counts in diagonals only if the given square is in a
  # diagonal.
  # Note that the square in the center of the grid counts for both diagonals.
  if row == col
    brd_state[:diag1][curr_plyr[:pc].to_sym] += 1
  end

  if row == brd[:grid_size] - 1 - col
    brd_state[:diag2][curr_plyr[:pc].to_sym] += 1
  end
end
# rubocop: enable Metrics/AbcSize

def clear_brd!(brd)
  brd[:grid].map! { ' ' }
end

=begin
Returns the padding to the right of a piece denoted by Zs below.
       |     |
  ZZ   |     |
  _____|_____|_____
       |     |
       |     |
  _____|_____|_____
       |     |
       |     |
       |     |
=end
def calc_front_pad(center_str)
  front_pad_length = (SQ_WIDTH - center_str.length) / 2
  PAD_CHAR * front_pad_length
end

=begin
Returns the padding to the left of a piece denoted by Zs below.
       |     |
     ZZ|     |
  _____|_____|_____
       |     |
       |     |
  _____|_____|_____
       |     |
       |     |
       |     |
=end
def calc_back_pad(front_pad, center_str)
  back_pad_length = SQ_WIDTH - front_pad.length - center_str.length
  PAD_CHAR * back_pad_length
end

=begin
Prints the part of a square denoted below by Zs.
  ZZZZZZ     |
       |     |
  _____|_____|_____
       |     |
       |     |
  _____|_____|_____
       |     |
       |     |
       |     |
=end
def draw_blank_sq_vert_div(brd)
  puts (PAD_CHAR * SQ_WIDTH + GRID_VERT_CHAR) * (brd[:grid_size] - 1)
end

=begin
Prints the part of a square denoted below by Zs.
       |     |
  ZZZZZZ     |
  _____|_____|_____
       |     |
       |     |
  _____|_____|_____
       |     |
       |     |
       |     |
=end
# rubocop: disable Metrics/AbcSize
def draw_pc_sq_vert_div(brd, row)
  front_pad = calc_front_pad(PIECES_CHOICE[0])
  back_pad = calc_back_pad(front_pad, PIECES_CHOICE[0])

  (brd[:grid_size] - 1).times do |idx|
    print "#{front_pad}"\
          "#{brd[:grid][row * brd[:grid_size] + idx]}"\
          "#{back_pad}|"
  end

  puts "#{front_pad}"\
       "#{brd[:grid][row * brd[:grid_size] + (brd[:grid_size] - 1)]}"\
       "#{back_pad}#{row}"
end
# rubocop: enable Metrics/AbcSize

=begin
Prints the part of a square denoted below by Zs.
       |     |
       |     |
  ZZZZZZ_____|_____
       |     |
       |     |
  _____|_____|_____
       |     |
       |     |
       |     |
=end
def draw_blank_sq_horz_vert_div(brd)
  sq = GRID_HORZ_CHAR * SQ_WIDTH + GRID_VERT_CHAR
  last_sq = GRID_HORZ_CHAR * SQ_WIDTH
  puts "#{sq * (brd[:grid_size] - 1)}#{last_sq}"
end

# Prints the column numbers.
def draw_col_coords(brd)
  (brd[:grid_size]).times do |idx|
    front_pad = calc_front_pad(idx.to_s)
    back_pad = calc_back_pad(front_pad, idx.to_s)
    print "#{front_pad}#{idx}#{back_pad} "
  end

  puts
end

def draw_top_row(brd)
  draw_blank_sq_vert_div(brd)
  draw_pc_sq_vert_div(brd, 0)
  draw_blank_sq_horz_vert_div(brd)
end

def draw_middle_rows(brd)
  (1...(brd[:grid_size] - 1)).each do |row|
    draw_blank_sq_vert_div(brd)
    draw_pc_sq_vert_div(brd, row)
    draw_blank_sq_horz_vert_div(brd)
  end
end

def draw_bottom_row(brd)
  draw_blank_sq_vert_div(brd)
  draw_pc_sq_vert_div(brd, brd[:grid_size] - 1)
  draw_blank_sq_vert_div(brd)
  puts
end

def print_divider
  puts "-" * SCREEN_LENGTH
end

# Unwinds the players stack to logical ordering when printing.
# For example:
#   human 0, human 1, ..., AI 0, AI 1, ...
def reorder_plyrs_to_print(plyrs, shft_til_fst_plyr, game_windup, match_windup)
  shft = -(shft_til_fst_plyr + game_windup + match_windup)
  plyrs.rotate(shft)
end

def print_scores(plyrs, curr_plyr)
  plyrs.each do |plyr|
    human_or_ai = plyr[:human?] ? MESSAGES['human'] : MESSAGES['ai']

    msg = "(#{plyr[:pc]}) "\
          "#{MESSAGES['plyr']} "\
          "#{human_or_ai} "\
          "#{plyr[:num]}"
    msg = "#{msg.ljust(20)}"\
          "| #{MESSAGES['score']} "\
           "#{plyr[:score]} "
    msg += '<=' if plyr == curr_plyr
    puts msg
  end
  print_divider
end

# Board is defined as follows:
# Top row
#  - Blank row with vertical dividers.
#  - Piece row with vertical dividers.
#  - Blank row with vertical and horizontal dividers.
# Middle row(s)
#  - Blank row with vertical dividers.
#  - Piece row with vertical dividers.
#  - Blank row with vertical and horizontal dividers.
# Bottom row
# - Blank row with vertical dividers.
# - Piece row with vertical dividers.
# - Blank row with vertical dividers.
def draw_brd(brd)
  clean_screen
  draw_col_coords(brd)
  draw_top_row(brd)
  draw_middle_rows(brd)
  draw_bottom_row(brd)
end

def prompt(msg)
  puts "=> #{msg}"
end

# Returns an object selected by the user from an array.
def req_from_list(msg, list)
  prompt(msg)

  loop do
    item = gets.chomp.downcase
    return item if list.include?(item)
    prompt(MESSAGES['invalid_choice'])
  end
end

# Returns a string of the avaliable options for the first player: human, AI
# or random.
def first_plyr_choices(human_count, ai_count)
  msg_choices = []
  msg_choices << MESSAGES['human'] if !human_count.zero?
  msg_choices << MESSAGES['ai'] if !ai_count.zero?
  msg_choices << MESSAGES['random']
end

# Returns a string of the user selected player type.
def req_first_plyr_type(human_count, ai_count)
  msg = "#{MESSAGES['who_first']} "

  msg_choices = first_plyr_choices(human_count, ai_count)

  choices = msg_choices[0..-1] << MESSAGES['random_abbreviated']
  req_from_list(msg + joinor(msg_choices), choices.map!(&:downcase))
end

# Returns an integer of the user selected player number for the given player
# type.
def req_first_plyr_num(plyr_type, max_plyr_num, choices)
  if max_plyr_num == 0
    0
  else
    msg = "#{MESSAGES['enter_the']} "\
          "#{plyr_type} "\
          "#{MESSAGES['plyr_num_first']} "\
          "#{choices}"

    req_num_and_scrub_inc_limits(msg, 0, max_plyr_num)
  end
end

# Returns an integer of the maximum player number for the given player
# type, and player count.
def calc_max_plyr_num(plyr_type, human_count, ai_count)
  case plyr_type
  when 'human' then human_count - 1
  when 'ai' then ai_count - 1
  end
end

# Returns an offset for the players array, which stores all human and AI
# players, to reach the first player of the given type.
def offset_from_first_plyr(plyr_type, human_count)
  case plyr_type
  when 'human' then 0
  when 'ai' then human_count
  end
end

# Returns a formatted string of possible player numbers to choose from for a
# given type.
def choices_for_first_plyr(plyr_type, human_count, ai_count)
  case plyr_type
  when 'human' then joinor((0...human_count).to_a).to_s
  when 'ai' then joinor((0...ai_count).to_a).to_s
  end
end

# Returns an integer to shift in the players array in order to reach the first
# player of a given type. The user may choose the first player or choose a
# random player to go first.
def calc_shft_til_first_plyr(plyrs, human_count, ai_count)
  plyr_type = req_first_plyr_type(human_count, ai_count)
  max_plyr_num = calc_max_plyr_num(plyr_type, human_count, ai_count)
  choices = choices_for_first_plyr(plyr_type, human_count, ai_count)

  offset = offset_from_first_plyr(plyr_type, human_count)

  case plyr_type
  when 'r' then (0...plyrs.length).to_a.sample
  else offset + req_first_plyr_num(plyr_type, max_plyr_num, choices)
  end
end

# Gets the users' piece choices for humans or randomly assigns AI pieces.
# Returns player objects with assigned pieces.
def populate_plyrs!(plyr_count, avail_pcs, human)
  plyrs = []

  plyr_count.times do |plyr_num|
    pc = if human
           req_human_pc!(plyr_num, avail_pcs)
         else
           decide_ai_pc!(avail_pcs)
         end

    plyrs << init_plyr(plyr_num, pc, human)
  end

  plyrs
end

def req_human_pc!(human_num, avail_pcs)
  human_pc = ''

  loop do
    prompt("#{MESSAGES['human']} "\
           "#{human_num} "\
           "#{MESSAGES['piece_choice']} "\
           "#{joinor(avail_pcs)}")
    human_pc = gets.chomp.upcase
    break if avail_pcs.include?(human_pc)
    prompt(MESSAGES['invalid_choice'])
  end

  avail_pcs.delete(human_pc)
end

def decide_ai_pc!(avail_pcs)
  avail_pcs.delete(avail_pcs.sample)
end

# Returns a formatted string from array items seperated by a deliminator
# and ending with a grammar conjugation.
# The formatted string has no deliminator if the array has only 2 items.
# For example:
#   joinor([1, 2, 3, 4])
#     => 1, 2, 3 or 4
#   joinor([1, 2])
#     => 1 or 2
def joinor(arr, delim = ', ', last = 'or')
  case arr.size
  when 0 then return ''
  when 1 then return arr.first.to_s
  when 2 then delim = ' '
  end

  arr[0..-2].each_with_object("") { |ele, str| str << ele.to_s + delim } +
    last + ' ' + arr[-1].to_s
end

# Returns a user input restricted to an integer that exists in a given array.
def req_num_from_list(msg, list)
  prompt(msg)
  num = 0

  loop do
    input = gets.chomp
    num = input.to_i

    break if num.to_s == input && list.include?(num)

    prompt(MESSAGES['invalid_choice'])
  end

  num
end

# Returns a row or column number from the user.
# The rows and columns where an empty square exists are printed, and the user
# must choose from these.
def get_human_move_coord(brd, plyr, col)
  msg = if col
          "#{MESSAGES['human']} "\
          "#{plyr[:num]} "\
          "#{MESSAGES['human_col']} "
        else
          "#{MESSAGES['human']} "\
          "#{plyr[:num]} "\
          "#{MESSAGES['human_row']} "
        end

  list = open_rows_or_cols(brd, col)
  msg += joinor(list)

  req_num_from_list(msg, list)
end

# Returns a list of rows or columns where empty squares exist.
def open_rows_or_cols(brd, cols)
  open_sq_coords = []

  brd[:grid].each_with_index do |sq, idx|
    if sq == ' '
      open_sq_coords << idx
    end
  end

  rows_or_cols = []

  open_sq_coords.each do |open_sq_coord|
    x, y = to_2d(brd, open_sq_coord)
    rows_or_cols << y if !cols
    rows_or_cols << x if cols
  end

  rows_or_cols.uniq.sort
end

def to_2d(brd, coord)
  y_coord = 0

  until y_coord * brd[:grid_size] > coord
    y_coord += 1
  end

  y_coord -= 1
  x_coord = coord - y_coord * brd[:grid_size]

  return x_coord, y_coord
end

def to_1d(brd, row, col)
  row * brd[:grid_size] + col
end

# Returns the 1d coordinates of a human move.
def human_move!(brd, plyr)
  loop do
    coord_1d = get_human_move_coord(brd, plyr, true) +
               get_human_move_coord(brd, plyr, false) * brd[:grid_size]

    if brd[:grid][coord_1d] == ' '
      brd[:grid][coord_1d] = plyr[:pc]
      return coord_1d
    end

    prompt(MESSAGES['sq_occupied'])
  end
end

# Returns an empty square in a given vector (either rows or columns).
# Returns nil if no such square exists.
def find_empty_sq_in_vec(brd, vec, vec_num = '0')
  (0...brd[:grid_size]).each do |orthog_vec_num|
    case vec
    when :rows then
      sq = to_1d(brd, vec_num, orthog_vec_num)
    when :cols then
      sq = to_1d(brd, orthog_vec_num, vec_num)
    when :diag1 then
      sq = to_1d(brd, orthog_vec_num, orthog_vec_num)
    when :diag2 then
      sq = to_1d(brd, orthog_vec_num, brd[:grid_size] - orthog_vec_num - 1)
    end
    return sq if brd[:grid][sq] == ' '
  end

  nil
end

# Depending on the given mode, either (win = true):
# - Returns a square in a given vector (either rows or columns) that,
#  if occupied with the given piece, results in a win for that piece.
# - Returns nil if no such square exists.
# or (win = false)
# - Returns a square in a given vector (either rows or columns) that,
#  if occupied by any piece other than the given piece, results in a loss
#  for the given piece.
# - Returns nil if no such square exists.
# rubocop: disable Metrics/CyclomaticComplexity
# rubocop: disable Metrics/PerceivedComplexity
def find_loss_win_sq_in_rows_cols(brd, brd_state, pc, rows_cols, win)
  found_vecs = find_vecs_with_pc_count(brd_state,
                                       brd[:grid_size] - 1,
                                       rows_cols)

  found_vecs.each do |found_vec|
    found_sq = find_empty_sq_in_vec(brd, rows_cols, found_vec[:vec_num])

    if !found_sq.nil? && found_vec[:pc] == pc && win
      return found_sq
    elsif !found_sq.nil? && found_vec[:pc] != pc && !win
      return found_sq
    end
  end

  nil
end

# Depending on the given mode, either (win = true):
# - Returns a square in a given diagonal that, if occupied with the given
#  piece, results in a win for that piece.
# - Returns nil if no such square exists.
# or (win = false)
# - Returns a square in a given diagonal that, if occupied by any piece other
# than the given piece, results in a loss for the given piece.
# - Returns nil if no such square exists.
def find_loss_win_sq_in_diags(brd, brd_state, pc, diag1_or_diag2, win)
  found_pc = find_vec_with_pc_count(brd_state[diag1_or_diag2],
                                    brd[:grid_size] - 1)

  found_sq = found_pc.nil? ? nil : find_empty_sq_in_vec(brd, diag1_or_diag2)

  if !found_sq.nil? && found_pc == pc && win
    return found_sq
  elsif !found_sq.nil? && found_pc != pc && !win
    return found_sq
  end

  nil
end
# rubocop: enable Metrics/CyclomaticComplexity
# rubocop: enable Metrics/PerceivedComplexity

# Depending on the given mode, either (win = true):
# - Returns a square that, if occupied with the given piece, results in a win
#   for that piece.
# - Returns nil if no such square exists.
# or (win = false)
# - Returns a square that, if occupied by any piece other than the given piece,
#   results in a loss for the given piece.
# - Returns nil if no such square exists.
def find_loss_win_sq(brd, brd_state, pc, win)
  found_sq = find_loss_win_sq_in_rows_cols(brd, brd_state, pc, :rows, win)
  return found_sq if !found_sq.nil?

  found_sq = find_loss_win_sq_in_rows_cols(brd, brd_state, pc, :cols, win)
  return found_sq if !found_sq.nil?

  found_sq = find_loss_win_sq_in_diags(brd, brd_state, pc, :diag1, win)
  return found_sq if !found_sq.nil?

  found_sq = find_loss_win_sq_in_diags(brd, brd_state, pc, :diag2, win)
  return found_sq if !found_sq.nil?

  nil
end

def rand_empty_sq(brd)
  empty_sqs = []
  brd[:grid].each_with_index do |obj, idx|
    empty_sqs << idx if obj == ' '
  end
  empty_sqs.sample
end

# Returns the 1d coordinates of the square that the AI decided to move.
# The AI moves on a square that results in a win. If no such square exists,
# the AI moves on a square that results in a win for any other player.
# If no such square exists, the AI selects a random square.
def ai_move!(brd, brd_state, plyr)
  prompt("#{MESSAGES['ai']} #{plyr[:num]} #{MESSAGES['turn']}")

  win_sq = find_loss_win_sq(brd, brd_state, plyr[:pc], true)
  loss_sq = find_loss_win_sq(brd, brd_state, plyr[:pc], false)

  sq = if !win_sq.nil?
         win_sq
       elsif !loss_sq.nil?
         loss_sq
       else
         rand_empty_sq(brd)
       end

  brd[:grid][sq] = plyr[:pc]
  sq
end

# Returns the piece whose count equals the given count in a given vector:
# rows, columns and diagonals.
# Returns nil if no such square exists.
def find_vec_with_pc_count(vec_state, count)
  pc = vec_state.key(count).to_s
  pc.empty? ? nil : pc
end

# Returns a list of vectors (rows or columns), where each vector
# contains a piece whose count equals the given count.
def find_vecs_with_pc_count(brd_state, count, vecs = :rows)
  found_vecs = []

  brd_state[vecs].each_with_index do |vec_state, vec_num|
    pc = find_vec_with_pc_count(vec_state, count)
    if !!pc
      found_vecs << { pc: pc, vec_num: vec_num }
    end
  end

  found_vecs
end

def win_in_rows_or_cols?(brd, brd_state, pc, vec)
  found_vecs = find_vecs_with_pc_count(brd_state, brd[:grid_size], vec)

  found_pc_in_vec = if !found_vecs.empty?
                      found_vecs.first[:pc]
                    end

  found_pc_in_vec == pc
end

def win_in_diags?(brd, brd_state, pc, vec)
  found_pc_in_vec = find_vec_with_pc_count(brd_state[vec], brd[:grid_size])

  found_pc_in_vec == pc
end

def win?(brd, brd_state, pc)
  win_in_rows = win_in_rows_or_cols?(brd, brd_state, pc, :rows)
  win_in_cols = win_in_rows_or_cols?(brd, brd_state, pc, :cols)
  win_in_diag1 = win_in_diags?(brd, brd_state, pc, :diag1)
  win_in_diag2 = win_in_diags?(brd, brd_state, pc, :diag2)

  (win_in_rows || win_in_cols || win_in_diag1 || win_in_diag2)
end

def tie?(brd)
  brd[:grid].count(' ') == 0
end

def determine_match_result(brd, brd_state, pc)
  if win?(brd, brd_state, pc)
    'win'
  elsif tie?(brd)
    'tie'
  else
    'continue'
  end
end

def print_match_result(plyr, result)
  case result
  when 'win'
    if result == 'win'
      human_or_ai = plyr[:human?] ? 'human' : 'AI'

      prompt("#{MESSAGES['plyr']} "\
             "#{human_or_ai} "\
             "#{plyr[:num]} "\
             "#{MESSAGES['won_match']}")
    end
  when 'tie'
    prompt(MESSAGES['tie'])
  end
end

def game_over?(plyrs)
  plyrs.any? { |plyr| plyr[:score] == WIN_CONDITION }
end

def display_winner(plyrs)
  plyrs.each do |plyr|
    human_or_ai = plyr[:human?] ? 'human' : 'AI'
    if plyr[:score] == WIN_CONDITION
      prompt("#{MESSAGES['plyr']} "\
             "#{human_or_ai} "\
             "#{plyr[:num]} "\
             "#{MESSAGES['won_game']}")
    end
  end
end

def wait_user(msg)
  user_input = ''
  until user_input =~ /./
    prompt(msg)
    user_input = gets.chomp
  end
end

def play_again?
  user_input = ''
  until %w(y n).include?(user_input)
    prompt(MESSAGES['again'])
    user_input = gets.chomp.downcase
  end
  user_input == 'y'
end

clean_screen
prompt(MESSAGES['welcome'])
game_windup = 0

# Game loop.
# A game consists of 5 match wins.
# players array is a stack that rotates (shifts left) after every move.
# The player at the top of the stack gets to move.
# match_windup keeps track of number of stack rotations made during a match.
# game_windup keeps track of number of stack rotations made during the game.

loop do
  grid_size = req_grid_size
  avail_pcs = PIECES_CHOICE.dup
  brd = init_brd(grid_size)
  plyrs = []
  human_count = req_plyr_count(0, grid_size, true)
  ai_count = req_ai_count(grid_size, human_count)

  plyrs += populate_plyrs!(human_count, avail_pcs, true)
  plyrs += populate_plyrs!(ai_count, avail_pcs, false)

  shft_til_fst_plyr = calc_shft_til_first_plyr(plyrs,
                                               human_count,
                                               ai_count)
  plyrs.rotate!(shft_til_fst_plyr)

  # Match loop.
  loop do
    match_result = ''
    match_windup = 0
    clear_brd!(brd)
    brd_state = init_brd_state(grid_size)
    curr_plyr = plyrs.first

    # Play moves loop.
    loop do
      curr_plyr = plyrs.first

      draw_brd(brd)
      plyrs_in_print_order = reorder_plyrs_to_print(plyrs,
                                                    shft_til_fst_plyr,
                                                    game_windup,
                                                    match_windup)
      print_scores(plyrs_in_print_order, curr_plyr)

      if curr_plyr[:human?] == true
        sq_coord_1d = human_move!(brd, curr_plyr)
      else
        sq_coord_1d = ai_move!(brd, brd_state, curr_plyr)
        wait_user(MESSAGES['continue'])
      end

      update_brd_state!(brd, brd_state, sq_coord_1d, curr_plyr)
      draw_brd(brd)

      plyrs_in_print_order = reorder_plyrs_to_print(plyrs,
                                                    shft_til_fst_plyr,
                                                    game_windup,
                                                    match_windup)
      print_scores(plyrs_in_print_order, curr_plyr)

      match_result = determine_match_result(brd, brd_state, curr_plyr[:pc])

      if match_result != 'continue'
        curr_plyr[:score] += 1 if match_result == 'win'
        break
      end

      plyrs.rotate!
      match_windup += 1
    end

    clean_screen
    draw_brd(brd)
    plyrs_in_print_order = reorder_plyrs_to_print(plyrs,
                                                  shft_til_fst_plyr,
                                                  game_windup,
                                                  match_windup)
    print_scores(plyrs_in_print_order, curr_plyr)

    print_match_result(curr_plyr, match_result)

    # Unwinds the stack to the order at the start of the match.
    plyrs.rotate!(-match_windup)

    break if game_over?(plyrs)

    # The next player goes first next match.
    plyrs.rotate!
    game_windup += 1
    wait_user(MESSAGES['next_match'])
  end

  # Unwinds the stack to the order at the start of the game.
  plyrs.rotate!(-game_windup)
  display_winner(plyrs)
  break if !play_again?
end
