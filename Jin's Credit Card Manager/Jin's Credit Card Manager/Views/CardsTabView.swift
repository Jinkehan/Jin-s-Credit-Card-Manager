//
//  CardsTabView.swift
//  Jin's Credit Card Manager
//
//  Created by Kehan Jin on 12/25/25.
//

import SwiftUI

struct CardsTabView: View {
    @Bindable var viewModel: CardViewModel
    @State private var isAddingCard = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                HStack {
                    HStack(spacing: 12) {
                        Image(systemName: "creditcard.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.blue)
                        
                        Text("My Cards")
                            .font(.system(size: 34, weight: .bold))
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        isAddingCard = true
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 48, height: 48)
                            
                            Image(systemName: "plus")
                                .font(.system(size: 24, weight: .medium))
                                .foregroundColor(.white)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
                
                // Cards List
                if viewModel.cards.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "creditcard")
                            .font(.system(size: 64))
                            .foregroundColor(.gray.opacity(0.3))
                        
                        Text("No cards added yet")
                            .font(.system(size: 17))
                            .foregroundColor(.gray)
                        
                        Text("Tap the + button to add your first card")
                            .font(.system(size: 14))
                            .foregroundColor(.gray.opacity(0.7))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 80)
                } else {
                    VStack(spacing: 12) {
                        ForEach(viewModel.cards, id: \.id) { card in
                            CardItemView(card: card, onDelete: {
                                viewModel.deleteCard(card)
                            })
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.bottom, 24)
        }
        .background(Color(.systemGroupedBackground))
        .sheet(isPresented: $isAddingCard) {
            AddCardView(viewModel: viewModel, isPresented: $isAddingCard)
        }
    }
}

struct CardItemView: View {
    let card: CreditCard
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Card color indicator
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(card.color)
                    .frame(width: 64, height: 64)
                
                Image(systemName: "creditcard.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.white)
            }
            
            // Card info
            VStack(alignment: .leading, spacing: 4) {
                Text(card.name)
                    .font(.system(size: 17, weight: .semibold))
                    .lineLimit(1)
                
                Text("•••• \(card.lastFourDigits)")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                
                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                    
                    Text("Due on the \(card.dueDate)\(getOrdinalSuffix(card.dueDate)) of each month")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            // Delete button
            Button(action: onDelete) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.red.opacity(0.1))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "trash")
                        .font(.system(size: 20))
                        .foregroundColor(.red)
                }
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    private func getOrdinalSuffix(_ day: Int) -> String {
        switch day {
        case 1, 21, 31: return "st"
        case 2, 22: return "nd"
        case 3, 23: return "rd"
        default: return "th"
        }
    }
}

struct AddCardView: View {
    @Bindable var viewModel: CardViewModel
    @Binding var isPresented: Bool
    
    @State private var cardName = ""
    @State private var lastFourDigits = ""
    @State private var dueDate = "15"
    @State private var selectedColor = CardColors.colors[0]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Card Information")) {
                    TextField("Card Name", text: $cardName)
                        .autocapitalization(.words)
                    
                    TextField("Last 4 Digits", text: $lastFourDigits)
                        .keyboardType(.numberPad)
                        .onChange(of: lastFourDigits) { oldValue, newValue in
                            lastFourDigits = String(newValue.filter { $0.isNumber }.prefix(4))
                        }
                    
                    Stepper("Due Date: \(dueDate)", value: Binding(
                        get: { Int(dueDate) ?? 15 },
                        set: { dueDate = String($0) }
                    ), in: 1...31)
                }
                
                Section(header: Text("Card Color")) {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 4), spacing: 12) {
                        ForEach(CardColors.colors, id: \.self) { color in
                            Button(action: {
                                selectedColor = color
                            }) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(hex: color))
                                        .frame(height: 48)
                                    
                                    if selectedColor == color {
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.blue, lineWidth: 4)
                                            .frame(height: 48)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("Add New Card")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        if !cardName.isEmpty && lastFourDigits.count == 4 {
                            viewModel.addCard(
                                name: cardName,
                                lastFourDigits: lastFourDigits,
                                dueDate: Int(dueDate) ?? 15,
                                colorHex: selectedColor
                            )
                            isPresented = false
                        }
                    }
                    .disabled(cardName.isEmpty || lastFourDigits.count != 4)
                }
            }
        }
    }
}

struct CardColors {
    static let colors = [
        "#3B82F6", // blue
        "#8B5CF6", // purple
        "#EC4899", // pink
        "#10B981", // green
        "#F59E0B", // amber
        "#EF4444", // red
        "#6366F1", // indigo
        "#14B8A6", // teal
    ]
}

