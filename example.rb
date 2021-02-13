# Немного сократил методы, выделив некоторые действия в отдельные методы,
# Можно было ещё сократить get_users,
# Добавить валидацию  PromoMessage

# Модели
class PromoMessage < ActiveRecord::Base
    validates :body, presence: true
    validates :date_from, presence: true
    validates :date_to, presence: true
    
end

class User < ActiveRecord::Base
  has_many :ads
  scope :recent, -> { order(created_at: :desc) } #мне кажется так чуть понятней выглядит
end

class Ad < ActiveRecord::Base
end




# Контроллеры
class PromoMessagesController < ApplicationController
  attr_reader :provider

  def new
    build_message  # используем метод создания сообщения
    users_list  # используем список пользователей
  end

  def create
    build_message  # используем метод создания сообщения
    users_list  # используем список пользователей
   
    if @message.save && send_message(recipients)
      redirect_to promo_messages_path, notice: "Messages Sent Successfully!"
    else
      render :new
    end
  end

  # загружаем csv используя список пользователей
  def download_csv
    send_data to_csv(users_list), filename: "promotion-users-#{Time.zone.today}.csv"
  end

  private

  # выносим создание сообщения в отдельный метод
    def build_message
        @message = PromoMessage.new(promo_message_params
    end

    # создаем список пользователей
    def users_list
      if params[:date_from].present? && params[:date_to].present?
        get_users
      end
    end


    def to_csv(data)
      attributes = %w(id phone name)
      CSV.generate(headers: true) do |csv|
        csv << attributes
        data.each do |user|
          csv << attributes.map { |attr| user.send(attr) }
        end
      end
    end

    # используем user_list для отправки сообщений
    def send_message
      users_list.each do |user|
        PromoMessagesSendJob.perform_later(user.phone)
      end
    end

    def get_users
      @users = User.recent.joins(:ads).group("ads.user_id").where("`published_ads_count` = 1").
        where("published_at Between ? AND ?", Date.parse(params[:date_from]), Date.parse(params[:date_to])).page(params[:page])
    end

    def promo_message_params
      params.permit(:body, :date_from, :date_to)
    end
end 
