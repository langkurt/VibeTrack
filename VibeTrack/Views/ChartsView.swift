import SwiftUI
import Charts

struct ChartsView: View {
    @ObservedObject var dataStore: FoodDataStore
    @State private var selectedTimeRange = 0
    
    var timeRanges = ["Week", "Month", "3 Months"]
    
    var daysToShow: Int {
        switch selectedTimeRange {
        case 0: return 7
        case 1: return 30
        case 2: return 90
        default: return 7
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Time Range Picker
                    Picker("Time Range", selection: $selectedTimeRange) {
                        ForEach(0..<timeRanges.count, id: \.self) { index in
                            Text(timeRanges[index]).tag(index)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding()
                    .onChange(of: selectedTimeRange) { newValue in
                        LogManager.shared.log("Time range changed to: \(timeRanges[newValue])", category: .ui)
                    }
                    
                    // Today's Summary
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Today's Summary")
                            .font(.headline)
                        
                        let totals = dataStore.todaysTotals()
                        
                        HStack(spacing: 20) {
                            VStack {
                                Text("\(totals.calories)")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                Text("Calories")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            VStack {
                                Text("\(Int(totals.protein))g")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.orange)
                                Text("Protein")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            VStack {
                                Text("\(Int(totals.carbs))g")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.blue)
                                Text("Carbs")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            VStack {
                                Text("\(Int(totals.fat))g")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.purple)
                                Text("Fat")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    
                    // Calories Chart
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Daily Calories")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        Chart(dataStore.dailyCalories(for: daysToShow), id: \.date) { item in
                            BarMark(
                                x: .value("Date", item.date, unit: .day),
                                y: .value("Calories", item.calories)
                            )
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.6, green: 0.2, blue: 0.8),
                                        Color(red: 0.9, green: 0.2, blue: 0.3)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                        }
                        .frame(height: 200)
                        .padding(.horizontal)
                    }
                    
                    // Macro Distribution Chart
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Macro Distribution (Last 7 Days)")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        let last7Days = dataStore.entries.filter {
                            $0.timestamp > Calendar.current.date(byAdding: .day, value: -7, to: Date())!
                        }
                        
                        let totalProtein = last7Days.reduce(0.0) { $0 + $1.protein }
                        let totalCarbs = last7Days.reduce(0.0) { $0 + $1.carbs }
                        let totalFat = last7Days.reduce(0.0) { $0 + $1.fat }
                        
                        let macroData = [
                            ("Protein", totalProtein, Color.orange),
                            ("Carbs", totalCarbs, Color.blue),
                            ("Fat", totalFat, Color.purple)
                        ]
                        
                        if totalProtein > 0 || totalCarbs > 0 || totalFat > 0 {
                            Chart(macroData, id: \.0) { item in
                                SectorMark(
                                    angle: .value("Value", item.1),
                                    innerRadius: .ratio(0.5)
                                )
                                .foregroundStyle(item.2)
                            }
                            .frame(height: 200)
                            .padding()
                            
                            HStack(spacing: 20) {
                                ForEach(macroData, id: \.0) { item in
                                    HStack(spacing: 4) {
                                        Circle()
                                            .fill(item.2)
                                            .frame(width: 12, height: 12)
                                        Text("\(item.0): \(Int(item.1))g")
                                            .font(.caption)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        } else {
                            Text("No macro data for the last 7 days")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .frame(height: 200)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    
                    Spacer(minLength: 50)
                }
            }
            .navigationTitle("Trends")
        }
        .onAppear {
            LogManager.shared.log("ChartsView appeared", category: .ui)
        }
    }
}
