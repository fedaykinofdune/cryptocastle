require 'sinatra'
require 'sinatra/config_file'
require 'httparty'

puts "#{Dir.pwd}/config.yml"
config_file "#{Dir.pwd}/config.yml"

class Game
    WALLET_GUID = 'da48e315-5ada-4e41-b5d8-0114e6033f1c'
    WALLET_ADDRESS = '1BZSrMWNETLSEs4bFEnxxz1UX4c2uPeudz'
    WALLET_PASSWORD = ARGV[0]
    PAYMENT_URL = "https://blockchain.info/merchant/#{WALLET_GUID}/payment"
    HOUSE_EDGE = 0.01
    SATOSHI_PER_BITCOIN = 100000000 

    def init(payout_address)
        @payout_address = payout_address
    end

    # Amount is in Satoshi.
    def bet(amount)
        if win_bet
            payout_amount = amount * (2 - HOUSE_EDGE)
            note = self.make_note(amount, payout_amount)
            self.payout(payout_amount, note)
        end
    end
    
    private

    def make_note(amount, payout_amount)
        bet = amount / SATOSHI_PER_BITCOIN
        winnings = payout_amount / SATOSHI_PER_BITCOIN
        "#{settings.site_name}: Bet #{bet}, won #{winnings}"
    end

    def payout(amount, note='')
        HTTParty.post(PAYMENT_URL, 
            main_password: WALLET_PASSWORD,
            to: @payout_address,
            amount: amount,
            from: WALLET_ADDRESS,
            note: note
        )
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

post '/bet' do
    if params[:test]
        return
    end

    # TODO: Verify secret.

    # Bitcoin amount received from Blockchain API.
    amount = 50
    game = Game.new(payout_address: params[:input_address])
    game.bet(params[:amount])
end
