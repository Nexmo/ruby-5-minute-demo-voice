# Require dependencies
require 'sinatra'
require 'sinatra/multi_route'
require 'sinatra/activerecord'
require 'vonage'
require 'dotenv/load'
require 'json'

# Require models
current_dir = Dir.pwd
Dir["#{current_dir}/models/*.rb"].each { |file| require file }

# Set up the database
set :database, { adapter: 'postgresql',  encoding: 'unicode', database: 'voice_demo_db', pool: 2 }

# Helper method to parse incoming phone call data into JSON
helpers do
  def parsed_body
    JSON.parse(request.body.read)
  end
end

# Set content type for application to JSON
before do
  content_type :json
end

# Create variables to hold Vonage API credentials
VONAGE_API_KEY = ENV['VONAGE_API_KEY']
VONAGE_API_SECRET = ENV['VONAGE_API_SECRET']
VONAGE_APPLICATION_ID = ''
VONAGE_NUMBER = ''

# Instantiate Vonage SDK client
def vonage
  @vonage ||= Vonage::Client.new(
    api_key: VONAGE_API_KEY,
    api_secret: VONAGE_API_SECRET,
    application_id: VONAGE_APPLICATION_ID,
    private_key: File.read('./private.key')
  )
end

# Accept incoming phone calls and create new contestant entries
route :post, '/webhooks/answer' do
  from = params['from'] || parsed_body['from']

  new_contestant = Contestant.create(phone_number: from)

  if new_contestant
    puts "New entry received from #{new_contestant.phone_number}"
    message = 'Thanks for entering the raffle!'
  else
    message = 'Thanks for calling! Remember there is one entry per phone number.'
  end

  [{
    action: 'talk',
    text: message
  }].to_json
end

route :get, '/winner' do
  winner = Contestant.order('RANDOM()').first
  puts "The winning nunmber is #{winner.phone_number}!"

  puts 'Calling the winner now...'
  response = vonage.voice.create(
    to: [{ type: 'phone', number: winner.phone_number }],
    from: { type: 'phone', number: VONAGE_NUMBER },
    ncco: [{ action: 'talk', text: 'Congratulations! You won! Please find us to claim your prize.' }]
  )

  puts response.inspect
end

route :get, '/webhooks/event' do
  status 200
  body ''
end

# Set application to listen on port 3000
set :port, 3000