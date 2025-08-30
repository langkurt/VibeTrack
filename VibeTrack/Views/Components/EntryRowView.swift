import SwiftUI

struct EntryRowView: View {
    let entry: FoodEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(entry.name)
                    .font(.headline)
                Spacer()
                Text("\(entry.calories) cal")
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            
            HStack(spacing: 12) {
                Label("\(Int(entry.protein))g", systemImage: "p.square.fill")
                    .font(.caption)
                    .foregroundColor(.orange)
                
                Label("\(Int(entry.carbs))g", systemImage: "c.square.fill")
                    .font(.caption)
                    .foregroundColor(.blue)
                
                Label("\(Int(entry.fat))g", systemImage: "f.square.fill")
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

