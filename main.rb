require 'rubygems'
require 'sinatra'
require 'pry'

use Rack::Session::Cookie, :key => 'rack.session',
                           :path => '/',
                           :secret => 'Im the best'


helpers do
  def make_game_deck
    card_numbers = ['Two', 'Three', 'Four', 'Five', 'Six', 'Seven', 'Eight', 'Nine', 'Ten',
                'Jack', 'Queen', 'King', 'Ace']
    card_suits = ['Clubs', 'Diamonds', 'Hearts', 'Spades']


    session[:deck] = []
    card_suits.each do |suit|
      card_numbers.each do |number|
        session[:deck] << number + " of " + suit
      end
    end
    session[:deck].shuffle!
  end

  def calculate_value(hand)
    card_values = {'Two' => 2, 'Three' => 3, 'Four' => 4, 'Five' => 5, 'Six' => 6, 'Seven' => 7, 
      'Eight' => 8, 'Nine' => 9, 'Ten' => 10, 'Jack' => 10, 'Queen' => 10, 'King' => 10,
      'Ace' => 1}
    value = 0
    hand.each do |card|
      value += card_values[card.split[0]]
    end
    number_of_aces = 0
    number_of_aces = hand.select {|card| card.split[0] == 'Ace'}.length
    while number_of_aces > 0 && value > 21
      value -= 10
      number_of_aces -= 1
    end
    value
  end
end

before do
  @show_hit_or_stay_buttons = true
  @dealer_turn = false
end


get '/' do
  if session[:player_name]
    redirect '/game'
  else 
    redirect '/new_player'
  end
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
  session[:player_hand] << session[:deck].pop
  if calculate_value(session[:player_hand]) > 21
    session[:cash] -= session[:bet]
    @error = "#{session[:player_name]} busted! You now have $#{session[:bet]}."
    @show_hit_or_stay_buttons = false
  end
  erb :game
end

post '/stay' do
  @success = "You have chosen to stay."
  @show_hit_or_stay_buttons = false
  erb :game
end







