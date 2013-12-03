require 'sinatra'
require 'sinatra/config_file'
require 'httparty'
require 'logger'

config_file "#{Dir.pwd}/config.yml"
LOGGER = Logger.new('debug.log', 'daily')

class Game
    include HTTParty
    debug_output $stderr

    WALLET_GUID = 'da48e315-5ada-4e41-b5d8-0114e6033f1c'
    WALLET_ADDRESS = '1BZSrMWNETLSEs4bFEnxxz1UX4c2uPeudz'
    WALLET_PASSWORD = ENV['WALLET_PASSWORD']
    PAYMENT_URL = "https://blockchain.info/merchant/#{WALLET_GUID}/payment"
    HOUSE_EDGE = 0.01
    SATOSHI_PER_BITCOIN = 100000000 

    def initialize(site_name, payout_address)
        @site_name = site_name
        @payout_address = payout_address
    end

    # Amount is in Satoshi.
    def bet(amount)
        if win_bet
            payout_amount = (amount * (2 - HOUSE_EDGE)).round
            note = make_note(amount, payout_amount)
            payout(payout_amount, note)
            LOGGER.debug(note)
        else
            LOGGER.debug('Lost bet')
        end
    end
    
    private

    def make_note(amount, payout_amount)
        bet = amount / SATOSHI_PER_BITCOIN.to_f
        winnings = payout_amount / SATOSHI_PER_BITCOIN.to_f
        "#{@site_name}: Bet #{bet}, won #{winnings}"
    end

    def payout(amount, note='')
        LOGGER.debug(self.class.post(PAYMENT_URL, query: {
            password: WALLET_PASSWORD,
            to: @payout_address,
            amount: amount,
            from: WALLET_ADDRESS,
            note: note
        }))
    end

    def win_bet
        rand(2).zero?
    end
end

get '/' do
    erb :index, locals: {
        title: settings.site_name,
        wallet_address: Game::WALLET_ADDRESS
    }
end

get '/bet' do
    if params[:test]
        return
    end

    puts params

    # TODO: Verify secret.

    game = Game.new(settings.site_name, params[:input_address])
    game.bet(params[:value].to_i)
end
