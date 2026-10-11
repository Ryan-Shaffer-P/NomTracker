import SwiftData
import SwiftUI

struct FoodsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \SavedFood.name) private var foods: [SavedFood]
    @Query(filter: #Predicate<Macro> { $0.isTracked == true }, sort: \Macro.sortOrder)
    private var macros: [Macro]

    @State private var showingNew = false
    @State private var editingFood: SavedFood?
    @State private var loggingFood: SavedFood?

    var body: some View {
        NavigationStack {
            List {
                ForEach(foods) { food in
                    Button {
                        editingFood = food
                    } label: {
                        FoodSummaryRow(name: food.name, detail: food.servingDescription, values: food.valuesPerServing, macros: macros)
                    }
                    .tint(.primary)
                    .swipeActions(edge: .leading) {
                        Button {
                            loggingFood = food
                        } label: {
                            Label("Log", systemImage: "plus")
                        }
                        .tint(.green)
                    }
                    .contextMenu {
                        Button {
                            loggingFood = food
                        } label: {
                            Label("Log Now", systemImage: "plus")
                        }
                    }
                }
                .onDelete { offsets in
                    offsets.map { foods[$0] }.forEach(context.delete)
                }
            }
            .overlay {
                if foods.isEmpty {
                    ContentUnavailableView(
                        "No Saved Foods",
                        systemImage: "fork.knife",
                        description: Text("Save foods you eat often to log them in one tap.")
                    )
                }
            }
            .navigationTitle("Foods")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingNew = true
                    } label: {
                        Label("New Food", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingNew) {
                NavigationStack { FoodEditorView(food: nil) }
            }
            .sheet(item: $editingFood) { food in
                NavigationStack { FoodEditorView(food: food) }
            }
            .sheet(item: $loggingFood) { food in
                NavigationStack {
                    EntryFormView(food: food, isRoot: true) { loggingFood = nil }
                }
            }
        }
    }
}

#Preview {
    FoodsView()
        .modelContainer(PreviewData.makeContainer())
}
