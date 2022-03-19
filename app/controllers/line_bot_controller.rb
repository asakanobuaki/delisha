class LineBotController < ApplicationController
  protect_from_forgery except: [:callback]

  def callback
    # request.bodyはStringIOクラスの値になっている。それをreadメソッドで文字列として読み出している
    # StringIOクラスとは、文字列を操作するための様々なメソッドを提供しているクラス
    body = request.body.read

    # 署名の検証(LINEプラットフォームからのPOSTリクエストには署名の情報が含まれている)
    # request.envでhttpリクエストのheaderだけ確認ができる
    # 署名はHTTP_X_LINE_SIGNATUREという変数に格納されているので、request.env['HTTP_X_LINE_SIGNATURE']とすることで署名を参照することができる
    signature = request.env['HTTP_X_LINE_SIGNATURE']
    unless client.validate_signature(body, signature)
      return head :bad_request
    end

    # parse_events_from文字列のbodyを配列で返すメソッド（https://github.com/line/line-bot-sdk-ruby/blob/24066cf50e9b4a2da52aebaddbed866aa60656e8/lib/line/bot/client.rb#L1096）
    events = client.parse_events_from(body)
    

    # messageの属性の分岐
    events.each do |event|
      case event
      when Line::Bot::Event::Message
        case event.type
        when Line::Bot::Event::MessageType::Text
          message = {
            type: 'text',
            text: event.message['text']
          }
          client.reply_message(event['replyToken'], message)
        end
      end
      head :ok
    end

  end

  private

  def client
    @client ||= Line::Bot::Client.new { |config|
      # config.channel_id = ENV["LINE_CHANNEL_ID"]
      config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
      config.channel_token = ENV["LINE_CHANNEL_TOKEN"]
    }
  end

end
