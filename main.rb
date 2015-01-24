require 'rubygems'
require 'sinatra'
require 'pry'

use Rack::Session::Cookie, :key => 'rack.session',
                           :path => '/',
                           :secret => 'Im the best'


helpers do
  CARD_NUMBERS = ['Two', 'Three', 'Four', 'Five', 'Six', 'Seven', 'Eight', 'Nine', 'Ten',
                'Jack', 'Queen', 'King', 'Ace']
  CARD_SUITS = ['Clubs', 'Diamonds', 'Hearts', 'Spades']
  
  CARD_VALUES = {'Two' => 2, 'Three' => 3, 'Four' => 4, 'Five' => 5, 'Six' => 6, 'Seven' => 7, 
      'Eight' => 8, 'Nine' => 9, 'Ten' => 10, 'Jack' => 10, 'Queen' => 10, 'King' => 10,
      'Ace' => 11}

  def make_game_deck
    session[:deck] = []
    CARD_SUITS.each do |suit|
      CARD_NUMBERS.each do |number|
        session[:deck] << number + " of " + suit
      end
    end
    session[:deck].shuffle!
  end

  def calculate_value(hand)
    value = 0
    hand.each do |card|
      value += CARD_VALUES[card.split.first]
    end
    number_of_aces = 0
    number_of_aces = hand.select {|card| card.split.first == 'Ace'}.length
    while number_of_aces > 0 && value > 21
      value -= 10
      number_of_aces -= 1
    end
    value
  end

  def card_image(card)
    suit = card.split.last.downcase
    value = CARD_VALUES[card.split.first].to_s
    if ['Jack', 'Queen', 'King', 'Ace'].include?(card.split.first)
      value = card.split.first.downcase
    end
    file = suit + '_' + value
    "<img src='/images/cards/#{file}.jpg' class='card_image'>"
  end 

  def dealer_turn_toggle!
    @show_hit_or_stay_buttons = false
    @dealer_turn = true
    @show_dealer_hit_button = true
  end

  def game_over_button_toggle!
    @show_hit_or_stay_buttons = false
    @dealer_turn = true
    @show_play_again_buttons = true
    @show_dealer_hit_button = false
  end
end

before do
  @show_hit_or_stay_buttons = true
  @dealer_turn = false
  @show_play_again_buttons = false
  @show_dealer_hit_button = false
end


get '/' do
  redirect '/new_player'
end

get '/new_player' do
  erb :new_player
end

post '/set_name' do
  if params[:player_name].empty?
    @error = "Please enter your name to proceed!"
    halt erb :new_player
  end
  session[:player_name] = params[:player_name]
  session[:cash] = 500
  make_game_deck
  redirect '/bet'
end

get '/bet' do
  if session[:cash] == 0
    @error = "#{session[:player_name]} is out of cash! Click <a href='/'>Start Over</a> to play again."
  end
  session[:bet] = nil
  erb :bet
end

post '/save_bet' do
  if params[:bet].to_i > session[:cash]
    @error = "You don't have enough cash! Please enter another bet."
    halt erb :bet
  elsif /\D/.match(params[:bet])
    @error = "Please enter numbers only!"
    halt erb :bet
  elsif params[:bet].empty? || params[:bet].to_i == 0
    @error = "Please enter your bet to proceed!"
    halt erb :bet
  end
  session[:bet] = params[:bet].to_i
  redirect '/game'
end

get '/game' do
  session[:player_hand] = []
  session[:dealer_hand] = []
  session[:player_hand] << session[:deck].pop
  session[:dealer_hand] << session[:deck].pop
  session[:player_hand] << session[:deck].pop
  session[:dealer_hand] << session[:deck].pop
  if calculate_value(session[:player_hand]) == 21
    session[:cash] += session[:bet]
    @success = "#{session[:player_name]} got a blackjack! #{session[:player_name]} wins! You now have $#{session[:cash]}."
    game_over_button_toggle!
  elsif calculate_value(session[:dealer_hand]) == 21
    session[:cash] -= session[:bet]
    @error = "Dealer got a blackjack!  #{session[:player_name]} loses. You now have $#{session[:cash]}."
    game_over_button_toggle!
  end
  erb :game
end
  
post '/player/hit' do
  session[:player_hand] << session[:deck].pop
  if calculate_value(session[:player_hand]) > 21
    session[:cash] -= session[:bet]
    @loser = "#{session[:player_name]} busted! You now have $#{session[:cash]}."
    game_over_button_toggle!
    if session[:cash] == 0
      @loser = "#{session[:player_name]} busted and is out of cash! Click <a href='/'>Start Over</a> to play again."
      @show_play_again_buttons = false
    end
  end
  erb :game, layout: false
end

post '/dealer' do
  dealer_turn_toggle!
  if calculate_value(session[:dealer_hand]) > 17
    redirect '/game/compare'
  end
  erb :game, layout: false
end

get '/game/compare' do
  game_over_button_toggle!
  if calculate_value(session[:dealer_hand]) > 21
    session[:cash] += session[:bet]
    @winner = "Dealer busted! #{session[:player_name]} wins! You now have $#{session[:cash]}."
  elsif calculate_value(session[:player_hand]) > calculate_value(session[:dealer_hand])
    session[:cash] += session[:bet]
    @winner = "#{session[:player_name]} wins! You now have $#{session[:cash]}."
  elsif calculate_value(session[:player_hand]) < calculate_value(session[:dealer_hand])
    session[:cash] -= session[:bet]
    @loser = "Dealer wins! You now have $#{session[:cash]}."
  else
    @tie = "It's a tie! You now have $#{session[:cash]}."
  end
  erb :game, layout: false
end

post '/dealer/hit' do
  dealer_turn_toggle!
  session[:dealer_hand] << session[:deck].pop
  if calculate_value(session[:dealer_hand]) <= 17
    erb :game, layout: false
  else
    redirect '/game/compare'
  end
end

post '/game_over' do
  redirect '/game_over'
end

get '/game_over' do
  erb :game_over
end

post '/next_round' do
  if session[:deck].length < 20
    make_game_deck
  end
  redirect '/bet'
end
