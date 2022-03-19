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
          message = search_and_create_message(event.message['text'])
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

  def search_and_create_message(keyword)
    http_client = HTTPClient.new
    url = 'https://app.rakuten.co.jp/services/api/Travel/KeywordHotelSearch/20170426'
    query = {
      'keyword' => keyword,
      'applicationId' => ENV['RAKUTEN_APPID'],
      'hits' => 5,
      'responseType' => 'small',
      'formatVersion' => 2
    }
    response = http_client.get(url, query)
    response = JSON.parse(response.body)

    if response.key?('error')
      text = "この検索条件に該当する宿泊施設が見つかりませんでした。\n条件を変えて再検索してください。"
    else
    # 変数 = ''のように変数に空文字を初期値とすると、Stringクラスの変数として宣言できる。
      text =''
      response['hotels'].each do |hotel|

        # <<演算子(Stringクラスの値でのみ使える)
        text <<
          hotel[0]['hotelBasicInfo']['hotelName'] + "\n" +
          hotel[0]['hotelBasicInfo']['hotelInformationUrl'] + "\n" +
          "\n"
      end
    end

    message = {
      type: 'text',
      text: text
    }

  end
end
