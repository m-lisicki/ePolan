//
//  ChartsView.swift
//  ePolan
//
//  Created by Michał Lisicki on 13/05/2025.
//

import Charts
import SwiftUI

struct Point: Identifiable {
    let id = UUID()
    var value: Double
}

struct WeekData: Identifiable {
    let id = UUID()
    let weekNumber: Int
    let totalPoints: Double
}

struct ChartsView: View {
    let pointsArray: [PointDto]

    var body: some View {
        ScrollView {
            ActivityPointsChart(pointsArray: pointsArray)
                .padding()
        }
        .navigationTitle("Graphs")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ActivityPointsChart: View {
    let pointsArray: [PointDto]

    var points: Double {
        pointsArray.reduce(0) { $0 + $1.activityValue }
    }

    var weeklyPoints: [WeekData] {
        let grouped = Dictionary(grouping: pointsArray.filter { $0.lesson.classDate < Date() }) {
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
                .font(.title3)
            Text(String(format: "%.1f", points))
                .fontWeight(.light)
                .accessibilityLabel("You've got \(points) points")
        }
        .padding(.bottom)
        Chart {
            ForEach(weeklyPoints) { week in
                BarMark(
                    x: .value("Week", week.weekNumber),
                    y: .value("Points", week.totalPoints),
                )
                .annotation(position: .top) {
                    Text(String(format: "%.1f", week.totalPoints))
                        .font(.caption)
                        .fontWeight(.light)
                }
            }
        }
        .chartXAxisLabel("Week")
        .chartXVisibleDomain(length: 10)
        .chartScrollableAxes(.horizontal)
        .aspectRatio(1.75, contentMode: .fit)
    }
}

#Preview {
    NavigationStack {
        ChartsView(pointsArray: PointDto.getMockData())
    }
}
