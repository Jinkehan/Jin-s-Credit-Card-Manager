//
//  CardsTabView.swift
//  J Due
//
//  Created by Kehan Jin on 12/25/25.
//

import SwiftUI

struct CardsTabView: View {
    @Bindable var viewModel: CardViewModel
    @State private var isAddingCard = false
    @State private var editingCard: CreditCard?
    @State private var cardToDelete: CreditCard?
    @State private var showDeleteConfirmation = false
    
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
                                cardToDelete = card
                                showDeleteConfirmation = true
                            }, onTap: {
                                editingCard = card
                            })
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.bottom, 24)
        }
        .background(Color(.systemGroupedBackground))
        .alert("Delete Card", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let card = cardToDelete {
                    viewModel.deleteCard(card)
                    cardToDelete = nil
                }
            }
        } message: {
            if let card = cardToDelete {
                Text("Are you sure you want to delete \"\(card.name)\"? This action cannot be undone.")
            }
        }
        .sheet(isPresented: $isAddingCard) {
            AddCardView(viewModel: viewModel, isPresented: $isAddingCard)
        }
        .sheet(item: $editingCard) { card in
            EditCardView(viewModel: viewModel, card: card, isPresented: Binding(
                get: { editingCard != nil },
                set: { if !$0 { editingCard = nil } }
            ))
        }
    }
}

struct CardItemView: View {
    let card: CreditCard
    let onDelete: () -> Void
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            cardContent
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var cardContent: some View {
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
                
                if !card.lastFourDigits.isEmpty {
                    Text("•••• \(card.lastFourDigits)")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
                
                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                    
                    Text("Due on the \(card.dueDateDescription) of each month")
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
            .buttonStyle(PlainButtonStyle())
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
    
    @ObservedObject private var benefitsService = CardBenefitsService.shared
    @State private var cardName = ""
    @State private var lastFourDigits = ""
    @State private var selectedDate = Date()
    @State private var isLastDayOfMonth = false
    @State private var selectedColor = CardColors.colors[0]
    @State private var reminderDaysAhead = 5
    @State private var selectedPredefinedCard: PredefinedCard?
    @State private var showPredefinedCardPicker = false
    @State private var searchText = ""
    
    private var dueDateDay: Int {
        if isLastDayOfMonth {
            return 0
        }
        return Calendar.current.component(.day, from: selectedDate)
    }
    
    private var dueDateDescription: String {
        if isLastDayOfMonth {
            return "last day"
        } else {
            let day = Calendar.current.component(.day, from: selectedDate)
            return "\(day)\(getOrdinalSuffix(day))"
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Card Type")) {
                    Picker("Card Type", selection: $selectedPredefinedCard) {
                        Text("Custom Card").tag(PredefinedCard?.none)
                        ForEach(benefitsService.predefinedCards) { predefinedCard in
                            Text("\(predefinedCard.name) - \(predefinedCard.issuer)")
                                .tag(PredefinedCard?.some(predefinedCard))
                        }
                    }
                    .pickerStyle(.menu)
                    
                    if let predefinedCard = selectedPredefinedCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Selected: \(predefinedCard.name)")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                            Text("\(predefinedCard.defaultBenefits.count) benefits will be added")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                Section(header: Text("Card Information")) {
                    TextField("Card Name", text: $cardName)
                        .autocapitalization(.words)
                        .onChange(of: selectedPredefinedCard) { oldValue, newValue in
                            if let predefined = newValue {
                                cardName = predefined.name
                            }
                        }
                    
                    TextField("Last 4 Digits (Optional)", text: $lastFourDigits)
                        .keyboardType(.numberPad)
                        .onChange(of: lastFourDigits) { oldValue, newValue in
                            lastFourDigits = String(newValue.filter { $0.isNumber }.prefix(4))
                        }
                    
                    Toggle("Last Day of Month", isOn: $isLastDayOfMonth)
                    
                    if !isLastDayOfMonth {
                        DatePicker(
                            "Due Date",
                            selection: $selectedDate,
                            displayedComponents: [.date]
                        )
                        .datePickerStyle(.compact)
                    }
                    
                    Text("Payment due on the \(dueDateDescription) of each month")
                        .font(.caption)
                        .foregroundColor(.gray)
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
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Section(header: Text("Reminder Settings")) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Remind me \(reminderDaysAhead) day\(reminderDaysAhead == 1 ? "" : "s") before due date")
                            .font(.system(size: 14, weight: .medium))
                        
                        Slider(
                            value: Binding(
                                get: { Double(reminderDaysAhead) },
                                set: { reminderDaysAhead = Int($0) }
                            ),
                            in: 1...30,
                            step: 1
                        )
                        .accentColor(.blue)
                        
                        HStack {
                            Text("1 day")
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                            
                            Spacer()
                            
                            Text("30 days")
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.vertical, 4)
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
                        if !cardName.isEmpty {
                            viewModel.addCard(
                                name: cardName,
                                lastFourDigits: lastFourDigits,
                                dueDate: dueDateDay,
                                colorHex: selectedColor,
                                reminderDaysAhead: reminderDaysAhead,
                                predefinedCardId: selectedPredefinedCard?.id,
                                cardAnniversaryDate: Date()
                            )
                            isPresented = false
                        }
                    }
                    .disabled(cardName.isEmpty)
                }
            }
            .task {
                await benefitsService.fetchCardBenefits()
            }
            }
        }
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

