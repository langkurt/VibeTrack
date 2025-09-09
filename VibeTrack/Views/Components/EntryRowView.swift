import SwiftUI

struct EntryRowView: View {
    let entry: FoodEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(entry.name)
                    .font(.headline)
                Spacer()
                Text(String(format: UICopy.EntriesList.caloriesFormat, entry.calories))
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            
            HStack(spacing: 12) {
                Label(String(format: UICopy.EntriesList.proteinLabel, Int(entry.protein)), systemImage: "p.square.fill")
                    .font(.caption)
                    .foregroundColor(.orange)
                
                Label(String(format: UICopy.EntriesList.carbsLabel, Int(entry.carbs)), systemImage: "c.square.fill")
                    .font(.caption)
                    .foregroundColor(.blue)
                
                Label(String(format: UICopy.EntriesList.fatLabel, Int(entry.fat)), systemImage: "f.square.fill")
                    .font(.caption)
                    .foregroundColor(.purple)
                
                Spacer()
                
                Text(entry.timestamp, style: .time)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if let assumptions = entry.llmAssumptions {
                Text(assumptions)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .italic()
            }
        }
        .padding(.vertical, 4)
    }
}

