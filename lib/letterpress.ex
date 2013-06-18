defmodule Letterpress do

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
    def play(dict, board, player) do
      # a list of word-score tuples sorted descending
      top_words = get_top_words dict, board
      best_word_score = Enum.at top_words, 0

      Board.play dict, board, player, elem(best_word_score, 0)
      best_word_score
    end

    defp get_top_words(dict, board, prefix // '') do
#     start_at = Time.now.to_f
#     @top_words = TopWords.new
#     find_words_from(@board.string, prefix = '', @dict.tree)

#     end_at = Time.now.to_f
#     puts "top words found in #{((end_at - start_at) * 1000).to_i}ms"
#     @top_words
    end

  #   def find_words_from(board_str, prefix, node)
  #     # do we have a match?
  #     if node[:stop] && !@top_words.contains?(prefix) && @board.playable?(prefix)
  #       word_path, score = score(prefix)
  #       @top_words.consider(word_path, score)
  #     end

  #     # essentially an exhaustive dictionary search
  #     # scoped to board letters available. Crazy fast.
  #     node.children.each do |child|
  #       next if child.name == :stop
  #       if i = board_str.index(child.name)
  #         str = board_str[i+1..-1]
  #         str.prepend(board_str[0..i-1]) if i > 0
  #         find_words_from(str, prefix + child.name, child)
  #       end
  #     end
  #   end

  #   def score(word, board = @board)
  #     paths = word_paths(word, board)
  #     paths.map{|path| [path, path_score(path, board)] }.sort_by{|(p, s)| -s }.first
  #   end

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
      if length(top_words) < 40 || elem(word_score, 1) > List.last top_words do
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
  dictionary = Letterpress.Dictionary.load('/usr/share/dict/twl.txt.gz | gunzip | tr A-Z a-z')
  IO.puts "Saving dictionary in binary format for later."
  File.write('dictionary.bin', term_to_binary(dictionary))
end

end_at = Time.now

IO.puts "dictionary loaded in #{end_at - start_at}s"

test_words = %w(apple stove meerkaadf beer elephant sicophant sycophant)
Enum.each test_words, fn(word) ->
  IO.puts "is #{word} a word? #{Letterpress.Dictionary.is_word?(word, dictionary)}"
end

# board =

player1 = 1
player2 = 2


# class Game
#   class EInvalidWord < StandardError
#     def initialize(word)
#       super("#{word} is not a valid word")
#     end
#   end
#   class EInvalidPlay < StandardError
#     def initialize(word)
#       super("#{word} is not a legal play")
#     end
#   end
#   class EAlreadyPlayed < StandardError
#     def initialize(word)
#       super("#{word} has already been played")
#     end
#   end

#   def initialize(board)
#     @board = board
#     @dict = board.dict
#   end

#   def start(players)
#     players.sort_by!{rand}
#     @players = players
#     @players.each_with_index {|p, i|
#       # p.player_id = i+1
#       p.new_game(@board)
#     }
#     while !game_finished? do
#       players.each{|player|
#         player.play
#       }
#     end
#   end

#   def play(player, word)
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
#   end
# end


# require './player'
# require './game'
# require './board'
# require './dictionary'
# # b=Board.new
# # # b=Board.new('zegtz wsyxe jrfcq dizhl ccfft')
# # # b=Board.new('ihuix msvex atfsp uasro pgnwk')
# # b=Board.new('zegtz wsyxe jrfcq dizhl ccfft')
# b=Board.new('qsnin iodsw nfgvp noiss mesnk')
# b.display
# p1=Player.new(b)
# p1.number = 1
# p2=Player.new(b)
# p2.number = 2

# while !b.over? do
#   puts "player 1 plays #{p1.play.inspect}"
#   b.display

#   puts "player 2 plays #{p2.play.inspect}"
#   b.display
# end

# puts "winner is player #{b.victory_for(p1) ? 1 : 2}"