//
//  EventRow.swift
//  dory
//
//  Created by Kunal Vats on 08/01/26.
//

import SwiftUI

struct DetectedEventRow: View {

    let event: DetectedEvent
    let isSelected: Bool
    let onToggle: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {

            Button(action: onToggle) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .accentColor : .secondary)
                    .font(.title3)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(.headline)

                if let start = event.startTime {
                    Text(start.formatted(date: .abbreviated, time: .shortened))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                if let recurrence = event.recurrence {
                    Text("Repeats: \(recurrence)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            Text("\(Int(event.confidence * 100))%")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
    }
}

//
//#Preview {
//    EventRow()
//}
