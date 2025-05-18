//
//  ErrorHandling.swift
//  ePolan
//
//  Created by Michał Lisicki on 17/05/2025.
//

import SwiftUI

enum ViewState {
    case loading
    case loaded
    case empty
}

@MainActor
protocol FallbackView: View {
    associatedtype T: Hashable
    
    var networkMonitor: NetworkMonitor { get }
    var apiError: ApiError? { get }
    var showApiError: Bool { get nonmutating set }
    var data: Set<T>? { get }
}

@MainActor
protocol PostData {
    var networkMonitor: NetworkMonitor { get }
    var isPutOngoing: Bool { get nonmutating set }
    var showApiError: Bool { get nonmutating set }
}

extension FallbackView {
    var viewState: ViewState {
        if data == nil {
            return .loading
        } else if data?.isEmpty ?? false {
            return .empty
        } else {
            return .loaded
        }
    }
    
    func fetchData<T: Sendable>(forceRefresh: Bool, fetchOperation: () async throws -> T, onError: ((ApiError?) -> Void), assign: (T) -> Void) async {
            do {
                assign(try await fetchOperation())
            } catch {
                if forceRefresh && !networkMonitor.isConnected || networkMonitor.isConnected {
                    let apiError = error.mapToApiError()
                    onError(apiError)
                    if apiError != nil {
                        showApiError = true
                    }
                }
            }
        }
}

extension PostData {
    func postInformation(postOperation: () async throws -> Void, onError: ((ApiError?) -> Void), logicAfterSuccess: () -> Void) async {
            do {
                isPutOngoing = true
                guard networkMonitor.isConnected else {
                    throw ApiError.customError("This action requires an internet connection.")
                }
                try await postOperation()
                logicAfterSuccess()
                isPutOngoing = false
            } catch {
                let apiError = error.mapToApiError()
                onError(apiError)
                if apiError != nil {
                    showApiError = true
                }
                isPutOngoing = false
            }
        }
}

// MARK: - Error Handling

enum ApiError: Error {
    case invalidResponse
    case httpError(statusCode: Int, body: String)
    case requestError(Error)
    case customError(String)
}

extension ApiError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response format"
        case .httpError(statusCode: let code, body: let message):
            return "HTTP error \(code): \(message)"
        case .requestError(let underlyingError):
            return underlyingError.localizedDescription
        case .customError(let message):
            return message
        }
    }
}

extension Error {
    func mapToApiError() -> ApiError? {
        if let apiError = self as? ApiError {
            return apiError
        } else if (self as NSError).code == NSURLErrorCancelled {
            return nil
        } else {
            return .customError(self.localizedDescription)
        }
    }
}

extension View {
    func fallbackView(viewState: ViewState) -> some View {
        overlay {
            switch viewState {
            case .loading:
                ProgressView()
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
            case .empty:
                ContentUnavailableView("No items yet", systemImage: "book.closed")
            case .loaded:
                EmptyView()
            }
        }
    }
}

extension View {
    func errorAlert(isPresented: Binding<Bool>, error: ApiError?) -> some View {
        if let error = error {
            return AnyView(self.alert(isPresented: isPresented) {
                Alert(title: Text("Something went wrong!"), message: Text(error.localizedDescription))
            })
        }
        return AnyView(self)
    }
}

extension Button {
    @ViewBuilder
    func replacedWithProgressView(isPutOngoing: Bool) -> some View {
        if isPutOngoing {
            ProgressView()
        } else {
            self
        }
    }
}
