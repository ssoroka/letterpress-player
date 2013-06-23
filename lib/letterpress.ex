# is there a better way to extend Enum to add select?
# or don't bother and just use a list comprehension?
defmodule EnumHelper do
  def select(arr, fun) do
    Enum.reduce arr, [], fn(i, acc) ->
      if fun.(i) do
        acc ++ [i]
      else
        acc
      end
    end
  end
end

# a 14 line test framework.
defmodule Assert do
  def equal(a, b) do
    equal(a, b, nil)
  end

  def equal(a, b, _) when a == b do
  end

  def equal(a, b, msg) do
    raise "#{a} is not equal to #{b}; #{msg}"
  end

  def ok(a) do
    ok(a, nil)
  end

  def ok(a, _) when !!a do
  end

  def ok(a, msg) do
    raise "#{a} is not true; #{msg}"
  end
end

defrecord Square, letter: nil, point: {0, 0}, locked: false, player: nil do
  def lock(square) do
    new(point: square.point, locked: true, player: square.player)
  end

  def unlock(square) do
    new(point: square.point, locked: false, player: square.player)
  end

  def color(square) do
    _player_color(square.player, square.locked)
  end

  def take(square, player) do
    new point: square.point, locked: false, player: player
  end

  def _player_color(nil, false), do: 8
  def _player_color(1, false), do: 81
  def _player_color(1, true), do: 21
  def _player_color(2, false), do: 204
  def _player_color(2, true), do: 9
  def _player_color(_, _), do: 220
end

defmodule Board do
  def load_from(str) do
    load_from(str, 0)
  end

  def load_from("", _) do
    []
  end

  def load_from(str, in_pos) do
    str = str |> to_binary |> String.lstrip
    [Square.new(letter: str |> String.at(0), point: {rem(in_pos, 5), div(in_pos, 5)})] ++ load_from(str |> String.slice(1, 30), in_pos + 1)
  end

  def at(board, point) do
    board |> Enum.find fn(square) ->
      square.point == point
    end
  end

  def squares_with(board, letter) do
    board |> EnumHelper.select fn(square) ->
      square.letter == letter
    end
  end

  def display(board) do
    board |> Enum.each fn(square) ->
      IO.write "\x1b[38;5;#{square.color}m#{square.letter}\x1b[0m "
      case square.point do
      {4,4} ->
        IO.write "\n\n"
      {4,_} ->
        IO.write "\n"
      {_,_} ->
      end
    end
    board
  end

  def play(board, dict, player, word) do
  #   def play(player, word)
  #     raise "#{word} is not playable" if !playable?(word)
  #     word = word.split('') if word.respond_to?(:split)
  #     board = fork(@data)
  #     word.each_with_index do |letter, i|
  #       square = if letter.is_a?(square)
  #         board.get(letter.x, letter.y)
  #       else
  #         board.find(letter)
  #       end
  #       board.set(square.take(player)) unless square.locked?
  #     end
  #
  #     board.refresh_locks
  #
  #     word = word.join('')
  #     board.played_words = @played_words + [word]
  #     board.shortened_played_words = @shortened_played_words + [shorten(word)]
  #     # word
  #     board
  #   end
  end

end

defmodule Dictionary do
  def load(dictionary) do
    System.cmd("cat #{dictionary}") |> String.replace("'", "") |> String.split("\n") |> Enum.filter(fn(s) ->
      String.length(s) >= 2 && Regex.match?(%r/^[a-z]+$/, s)
    end) |> Enum.sort |> list_to_gb_tree
  end

  def is_word?(word, tree) do
    _check_word_in_tree(word, tree)
  end

  def list_to_gb_tree(list) do
    Enum.reduce list, HashDict.new, fn(word, tree) ->
      _insert_word_in_tree(word, tree)
    end
  end

  defp _check_word_in_tree('', tree) do
    tree[:stop]
  end

  defp _check_word_in_tree(_, nil) do
    false
  end

  defp _check_word_in_tree(word, tree) when is_binary word do
    _check_word_in_tree binary_to_list(word), tree
  end

  defp _check_word_in_tree(word, tree) do
    [first|rest] = String.split(word, %r{}, global: false)
    _check_word_in_tree(rest, tree[first])
  end

  defp _insert_word_in_tree('', tree) do
    HashDict.put_new(tree, :stop, true)
  end

  defp _insert_word_in_tree(word, tree) when is_binary(word) do
    _insert_word_in_tree(binary_to_list(word), tree)
  end

  defp _insert_word_in_tree(word, tree) do
    [first|rest] = String.split(word, %r{}, global: false)
    child = tree[first] || HashDict.new
    child = _insert_word_in_tree(rest, child)
    HashDict.put(tree, first, child)
  end
end

