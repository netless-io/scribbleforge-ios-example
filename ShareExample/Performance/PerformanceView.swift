import BenchmarkKit
import SwiftUI

struct GResult: Identifiable {
    var id: UUID = UUID()
    let identifier: String
    let results: [MeasureResult]
}

struct PerformanceView: View {
    @State var running = false
    @State var mainThread = false
    @State var performTimes = 1
    @State var formResults: [GResult] = []

    var body: some View {
        ScrollView {
            VStack(spacing: 4) {
                Group {
                    Text("YJS Benchmark")
                        .font(.title)

                    Stepper("Perform Times: \(performTimes)", value: $performTimes, in: 1 ... 10)

                    Toggle(isOn: $mainThread) {
                        Text("Use MainThread")
                    }

                    Button("Start Benchmark") {
                        Task {
                            await work()
                        }
                    }
                }
                .padding()
                
                ForEach(formResults) { item in
                    BenchmarkKit.formView(results: item.results, title: item.identifier)
                }
            }
        }
        .overlay {
            if running {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .frame(maxHeight: .infinity)
                    .background(.ultraThinMaterial)
                    .ignoresSafeArea()
                    .transition(.opacity)
            }
        }
        .buttonStyle(.borderedProminent)
    }

    func work() async {
        await MainActor.run {
            running.toggle()
        }
        let queue = DispatchQueue(label: "benchmark", qos: .default)
        let model = PerformanceModel(times: performTimes, queue: mainThread ? .main : queue)
        let performResults = await model.perform()

        let identifies = performResults.reduce(into: Set<String>()) { $0.insert($1.resourceCaseLabel) }
        var groupedResults: [GResult] = []

        for identifier in identifies {
            let items = performResults.filter { $0.resourceCaseLabel == identifier }
            groupedResults.append(.init(identifier: identifier, results: items))
        }

        await MainActor.run {
            formResults = groupedResults
            running.toggle()
        }
    }
}

#Preview {
    PerformanceView()
}
