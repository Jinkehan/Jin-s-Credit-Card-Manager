//
//  BenefitsListView.swift
//  J Due
//
//  Created by Kehan Jin on 12/25/25.
//

import SwiftUI
import SwiftData

struct BenefitsListView: View {
    @Bindable var card: CreditCard
    @State private var benefitsViewModel = BenefitsViewModel()
    @State private var isAddingBenefit = false
    @State private var editingBenefit: CardBenefit?
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        List {
            if let benefits = card.benefits, !benefits.isEmpty {
                ForEach(benefits.filter { $0.isActive }, id: \.id) { benefit in
                    BenefitRowView(benefit: benefit, onTap: {
                        editingBenefit = benefit
                    }, onToggleActive: {
                        benefitsViewModel.toggleBenefitActive(benefit)
                    }, onMarkUsed: {
                        benefitsViewModel.markBenefitAsUsed(benefit)
                    })
                }
                .onDelete { indexSet in
                    let activeBenefits = card.benefits?.filter { $0.isActive } ?? []
                    for index in indexSet {
                        if index < activeBenefits.count {
                            benefitsViewModel.deleteBenefit(activeBenefits[index])
                        }
                    }
                }
            } else {
                Text("No benefits added yet")
                    .foregroundColor(.gray)
                    .font(.subheadline)
            }
        }
        .navigationTitle("Card Benefits")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    isAddingBenefit = true
                }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $isAddingBenefit) {
            AddBenefitView(
                card: card,
                benefitsViewModel: benefitsViewModel,
                isPresented: $isAddingBenefit
            )
        }
        .sheet(item: $editingBenefit) { benefit in
            EditBenefitView(
                benefit: benefit,
                benefitsViewModel: benefitsViewModel,
                isPresented: Binding(
                    get: { editingBenefit != nil },
                    set: { if !$0 { editingBenefit = nil } }
                )
            )
        }
        .onAppear {
            benefitsViewModel.setModelContext(modelContext)
            benefitsViewModel.loadBenefits(for: card)
        }
    }
}

struct BenefitRowView: View {
    let benefit: CardBenefit
    let onTap: () -> Void
    let onToggleActive: () -> Void
    let onMarkUsed: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(benefit.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    if benefit.amount != nil && benefit.amount! > 0 {
                        Text(benefit.formattedAmount)
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                }
                
                Text(benefit.benefitDescription)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .lineLimit(2)
                
                HStack(spacing: 12) {
                    Label(benefit.reminderDescription, systemImage: "bell.fill")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    if benefit.isFromPredefined {
                        Label("Predefined", systemImage: "checkmark.circle.fill")
                            .font(.caption2)
                            .foregroundColor(.green)
                    }
                    
                    if benefit.isCustom {
                        Label("Custom", systemImage: "pencil.circle.fill")
                            .font(.caption2)
                            .foregroundColor(.orange)
                    }
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                onToggleActive()
            } label: {
                Label("Disable", systemImage: "eye.slash")
            }
            
            Button {
                onMarkUsed()
            } label: {
                Label("Mark Used", systemImage: "checkmark")
            }
            .tint(.blue)
        }
    }
}

struct AddBenefitView: View {
    let card: CreditCard
    @Bindable var benefitsViewModel: BenefitsViewModel
    @Binding var isPresented: Bool
    
    @State private var name = ""
    @State private var description = ""
    @State private var category = "Other"
    @State private var amount: Double? = nil
    @State private var currency = "USD"
    @State private var benefitType = "credit"
    @State private var reminderType = "monthly"
    @State private var reminderDay: Int? = 1
    @State private var reminderDate: Date? = nil
    @State private var reminderMessage = ""
    @State private var resetPeriod: String? = nil
    
    private let categories = ["Travel", "Dining", "Shopping", "Entertainment", "Other"]
    private let benefitTypes = ["credit", "membership", "bonus", "discount", "other"]
    private let reminderTypes = ["monthly", "annual", "quarterly", "semi_annual", "one_time"]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Benefit Information")) {
                    TextField("Benefit Name", text: $name)
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                    
                    Picker("Category", selection: $category) {
                        ForEach(categories, id: \.self) { cat in
                            Text(cat).tag(cat)
                        }
                    }
                    
