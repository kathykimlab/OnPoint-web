class MedicationSchedule < ActiveRecord::Base

  def self.default_schedule
    schedule = [
      {
        time: "08:00",
        name: "Morning",
        days: [true, true, true, true, true, true, true], # array descirbing days of week to do this action
        medications: ["Lasix", "Toprol XL", "Zestril", "Coumadin", "Riomet"]
      }.with_indifferent_access,
      {
        time: "13:00",
        name: "Afternoon",
        days: [true, true, true, true, true, true, true], # array descirbing days of week to do this action,
        medications: ["Lasix", "Toprol XL", "Zestril", "Riomet"]
      }.with_indifferent_access,
      {
        time: "19:00",
        name: "Evening",
        days: [true, true, true, true, true, true, true], # array descirbing days of week to do this action,
        medications: ["Lipitor"]
      }.with_indifferent_access
    ]

    return schedule
  end

  # uid = 1dae2ad5-9d3c-407c-9d8e-6f3796f0a2ec
  def self.find_by_uid(uid)
    firebase = Firebase::Client.new(ENV["FIREBASE_URL"], ENV["FIREBASE_DATABASE_SECRET"])
    return firebase.get("patients/#{uid}/medication_schedule").body
  end

  def self.update(uid, schedule_id, data)
    firebase = Firebase::Client.new(ENV["FIREBASE_URL"], ENV["FIREBASE_DATABASE_SECRET"])
    path = "patients/#{uid}/medication_schedule/#{schedule_id}/"
    response = firebase.update(path, data)
    return response
  end

  def self.save(uid, data)
    firebase = Firebase::Client.new(ENV["FIREBASE_URL"], ENV["FIREBASE_DATABASE_SECRET"])
    path = "patients/#{uid}/medication_schedule/"
    return firebase.push(path, data)
  end

  # $scope.findMedicationScheduleForCard = function(card) {
  def self.find_by_card(uid, card)
    schedules = self.find_by_uid(uid)
    return schedules[card["object_id"]]
  end

end
