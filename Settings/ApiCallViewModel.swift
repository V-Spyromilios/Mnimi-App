//
//  ApiCallViewModel.swift
//  MyndVault
//
//  Created by Evangelos Spyromilios on 27.07.24.
//

import Foundation
import SwiftUI
import Combine

final class ApiCallViewModel: ObservableObject {
    @Published var monthlyApiCalls: [String: Int] = UserDefaults.standard.dictionary(forKey: "monthlyApiCalls") as? [String: Int] ?? [:]
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        $monthlyApiCalls
            .sink { newValue in
                UserDefaults.standard.set(newValue, forKey: "monthlyApiCalls")
            }
            .store(in: &cancellables)
    }
    
    func incrementApiCallCount() {
        let currentMonth = getCurrentMonth()
        if let count = monthlyApiCalls[currentMonth] {
            monthlyApiCalls[currentMonth] = count + 1
        } else {
            monthlyApiCalls[currentMonth] = 1
        }
    }
    
    func getCurrentMonth() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        return formatter.string(from: Date())
    }
    
    func getMonthName(from key: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        if let date = formatter.date(from: key) {
            formatter.dateFormat = "MMMM yyyy"
            return formatter.string(from: date)
        }
        return key
    }
}
