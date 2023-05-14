class MessagesController < ApplicationController
  require 'net/http'
  require 'uri'
  require 'json'

  skip_before_action :verify_authenticity_token, only: [:callback]
  before_action :set_message, only: %i[ show edit update destroy ]

  # GET /messages or /messages.json
  def index
    @messages = Message.all
  end

  # GET /messages/1 or /messages/1.json
  def show
  end

  # GET /messages/new
  def new
    @message = Message.new
  end

  # GET /messages/1/edit
  def edit
  end

  # POST /messages or /messages.json
  def create
    @message = Message.new(message_params)

    respond_to do |format|
      if @message.save
        send_message(@message)
        format.html { redirect_to message_url(@message), notice: "Message was successfully created." }
        format.json { render :show, status: :created, location: @message }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @message.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /messages/1 or /messages/1.json
  def update
    respond_to do |format|
      if @message.update(message_params)
        format.html { redirect_to message_url(@message), notice: "Message was successfully updated." }
        format.json { render :show, status: :ok, location: @message }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @message.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /messages/1 or /messages/1.json
  def destroy
    @message.destroy

    respond_to do |format|
      format.html { redirect_to messages_url, notice: "Message was successfully destroyed." }
      format.json { head :no_content }
    end
  end

def send_message(message)
  uri = URI.parse("https://mock-text-provider.parentsquare.com/provider1")
  request = Net::HTTP::Post.new(uri)
  request["Content-Type"] = "application/json"
  request.body = JSON.dump({
    "to_number" => message.to_number,
    "message" => message.message,
    "callback_url" => message.callback_url
  })

  req_options = {
    use_ssl: uri.scheme == "https",
  }

  begin
    response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
      http.request(request)
    end

    if response.code.to_i >= 400
      raise "Server Error: #{response.code} #{response.message}"
    end

    puts "***" * 20
    puts response.code
    puts response
    puts response.body
    puts "***" * 20

    if response.code.to_i == 200
      message.update(external_id: JSON.parse(response.body)["message_id"])
    end

    rescue => e
      puts "An error occurred: [#{response.code}]: #{e.message}"
    end
end


  def callback
    @message = Message.find_by(external_id: params[:message_id])
    @message.update(status: params[:status])
    @message.save
    render json: @message
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_message
      @message = Message.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def message_params
      params.require(:message).permit(:to_number, :callback_url, :message, :status, :external_id)
    end
end
