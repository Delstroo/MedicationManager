//
//  MedicationController.swift
//  MedicationManager
//
//  Created by Aaron Martinez on 12/21/20.
//

import CoreData

class MedicationController {

    static let shared = MedicationController()

    private lazy var fetchRequest: NSFetchRequest<Medication> = {
        let request = NSFetchRequest<Medication>(entityName: "Medication")
        request.predicate = NSPredicate(value: true)
        return request
    }()

    var sections: [[Medication]] { [notTakenMeds, takenMeds] }
    var notTakenMeds: [Medication] = []
    var takenMeds: [Medication] = []

    private init() {}

    func createMedication(name: String, timeOfDay: Date) {
        let medication = Medication(name: name, timeOfDay: timeOfDay)
        notTakenMeds.append(medication)
        CoreDataStack.saveContext()
    }

    func fetchMedications() {
        let medications = (try? CoreDataStack.context.fetch(self.fetchRequest)) ?? []
        takenMeds = medications.filter { $0.wasTakenToday() }
        notTakenMeds = medications.filter { !$0.wasTakenToday() }
    }

    func updateMedicationDetails(_ medication: Medication, name: String, timeOfDay: Date) {
        medication.name = name
        medication.timeOfDay = timeOfDay
        CoreDataStack.saveContext()
    }

    func updateMedicationTakenStatus(_ wasTaken: Bool, medication: Medication) {
        if wasTaken { // if a medication was taken....
            // We must first initialize a TakenDate & get that into context.
            TakenDate(date: Date(), medication: medication)
            // then, we must find the first index of that medication in the notTaken meds array in order to remove it from there
            if let index = notTakenMeds.firstIndex(of: medication) {
                notTakenMeds.remove(at: index)
                // Then we need to append the med to the takenMeds array.
                takenMeds.append(medication)
            }
        } else {
            let mutableTakenDates = medication.mutableSetValue(forKey: "takenDates")

            if let takenDate = (mutableTakenDates as? Set<TakenDate>)?.first(where: { takenDate in
                guard let date = takenDate.date
                else { return false }

                return Calendar.current.isDate(date, inSameDayAs: Date())
            }) {
                mutableTakenDates.remove(takenDate)
                if let index = takenMeds.firstIndex(of: medication) {
                    takenMeds.remove(at: index)
                    notTakenMeds.append(medication)
                }
            }
        }
        CoreDataStack.saveContext()
    }

    func deleteMedication() {

    }
    
}
