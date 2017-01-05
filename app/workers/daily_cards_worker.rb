# encoding: utf-8

class DailyCardsWorker
  include Sidekiq::Worker
  sidekiq_options :retry => true, :backtrace => true

  def perform
    today_string    = Card.format_date(Time.zone.today)
    tomorrow_string = Card.format_date(Time.zone.tomorrow)
    # Iterate over each patient, checking if they have cards for this day.
    patients = Patient.all
    patients.each do |uid, data|
      next if data["cards"].blank?

      cards = data["cards"]
      if cards[today_string].blank?
        Card.generate_cards_for_date(uid, today_string)
      end

      if cards[tomorrow_string].blank?
        Card.generate_cards_for_date(uid, tomorrow_string)
      end
    end

    DailyCardsWorker.perform_at(1.day.from_now)
  end
end
