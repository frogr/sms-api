class MessagesController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:callback]
  before_action :set_message, only: %i[ show edit update destroy ]

  def index
    @messages = Message.all
  end

  def show
  end

  def new
    @message = Message.new
  end

  def create
    @message = Message.new(message_params)

    respond_to do |format|
      if @message.save
        MessageSenderService.new(@message).call
        format.html { redirect_to root_path, notice: "Message was successfully created." }
      else
        format.html { render :new, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @message.update(message_params)
        format.html { redirect_to message_url(@message), notice: "Message was successfully updated." }
      else
        format.html { render :edit, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @message.destroy

    respond_to do |format|
      format.html { redirect_to messages_url, notice: "Message was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  def callback
    @message = Message.find_by(external_id: params[:message_id])
    @message.update(status: params[:status])

    if @message.status == 'failed'
      failover_provider = @message.provider == MessageSenderService::PROVIDERS[0] ? MessageSenderService::PROVIDERS[1] : MessageSenderService::PROVIDERS[0]
      @message.update(provider: failover_provider)
      MessageSenderService.new(@message).send_message_to_provider(failover_provider)
    end

    render json: @message
  end


  private
    def set_message
      @message = Message.find(params[:id])
    end

    def message_params
      params.require(:message).permit(:to_number, :callback_url, :message, :status, :provider, :external_id)
    end
end
