//
//  TasksAssignedView.swift
//  ePolan
//
//  Created by Michał Lisicki on 30/04/2025.
//

import SwiftUI
import Combine
import ConfettiSwiftUI

#Preview {
    TasksAssignedView(title: "Get Back!", lesson: LessonDto.getMockData().first!, courseId: UUID(), activity: 0.0)
        .environment(NetworkMonitor())
        .environment(RefreshController())
}

struct TasksAssignedView: View, FallbackView {
    typealias T = DeclarationDto
            
    let title: String
    let lesson: LessonDto
    let courseId: UUID
    
    @State var data: Set<DeclarationDto>?
    @State var activity: Double
    
    @State var activityTask: Task<Void, Never>?
    
    @State var showApiError: Bool = false
    @State var apiError: ApiError?
    
    @State var isConfettiActivated = false
        
    @Environment(NetworkMonitor.self) var networkMonitor
    @Environment(RefreshController.self) var refreshController
    
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    
    var body: some View {
        VStack {
            List(lesson.exercises.sortedByNumber(), id: \.id) { exercise in
                HStack {
                    Text("\(exercise.exerciseNumber)\(exercise.subpoint ?? "").")
                    Spacer()
                    if let data = data {
                        Text(data.contains(where: { $0.exercise == exercise && $0.declarationStatus == .approved }) ? "Assigned 🎉" : "Not assigned")
                    }
                }
            }
            .refreshable {
                await fetchData(forceRefresh: true)
            }
            .confettiCannon(trigger: $isConfettiActivated)
            Stepper(value: Binding<Double>(get:{self.activity},set:{self.activity = $0}), in: 0...5, step: 0.5) {
                Text("Points: \(String(format: "%.1f", activity))")
                    .accessibilityLabel("Points selector")
            }
            .accessibilityValue("\(String(format: "%.1f", activity)) points")
            .padding()
        }
        .fallbackView(viewState: viewState)
        .onChange(of: data) {
            if data?.first(where: { $0.declarationStatus == .approved }) != nil && !reduceMotion {
                isConfettiActivated.toggle()
            }
        }
        .onChange(of: activity) { oldValue, newValue in
            activityTask?.cancel()
            activityTask = Task {
                try? await Task.sleep(for: .seconds(1))
                
                if Task.isCancelled { return }
                
                do {
                    try await DBQuery.addPoints(lessonId: lesson.id, courseId: courseId, activityValue: newValue)
                    refreshController.triggerRefreshActivity()
                } catch {
                    apiError = .customError("Unable to add points: \(error.localizedDescription)")
                }
            }
        }
        .errorAlert(isPresented: $showApiError, error: apiError)
        .task {
            await fetchData()
        }
        .onChange(of: networkMonitor.isConnected) {
            Task {
                await fetchData()
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    func fetchData(forceRefresh: Bool = false) async {
#if !targetEnvironment(simulator)
        await fetchData(
            forceRefresh: forceRefresh,
            fetchOperation: { try await DBQuery.getAllLessonDeclarations(lessonId: lesson.id, forceRefresh: forceRefresh) },
            onError: { error in self.apiError = error }
        ) {
            data in self.data = data
        }
#else
        data = Set(DeclarationDto.getMockData())
#endif
    }
}
