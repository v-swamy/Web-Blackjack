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
      'Ace' => 1}

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
      value += CARD_VALUES[card.split[0]]
    end
    number_of_aces = 0
    number_of_aces = hand.select {|card| card.split[0] == 'Ace'}.length
    while number_of_aces > 0 && value > 21
      value -= 10
      number_of_aces -= 1
    end
    value
  end

  def card_image(card)
    suit = card.split[2].downcase
    value = CARD_VALUES[card.split[0]].to_s

    if ['Jack', 'Queen', 'King', 'Ace'].include?card.split[0]
      value = card.split[0].downcase
    end

    file = suit + '_' + value
    "<img src='/images/cards/#{file}.jpg' class='card_image'>"
  end 
end

before do
  @show_hit_or_stay_buttons = true
  @dealer_turn = false
end


get '/' do
  redirect '/new_player'
end

get '/new_player' do
  erb :new_player
end

post '/set_name' do
  session[:player_name] = params[:player_name]
  session[:cash] = 500
  redirect '/bet'
end

get '/bet' do
  erb :bet
end

post '/save_bet' do
  session[:bet] = params[:bet].to_i
  redirect '/game'
end


get '/game' do
  make_game_deck
  session[:player_hand] = []
  session[:dealer_hand] = []
  session[:player_hand] << session[:deck].pop
  session[:dealer_hand] << session[:deck].pop
  session[:player_hand] << session[:deck].pop
  session[:dealer_hand] << session[:deck].pop
  erb :game
end
  
post '/hit' do
  binding.pry
  session[:player_hand] << session[:deck].pop
  if calculate_value(session[:player_hand]) > 21
    session[:cash] -= session[:bet]
    @error = "#{session[:player_name]} busted! You now have $#{session[:bet]}."
    @show_hit_or_stay_buttons = false
  end
  erb :game
end

post '/stay' do
  binding.pry
  @success = "You have chosen to stay."
  @show_hit_or_stay_buttons = false
  erb :game
end