defmodule Player do
  def play_turn(board, dict, player) do
    # a list of word-score tuples sorted descending
    top_words = find_words_from(dict, board, [], [])
    best_word_score = Enum.at top_words, 0
    case best_word_score do
    nil ->
      {}
    else
      elem best_word_score, 0
    end
  end

  defp find_words_from(partial_dict, board, partially_built_word, top_words) do
    # exhaustive dictionary search
    # scoped to board letters available. Crazy fast.
    partial_dict |> Enum.reduce top_words, fn(child, top_words) ->
      case child do
      {:stop, _} ->
        _consider top_words, score(board, partially_built_word)
      {letter, children} ->
        board |> Board.squares_with(letter) |> Enum.reduce top_words, fn(square, top_words) ->
          find_words_from(children, board -- [square], partially_built_word ++ [letter], top_words)
        end
      end
    end
  end

  def score(board, word) do
    #   def score(word, board = @board)
    #     paths = word_paths(word, board)
    #     paths.map{|path| [path, path_score(path, board)] }.sort_by{|(p, s)| -s }.first
    #   end
  end

  #   def path_score(path, board = @board)
  #     # board2 = board.duplicate
  #     # board2.play(self, path)

  #     board2 = board.play(self, path)
  #     # score = board2.score_for(self) * (board2.locked_for(self) + 1)
  #     score = board2.weighted_value_for(self)
  #     score += 1000000 if board2.victory_for(self) # if you won
  #     score /= 2 if board2.unused_letters == 1 unless board2.locked_for(self) >= 15
  #     score
  #   end

  #   def word_paths(word, board = @board)
  #     word_letter_options = []
  #     word.each_char do |c|
  #       squares = board.find_all(c)
  #       word_letter_options.push(squares)
  #     end

  #     paths = []
  #     build_word_paths(word_letter_options) do |word_path|
  #       paths << word_path
  #     end

  #     paths
  #   end

  #   # [["b", "h"], ["e"], ["l"], ["l", "k"], ["o"]]

  #   def build_word_paths(word_letter_options, prefix = [], &block)
  #     if letter_options = word_letter_options.first
  #       letter_options.each do |letter|
  #         # if prefix.none?{|l| l == letter && l.x == letter.x && l.y == letter.y }
  #           build_word_paths(word_letter_options[1..-1], prefix + [letter], &block)
  #         # end
  #       end
  #     else
  #       block.call(prefix)
  #     end
  #   end

  #   def played_words
  #     @board.played_words
  #   end
  def _consider(top_words, word_score) do
    IO.puts "#{word_score}"
    if length(top_words) < 40 || elem(word_score, 1) > elem(List.last(top_words), 1) do
      insert_position = Enum.find_index top_words, fn(word_score2) -> elem word_score2, 1 < elem word_score, 1 end
      top_words = List.insert_at(top_words, insert_position, word_score)
      List.delete(top_words, Enum.at(top_words, 40))
    end
  end

  def is_top_word?(top_words, word) do
    Enum.find_value top_words, fn({_word, score}) -> _word == word end
  end

  def top_words_to_words(top_words) do
    Enum.map top_words, fn({word, _}) -> word end
  end
end

defmodule Time do
  def now do
    {{year, month, day},{hour,min,sec}} = :erlang.localtime()

    epoc = (year - 1970) * 12 + month
    epoc = epoc * 30.369 + day
    epoc = epoc * 24 + hour
    epoc = epoc * 60 + min
    epoc = epoc * 60 + sec
    trunc epoc
  end
end
Time.now

start_at = Time.now

# dict1 = '/usr/share/dict/words | tr A-Z a-z'
# dict2 = '/usr/share/dict/sowpods.txt.gz | gunzip | tr A-Z a-z'
# dict3 = '/usr/share/dict/twl.txt.gz | gunzip | tr A-Z a-z'

IO.puts "loading dictionary. Please wait.."
case File.read('dictionary.bin') do
{:ok, binary} ->
  dictionary = binary_to_term(binary)
{:error, reason} ->
  dictionary = Dictionary.load('/usr/share/dict/twl.txt.gz | gunzip | tr A-Z a-z')
  IO.puts "Saving dictionary in binary format for later."
  File.write('dictionary.bin', term_to_binary(dictionary))
end

end_at = Time.now

IO.puts "dictionary loaded in #{end_at - start_at}s"

valid_words = %w(apple stove beer elephant sycophant)
Enum.each valid_words, fn(word) ->
  Assert.ok Dictionary.is_word?(word, dictionary), "#{word} should be a word"
end

invalid_words = %w(meerkaadf sicophant)
Enum.each invalid_words, fn(word) ->
  Assert.ok !Dictionary.is_word?(word, dictionary), "#{word} should not be a word"
end

board = Board.load_from("qsnin iodsw nfgvp noiss mesnk")
t = Board.at(board, {2,3})
Assert.equal "i", t.letter, "this should select 'i'"
Assert.ok !t.locked, "letter should not be locked yet"

board |> Board.display

player1 = 1
player2 = 2


defmodule Game do
  def over?(board) do
    board |> Enum.all? fn(square) -> square.player end
  end

  def play(board, dictionary, player_a, player_b) do
    if Game.over?(board) do
      {:done, player_a}
    else
      word = Player.play_turn(board, dictionary, player_a)
      play_word(board, dictionary, player_a, word) |> Board.display |> play(dictionary, player_b, player_a)
    end
  end

  def play_word(board, dictionary, player, word) do
#     if !@board.playable?(word)
#       if !@dict.word?(word)
#         raise EInvalidWord.new(word)
#       elsif @board.played_already?(word)
#         raise EAlreadyPlayed.new(word)
#       else
#         raise EInvalidPlay.new(word)
#       end
#     end
#     @board.play(word)
    board
  end
end

Assert.ok !Game.over?(board)

{win_state, player} = Game.play(board, dictionary, player1, player2)

# puts "winner is player #{b.victory_for(p1) ? 1 : 2}"

# # b=Board.new
# # # b=Board.new('zegtz wsyxe jrfcq dizhl ccfft')
# # # b=Board.new('ihuix msvex atfsp uasro pgnwk')
# # b=Board.new('zegtz wsyxe jrfcq dizhl ccfft')
# b=Board.new('qsnin iodsw nfgvp noiss mesnk')