                    Picker("Type", selection: $benefitType) {
                        ForEach(benefitTypes, id: \.self) { type in
                            Text(type.capitalized).tag(type)
                        }
                    }
                }
                
                Section(header: Text("Value")) {
                    HStack {
                        Text("Amount")
                        Spacer()
                        TextField("0", value: $amount, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    Picker("Currency", selection: $currency) {
                        Text("USD").tag("USD")
                        Text("EUR").tag("EUR")
                        Text("GBP").tag("GBP")
                    }
                }
                
                Section(header: Text("Reminder Settings")) {
                    Picker("Reminder Type", selection: $reminderType) {
                        ForEach(reminderTypes, id: \.self) { type in
                            Text(type.capitalized.replacingOccurrences(of: "_", with: " ")).tag(type)
                        }
                    }
                    .onChange(of: reminderType) { oldValue, newValue in
                        if newValue == "one_time" {
                            reminderDate = Date()
                        } else if newValue == "monthly" {
                            reminderDay = 1
                        }
                    }
                    
                    if reminderType == "monthly" {
                        Stepper("Day of Month: \(reminderDay ?? 1)", value: Binding(
                            get: { reminderDay ?? 1 },
                            set: { reminderDay = $0 }
                        ), in: 1...31)
                    }
                    
                    if reminderType == "one_time" {
                        DatePicker("Reminder Date", selection: Binding(
                            get: { reminderDate ?? Date() },
                            set: { reminderDate = $0 }
                        ), displayedComponents: [.date])
                    }
                    
                    if reminderType == "annual" || reminderType == "monthly" {
                        Picker("Reset Period", selection: Binding(
                            get: { resetPeriod ?? reminderType },
                            set: { resetPeriod = $0 }
                        )) {
                            Text("Monthly").tag("monthly")
                            Text("Annual").tag("annual")
                            Text("Semi-Annual").tag("semi_annual")
                        }
                    }
                    
                    TextField("Reminder Message", text: $reminderMessage, axis: .vertical)
                        .lineLimit(2...4)
                }
            }
            .navigationTitle("Add Benefit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        if !name.isEmpty {
                            benefitsViewModel.addCustomBenefit(
                                name: name,
                                description: description,
                                category: category,
                                amount: amount,
                                currency: currency,
                                benefitType: benefitType,
                                reminderType: reminderType,
                                reminderDay: reminderDay,
                                reminderDate: reminderDate,
                                reminderMessage: reminderMessage.isEmpty ? "Don't forget to use your \(name)!" : reminderMessage,
                                resetPeriod: resetPeriod
                            )
                            isPresented = false
                        }
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}

struct EditBenefitView: View {
    let benefit: CardBenefit
    @Bindable var benefitsViewModel: BenefitsViewModel
    @Binding var isPresented: Bool
    
    @State private var name = ""
    @State private var description = ""
    @State private var category = "Other"
    @State private var amount: Double? = nil
    @State private var currency = "USD"
    @State private var benefitType = "credit"
    @State private var reminderType = "monthly"
    @State private var reminderDay: Int? = 1
    @State private var reminderDate: Date? = nil
    @State private var reminderMessage = ""
    @State private var isActive = true
    @State private var resetPeriod: String? = nil
    
    private let categories = ["Travel", "Dining", "Shopping", "Entertainment", "Other"]
    private let benefitTypes = ["credit", "membership", "bonus", "discount", "other"]
    private let reminderTypes = ["monthly", "annual", "quarterly", "semi_annual", "one_time"]
    
