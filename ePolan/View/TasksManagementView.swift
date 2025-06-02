//
//  TasksManagementView.swift
//  ePolan
//
//  Created by Michał Lisicki on 02/05/2025.
//

import SwiftUI

struct TasksManagementView: View, FallbackView, PostData {
    @State var lesson: LessonDto
    @State var data: Set<ExerciseDto>?

    @Environment(\.dismiss) var dismiss
    @Environment(NetworkMonitor.self) var networkMonitor

    @State var showApiError = false
    @State var isPutOngoing = false
    @State var apiError: ApiError?

    let courseID: UUID

    var body: some View {
        VStack {
            if let data {
                if !data.isEmpty {
                    List(data.sortedByNumber(), id: \.id) { exercise in
                        HStack {
                            Text("\(exercise.exerciseNumber). \(exercise.subpoint ?? "")")
                            Spacer()
                            let siblings = data.filter { $0.exerciseNumber == exercise.exerciseNumber }
                            let sortedSiblings = siblings.sorted { ($0.subpoint ?? "") < ($1.subpoint ?? "") }

                            if siblings.count == 1 || sortedSiblings.last?.id == exercise.id {
                                HStack {
                                    let isOnlyBaseLast = siblings.count == 1 && exercise.exerciseNumber == (data.map(\.exerciseNumber).max() ?? Int.min)
                                    if siblings.count > 1 || isOnlyBaseLast {
                                        Button { removeExercise(for: exercise) } label: {
                                            Image(systemName: "minus.diamond.fill")
                                        }
                                        .buttonStyle(.bordered)
                                    }
                                    Button { addSubpoint(to: exercise) } label: {
                                        Image(systemName: "plus.diamond.fill")
                                    }
                                    .buttonStyle(.bordered)
                                }
                            }
                        }
                    }
                } else {
                    Text("No exercises yet")
                }
                Button("Add exercise") {
                    addExercise()
                }
                .buttonStyle(.borderedProminent)
                .padding()
            }
        }
        .fallbackView(viewState: viewState != .empty ? viewState : .loaded)
        .errorAlert(isPresented: $showApiError, error: apiError)
        .navigationTitle("Manage exercises")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    Task {
                        lesson.exercises = data!
                        await postInformation(
                            postOperation: { try await DBQuery.postExercises(lesson: lesson) },
                            onError: { error in apiError = error },
                        ) {
                            dismiss()
                            Task {
                                try await ApiClient.shared.removeCachedResponse(for: DBQuery.makeRequest(url: DBQuery.getAllLessonsURL(courseID), method: .GET))
                            }
                        }
                    }
                }
                .replacedWithProgressView(isPutOngoing: isPutOngoing)
                .disabled(lesson.exercises == data || data == nil)
            }
        }
        .task {
            await fetchData()
        }
    }

    func fetchData(forceRefresh: Bool = false) async {
        await fetchData(
            forceRefresh: forceRefresh,
            fetchOperation: { try await Set(DBQuery.getAllExercises(lessonId: lesson.id)) },
            onError: { error in apiError = error },
        ) {
            data in self.data = data
        }
    }

    func addExercise() {
        let index = (data!.map(\.exerciseNumber).max() ?? 0) + 1
        data?.insert(ExerciseDto(classDate: lesson.classDate, groupName: lesson.courseName, exerciseNumber: index, subpoint: nil))
    }

    func addSubpoint(to exercise: ExerciseDto) {
        let siblings = data?.filter { $0.exerciseNumber == exercise.exerciseNumber }

        if exercise.subpoint == nil {
            // First subpoint (creating a and b at once)
            data?.remove(exercise)
            var first = exercise
            first.subpoint = "a"
            data?.insert(first)
            let second = ExerciseDto(classDate: exercise.classDate, groupName: exercise.groupName, exerciseNumber: exercise.exerciseNumber, subpoint: "b")
            data?.insert(second)
            return
        }

        let sortedSiblings = siblings?.sorted { ($0.subpoint ?? "") < ($1.subpoint ?? "") }

        if let last = sortedSiblings?.last, let lastSubpoint = last.subpoint {
            var nextSubpoint: String?

            if let ascii = lastSubpoint.unicodeScalars.first?.value, ascii < 122 {
                nextSubpoint = String(Character(UnicodeScalar(ascii + 1)!))
            } else if lastSubpoint.starts(with: "z") {
                let apostropheCount = lastSubpoint.dropFirst().count(where: { $0 == "'" })
                nextSubpoint = "z" + String(repeating: "'", count: apostropheCount + 1)
            }

            if let nextSubpoint {
                let next = ExerciseDto(
                    classDate: exercise.classDate,
                    groupName: exercise.groupName,
                    exerciseNumber: exercise.exerciseNumber,
                    subpoint: nextSubpoint,
                )
                data?.insert(next)
            }
        }
    }

    func removeExercise(for exercise: ExerciseDto) {
        data?.remove(exercise)

        let siblings = data?.filter { $0.exerciseNumber == exercise.exerciseNumber }

        // Last subpoints - converting back to exercise without subpoint
        if siblings?.count == 1, var second = siblings?.first, second.subpoint != nil {
            data?.remove(second)
            second.subpoint = nil
            data?.insert(second)
        }
    }
}
