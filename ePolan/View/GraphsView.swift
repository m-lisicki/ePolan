//
//  GraphsView.swift
//  ePolan
//
//  Created by Michał Lisicki on 13/05/2025.
//  Copyright © 2025 orgName. All rights reserved.
//

import SwiftUI
import Charts

struct WeekData: Identifiable {
    let id = UUID()
    let weekNumber: Int
    let totalPoints: Double
}

struct GraphsView: View {
    let activityPoints: [PointDto]
    
    var weeklyPoints: [WeekData] {
        let grouped = Dictionary(grouping: activityPoints.filter { $0.lesson.classDate < Date() }) {
            Calendar.current.component(.weekOfYear, from: $0.lesson.classDate)
        }
        
        return grouped.sorted(by: { $0.key < $1.key }).enumerated().map { index, element in
            let weekNumber = index + 1
            let totalPoints = element.value.reduce(0) { $0 + $1.activityValue }
            return WeekData(weekNumber: weekNumber, totalPoints: totalPoints)
        }
    }
    
    var body: some View {
        VStack {
            Text("Activity Points")
                .font(.subheadline)
            Chart {
                ForEach(weeklyPoints) { week in
                    BarMark(
                        x: .value("Week", "Week \(week.weekNumber)"),
                        y: .value("Points", week.totalPoints)
                    )
                    .annotation(position: .top) {
                        Text(String(format: "%.1f", week.totalPoints))
                            .font(.caption)
                    }
                }
            }
            .aspectRatio(2, contentMode: .fit)
            .padding()
        }
        .navigationTitle("Graphs")
    }
}

#Preview {
    GraphsView(activityPoints: PointDto.getMockData())
}