    init(benefit: CardBenefit, benefitsViewModel: BenefitsViewModel, isPresented: Binding<Bool>) {
        self.benefit = benefit
        self.benefitsViewModel = benefitsViewModel
        self._isPresented = isPresented
        
        _name = State(initialValue: benefit.name)
        _description = State(initialValue: benefit.benefitDescription)
        _category = State(initialValue: benefit.category)
        _amount = State(initialValue: benefit.amount)
        _currency = State(initialValue: benefit.currency)
        _benefitType = State(initialValue: benefit.benefitType)
        _reminderType = State(initialValue: benefit.reminderType)
        _reminderDay = State(initialValue: benefit.reminderDay)
        _reminderDate = State(initialValue: benefit.reminderDate)
        _reminderMessage = State(initialValue: benefit.reminderMessage)
        _isActive = State(initialValue: benefit.isActive)
        _resetPeriod = State(initialValue: benefit.resetPeriod)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Benefit Information")) {
                    TextField("Benefit Name", text: $name)
                        .disabled(benefit.isFromPredefined && !benefit.isCustom)
                    
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                        .disabled(benefit.isFromPredefined && !benefit.isCustom)
                    
                    Picker("Category", selection: $category) {
                        ForEach(categories, id: \.self) { cat in
                            Text(cat).tag(cat)
                        }
                    }
                    .disabled(benefit.isFromPredefined && !benefit.isCustom)
                    
                    Picker("Type", selection: $benefitType) {
                        ForEach(benefitTypes, id: \.self) { type in
                            Text(type.capitalized).tag(type)
                        }
                    }
                    .disabled(benefit.isFromPredefined && !benefit.isCustom)
                    
                    Toggle("Active", isOn: $isActive)
                }
                
                Section(header: Text("Value")) {
                    HStack {
                        Text("Amount")
                        Spacer()
                        TextField("0", value: $amount, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    .disabled(benefit.isFromPredefined && !benefit.isCustom)
                    
                    Picker("Currency", selection: $currency) {
                        Text("USD").tag("USD")
                        Text("EUR").tag("EUR")
                        Text("GBP").tag("GBP")
                    }
                    .disabled(benefit.isFromPredefined && !benefit.isCustom)
                }
                
                Section(header: Text("Reminder Settings")) {
                    Picker("Reminder Type", selection: $reminderType) {
                        ForEach(reminderTypes, id: \.self) { type in
                            Text(type.capitalized.replacingOccurrences(of: "_", with: " ")).tag(type)
                        }
                    }
                    
                    if reminderType == "monthly" {
                        Stepper("Day of Month: \(reminderDay ?? 1)", value: Binding(
                            get: { reminderDay ?? 1 },
                            set: { reminderDay = $0 }
                        ), in: 1...31)
                    }
                    
                    if reminderType == "one_time" {
                        DatePicker("Reminder Date", selection: Binding(
                            get: { reminderDate ?? Date() },
                            set: { reminderDate = $0 }
                        ), displayedComponents: [.date])
                    }
                    
                    if reminderType == "annual" || reminderType == "monthly" {
                        Picker("Reset Period", selection: Binding(
                            get: { resetPeriod ?? reminderType },
                            set: { resetPeriod = $0 }
                        )) {
                            Text("Monthly").tag("monthly")
                            Text("Annual").tag("annual")
                            Text("Semi-Annual").tag("semi_annual")
                        }
                    }
                    
                    TextField("Reminder Message", text: $reminderMessage, axis: .vertical)
                        .lineLimit(2...4)
                }
                
                if benefit.isFromPredefined {
                    Section {
                        Text("This benefit is synced from a predefined card. Some fields cannot be edited.")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
            .navigationTitle("Edit Benefit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if !name.isEmpty {
                            benefitsViewModel.updateBenefit(
                                benefit,
                                name: name,
                                description: description,
                                category: category,
                                amount: amount,
                                currency: currency,
                                benefitType: benefitType,
                                reminderType: reminderType,
                                reminderDay: reminderDay,
                                reminderDate: reminderDate,
                                reminderMessage: reminderMessage.isEmpty ? "Don't forget to use your \(name)!" : reminderMessage,
                                isActive: isActive,
                                resetPeriod: resetPeriod
                            )
                            isPresented = false
                        }
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}