struct EditCardView: View {
    @Bindable var viewModel: CardViewModel
    let card: CreditCard
    @Binding var isPresented: Bool
    
    @State private var cardName = ""
    @State private var lastFourDigits = ""
    @State private var selectedDate = Date()
    @State private var isLastDayOfMonth = false
    @State private var selectedColor = ""
    @State private var reminderDaysAhead = 5
    @State private var showBenefits = false
    
    init(viewModel: CardViewModel, card: CreditCard, isPresented: Binding<Bool>) {
        self.viewModel = viewModel
        self.card = card
        self._isPresented = isPresented
        
        // Initialize state with card values
        self._cardName = State(initialValue: card.name)
        self._lastFourDigits = State(initialValue: card.lastFourDigits)
        self._isLastDayOfMonth = State(initialValue: card.isLastDayOfMonth)
        self._selectedColor = State(initialValue: card.colorHex)
        self._reminderDaysAhead = State(initialValue: card.reminderDaysAhead)
        
        // Set initial date
        if !card.isLastDayOfMonth {
            let calendar = Calendar.current
            let components = DateComponents(year: 2024, month: 1, day: card.dueDate)
            self._selectedDate = State(initialValue: calendar.date(from: components) ?? Date())
        }
    }
    
    private var dueDateDay: Int {
        if isLastDayOfMonth {
            return 0
        }
        return Calendar.current.component(.day, from: selectedDate)
    }
    
    private var dueDateDescription: String {
        if isLastDayOfMonth {
            return "last day"
        } else {
            let day = Calendar.current.component(.day, from: selectedDate)
            return "\(day)\(getOrdinalSuffix(day))"
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Card Information")) {
                    TextField("Card Name", text: $cardName)
                        .autocapitalization(.words)
                    
                    TextField("Last 4 Digits (Optional)", text: $lastFourDigits)
                        .keyboardType(.numberPad)
                        .onChange(of: lastFourDigits) { oldValue, newValue in
                            lastFourDigits = String(newValue.filter { $0.isNumber }.prefix(4))
                        }
                    
                    Toggle("Last Day of Month", isOn: $isLastDayOfMonth)
                    
                    if !isLastDayOfMonth {
                        DatePicker(
                            "Due Date",
                            selection: $selectedDate,
                            displayedComponents: [.date]
                        )
                        .datePickerStyle(.compact)
                    }
                    
                    Text("Payment due on the \(dueDateDescription) of each month")
                        .font(.caption)
                        .foregroundColor(.gray)
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
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Section(header: Text("Reminder Settings")) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Remind me \(reminderDaysAhead) day\(reminderDaysAhead == 1 ? "" : "s") before due date")
                            .font(.system(size: 14, weight: .medium))
                        
                        Slider(
                            value: Binding(
                                get: { Double(reminderDaysAhead) },
                                set: { reminderDaysAhead = Int($0) }
                            ),
                            in: 1...30,
                            step: 1
                        )
                        .accentColor(.blue)
                        
                        HStack {
                            Text("1 day")
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                            
                            Spacer()
                            
                            Text("30 days")
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                Section(header: Text("Benefits")) {
                    Button(action: {
                        showBenefits = true
                    }) {
                        HStack {
                            Image(systemName: "gift.fill")
                                .foregroundColor(.blue)
                            Text("Manage Benefits")
                            Spacer()
                            if let benefits = card.benefits, !benefits.isEmpty {
                                Text("\(benefits.filter { $0.isActive }.count)")
                                    .foregroundColor(.gray)
                            }
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                                .font(.caption)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .navigationTitle("Edit Card")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if !cardName.isEmpty {
                            viewModel.updateCard(
                                card,
                                name: cardName,
                                lastFourDigits: lastFourDigits,
                                dueDate: dueDateDay,
                                colorHex: selectedColor,
                                reminderDaysAhead: reminderDaysAhead
                            )
                            isPresented = false
                        }
                    }
                    .disabled(cardName.isEmpty)
                }
            }
            .sheet(isPresented: $showBenefits) {
                NavigationView {
                    BenefitsListView(card: card)
                }
            }
        }
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

